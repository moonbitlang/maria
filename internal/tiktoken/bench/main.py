import tiktoken
from pathlib import Path
import time

WARMUP_ROUNDS = 5
BENCHMARK_ROUNDS = 100


def bench(tokenizer: tiktoken.Encoding, text: str) -> float:
    start = time.perf_counter()
    tokenizer.encode(text)
    end = time.perf_counter()
    return end - start


def main():
    messages_path = Path("bench") / "messages.json"
    messages_text = messages_path.read_text()
    tokenizer = tiktoken.get_encoding("cl100k_base")

    for _ in range(WARMUP_ROUNDS):
        bench(tokenizer, messages_text)

    samples = []
    for _ in range(BENCHMARK_ROUNDS):
        samples.append(bench(tokenizer, messages_text))

    print(f"Time taken: {sum(samples) * 1000 / BENCHMARK_ROUNDS:.2f}ms")


if __name__ == "__main__":
    main()
