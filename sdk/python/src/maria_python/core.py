from __future__ import annotations

import asyncio
import codecs
import json
from collections.abc import AsyncIterator, Mapping
from contextlib import asynccontextmanager, suppress
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, Optional

import importlib.resources as resources

JsonDict = Dict[str, Any]
MessageParam = str | Mapping[str, Any]


class MariaError(RuntimeError):
    def __init__(self, code: int, message: str, data: Any | None = None) -> None:
        super().__init__(f"JSON-RPC error {code}: {message}")
        self.code = code
        self.data = data


class MariaProcessError(RuntimeError):
    def __init__(self, returncode: int, stderr: str) -> None:
        detail = f"Process exited with code {returncode}"
        if stderr:
            detail = f"{detail}: {stderr}"
        super().__init__(detail)
        self.returncode = returncode
        self.stderr = stderr


@dataclass(slots=True)
class MariaAssistantMessage:
    content: Any


@dataclass(slots=True)
class MariaToolCallMessage:
    tool_call: Any
    json: Any
    text: Any


@dataclass(slots=True)
class MariaRawMessage:
    payload: Any


MariaEvent = MariaAssistantMessage | MariaToolCallMessage | MariaRawMessage


class _JsonStreamParser:
    def __init__(self) -> None:
        self._buffer = ""
        self._decoder = json.JSONDecoder()

    def feed(self, chunk: str) -> list[Any]:
        self._buffer += chunk
        messages: list[Any] = []
        while self._buffer:
            try:
                obj, index = self._decoder.raw_decode(self._buffer)
            except json.JSONDecodeError:
                break
            messages.append(obj)
            self._buffer = self._buffer[index:]
            self._buffer = self._buffer.lstrip()
        return messages


class Maria:
    def __init__(
        self, executable: Path | None = None, *, encoding: str = "utf-8"
    ) -> None:
        self._explicit_executable = executable
        self._encoding = encoding
        self._counter = 0

    @asynccontextmanager
    async def _resolve_executable(self) -> AsyncIterator[Path]:
        if self._explicit_executable is not None:
            yield Path(self._explicit_executable)
            return
        resource = resources.files("maria_python").joinpath("bin", "sdk.exe")
        with resources.as_file(resource) as exe_path:
            yield Path(exe_path)

    def _next_request_id(self) -> str:
        self._counter += 1
        return f"req-{self._counter}"

    def _format_prompt(self, prompt: MessageParam) -> JsonDict:
        if isinstance(prompt, str):
            return {"role": "user", "content": prompt}
        if isinstance(prompt, Mapping):
            if "role" not in prompt or "content" not in prompt:
                raise ValueError("Prompt mapping must include 'role' and 'content'.")
            return dict(prompt)
        raise TypeError("Prompt must be a string or mapping.")

    async def _send(self, stdin: asyncio.StreamWriter, payload: JsonDict) -> None:
        data = json.dumps(payload, separators=(",", ":"), ensure_ascii=False)
        stdin.write(data.encode(self._encoding) + b"\n")
        await stdin.drain()

    async def _read_payloads(
        self,
        stdout: asyncio.StreamReader,
        decoder: codecs.IncrementalDecoder,
        parser: _JsonStreamParser,
    ) -> AsyncIterator[Any]:
        while True:
            chunk = await stdout.read(4096)
            if not chunk:
                tail = decoder.decode(b"", final=True)
                if tail:
                    for payload in parser.feed(tail):
                        yield payload
                break
            text = decoder.decode(chunk)
            for payload in parser.feed(text):
                yield payload

    def _convert_event(self, payload: Any) -> MariaEvent | None:
        if not isinstance(payload, dict):
            return MariaRawMessage(payload)
        method = payload.get("method")
        if method == "maria.agent.assistant":
            return MariaAssistantMessage(payload.get("params"))
        if method == "maria.agent.tool_call":
            params = payload.get("params", {})
            return MariaToolCallMessage(
                tool_call=params.get("tool_call"),
                json=params.get("json"),
                text=params.get("text"),
            )
        if method is None and payload:
            return MariaRawMessage(payload)
        return None

    async def stream(self, prompt: MessageParam) -> AsyncIterator[MariaEvent]:
        message = self._format_prompt(prompt)
        async with self._resolve_executable() as executable:
            if not executable.exists():
                raise FileNotFoundError(f"Maria executable not found at {executable}")
            process = await asyncio.create_subprocess_exec(
                str(executable),
                stdin=asyncio.subprocess.PIPE,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
            )
            assert process.stdin is not None
            assert process.stdout is not None
            stdin = process.stdin
            stdout = process.stdout
            decoder = codecs.getincrementaldecoder(self._encoding)()
            parser = _JsonStreamParser()
            inflight: set[str] = set()
            stderr_task: Optional[asyncio.Task[bytes]] = None
            if process.stderr is not None:
                stderr_task = asyncio.create_task(process.stderr.read())
            terminated = False
            captured_error: Exception | None = None
            stderr_output = ""
            try:
                request_id = self._next_request_id()
                await self._send(
                    stdin,
                    {
                        "jsonrpc": "2.0",
                        "id": request_id,
                        "method": "maria.agent.add_message",
                        "params": message,
                    },
                )
                inflight.add(request_id)
                async for payload in self._read_payloads(stdout, decoder, parser):
                    # Distinguish JSON-RPC responses from event notifications.
                    if (
                        isinstance(payload, dict)
                        and payload.get("jsonrpc") == "2.0"
                        and "id" in payload
                    ):
                        inflight.discard(str(payload["id"]))
                        if "error" in payload:
                            error = payload["error"]
                            code = int(error.get("code", -32000))
                            message = str(error.get("message", "Unknown error"))
                            raise MariaError(code, message, error.get("data"))
                        continue
                    event = self._convert_event(payload)
                    if event is None:
                        continue
                    yield event
                    if isinstance(event, MariaAssistantMessage):
                        return
            except Exception as exc:  # pragma: no cover - defensive cleanup path
                captured_error = exc
                raise
            finally:
                if stdin and not stdin.is_closing():
                    stdin.close()
                    wait_closed = getattr(stdin, "wait_closed", None)
                    if wait_closed is not None:
                        with suppress(Exception):
                            await wait_closed()
                if process.returncode is None:
                    process.terminate()
                    terminated = True
                with suppress(asyncio.TimeoutError, ProcessLookupError):
                    await asyncio.wait_for(process.wait(), timeout=5)
                if stderr_task is not None:
                    with suppress(asyncio.CancelledError):
                        stderr_bytes = await stderr_task
                        if stderr_bytes:
                            stderr_output = stderr_bytes.decode(
                                self._encoding,
                                errors="replace",
                            ).strip()
                if (
                    captured_error is None
                    and not terminated
                    and process.returncode not in (0, None)
                ):
                    raise MariaProcessError(process.returncode or -1, stderr_output)


__all__ = [
    "Maria",
    "MariaAssistantMessage",
    "MariaToolCallMessage",
    "MariaRawMessage",
    "MariaEvent",
    "MariaError",
    "MariaProcessError",
]
