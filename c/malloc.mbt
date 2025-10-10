///|
extern "c" fn c_malloc(size : UInt64) -> Pointer[Unit] = "moonbit_c_malloc"

///|
pub fn[T] malloc(size : UInt64) -> Pointer[T] {
  c_malloc(size).cast()
}

///|
extern "c" fn c_free(ptr : Pointer[Unit]) = "moonbit_c_free"

///|
pub fn[T] free(ptr : Pointer[T]) -> Unit {
  c_free(ptr.cast())
}
