import importlib.resources as resources
import asyncio


class Maria:
    async def start(self, prompt: str) -> None:
        resource = resources.files("maria").joinpath("bin", "sdk.exe")
        with resources.as_file(resource) as executable_path:
            process = await asyncio.create_subprocess_exec(
                executable_path,
                prompt,
            )
            status = await process.wait()
            if status != 0:
                raise RuntimeError(f"Maria process failed to start: {status}")
