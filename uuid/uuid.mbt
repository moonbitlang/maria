///|
struct UUID(@uuid.UUID)

///|
pub fn uuid() -> UUID {
  let buffer = @buffer.new()
  buffer.write_uint64_be(@global.rand().uint64())
  buffer.write_uint64_be(@global.rand().uint64())
  @uuid.from_bytes(buffer.to_bytes()) catch {
    error => abort("uuid.from_bytes: \{error}")
  }
}

///|
pub fn UUID::to_string(self : UUID) -> String {
  self.0.to_string()
}
