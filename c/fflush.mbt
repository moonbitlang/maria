///|
extern "c" fn c_fflush(stream : FILE) -> Int = "fflush"

///|
trait ToNullableFILE {
  to_nullable_FILE(self : Self) -> FILE
}

///|
pub impl ToNullableFILE for FILE with to_nullable_FILE(self : FILE) -> FILE {
  self
}

///|
pub impl ToNullableFILE for Null with to_nullable_FILE(self : Null) -> FILE = "%identity"

///|
pub fn[T : ToNullableFILE] fflush(stream : T) -> Int {
  c_fflush(T::to_nullable_FILE(stream))
}
