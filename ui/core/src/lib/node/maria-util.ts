export async function shutdown(port: number): Promise<void> {
  await fetch(`http://localhost:${port}/v1/shutdown`, { method: "POST" });
}
