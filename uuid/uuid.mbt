///|
struct Uuid(@uuid.UUID)

///|
pub fn Uuid::to_string(self : Uuid) -> String {
  self.0.to_string()
}

///|
pub fn uuid() -> Uuid raise {
  let buffer = @buffer.new()
  buffer.write_uint64_le(@global.rand().uint64())
  buffer.write_uint64_le(@global.rand().uint64())
  @uuid.from_bytes(buffer.to_bytes())
}
