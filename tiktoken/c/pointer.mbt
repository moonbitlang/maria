///|
#external
pub type Pointer[_]

///|
pub typealias Pointer as Ptr

///|
pub fn[T, U] Pointer::cast(self : Pointer[T]) -> Pointer[U] = "%identity"

///|
extern "c" fn Pointer::_is_null(ptr : Pointer[Unit]) -> Bool = "moonbit_maria_c_is_null"

///|
pub fn[T] Pointer::is_null(self : Pointer[T]) -> Bool {
  self.cast()._is_null()
}

///|
extern "c" fn Pointer::_null() -> Pointer[Unit] = "moonbit_maria_c_null"

///|
pub fn[T] Pointer::null() -> Pointer[T] {
  Pointer::_null().cast()
}

///|
pub extern "c" fn Pointer::op_equal(
  self : Pointer[Unit],
  other : Pointer[Unit],
) -> Bool = "moonbit_maria_c_pointer_equal"

///|
pub impl[T] Eq for Pointer[T] with equal(self : Pointer[T], other : Pointer[T]) -> Bool {
  self.cast().op_equal(other.cast())
}

///|
pub fn[T : Load] Pointer::op_get(self : Pointer[T], index : Int) -> T {
  T::load(self, index)
}

///|
pub fn[T : Store] Pointer::op_set(
  self : Pointer[T],
  index : Int,
  value : T,
) -> Unit {
  T::store(self, index, value)
}

///|
pub fn[T : Load] Pointer::load(self : Pointer[T], offset? : Int = 0) -> T {
  T::load(self, offset)
}

///|
pub fn[T : Store] Pointer::store(
  self : Pointer[T],
  offset? : Int = 0,
  value : T,
) -> Unit {
  T::store(self, offset, value)
}

///|
pub(open) trait Load {
  load(Pointer[Self], Int) -> Self
}

///|
extern "c" fn moonbit_c_load_byte(
  pointer : Pointer[Byte],
  offset : Int,
) -> Byte = "moonbit_maria_c_load_byte"

///|
extern "c" fn moonbit_c_load_int16(
  pointer : Pointer[Int16],
  offset : Int,
) -> Int16 = "moonbit_maria_c_load_int16"

///|
extern "c" fn moonbit_c_load_uint16(
  pointer : Pointer[UInt16],
  offset : Int,
) -> UInt16 = "moonbit_maria_c_load_uint16"

///|
extern "c" fn moonbit_c_load_int(pointer : Pointer[Int], offset : Int) -> Int = "moonbit_maria_c_load_int"

///|
extern "c" fn moonbit_c_load_uint(
  pointer : Pointer[UInt],
  offset : Int,
) -> UInt = "moonbit_maria_c_load_uint"

///|
extern "c" fn moonbit_c_load_int64(
  pointer : Pointer[Int64],
  offset : Int,
) -> Int64 = "moonbit_maria_c_load_int64"

///|
extern "c" fn moonbit_c_load_uint64(
  pointer : Pointer[UInt64],
  offset : Int,
) -> UInt64 = "moonbit_maria_c_load_uint64"

///|
extern "c" fn moonbit_c_load_float(
  pointer : Pointer[Float],
  offset : Int,
) -> Float = "moonbit_maria_c_load_float"

///|
extern "c" fn moonbit_c_load_double(
  pointer : Pointer[Double],
  offset : Int,
) -> Double = "moonbit_maria_c_load_double"

///|
pub impl Load for Byte with load(pointer : Pointer[Byte], offset : Int) -> Byte {
  moonbit_c_load_byte(pointer, offset)
}

///|
pub impl Load for Int16 with load(pointer : Pointer[Int16], offset : Int) -> Int16 {
  moonbit_c_load_int16(pointer, offset)
}

///|
pub impl Load for UInt16 with load(pointer : Pointer[UInt16], offset : Int) -> UInt16 {
  moonbit_c_load_uint16(pointer, offset)
}

///|
pub impl Load for Int with load(pointer : Pointer[Int], offset : Int) -> Int {
  moonbit_c_load_int(pointer, offset)
}

///|
pub impl Load for UInt with load(pointer : Pointer[UInt], offset : Int) -> UInt {
  moonbit_c_load_uint(pointer, offset)
}

///|
pub impl Load for Int64 with load(pointer : Pointer[Int64], offset : Int) -> Int64 {
  moonbit_c_load_int64(pointer, offset)
}

///|
pub impl Load for UInt64 with load(pointer : Pointer[UInt64], offset : Int) -> UInt64 {
  moonbit_c_load_uint64(pointer, offset)
}

///|
pub impl Load for Float with load(pointer : Pointer[Float], offset : Int) -> Float {
  moonbit_c_load_float(pointer, offset)
}

///|
pub impl Load for Double with load(pointer : Pointer[Double], offset : Int) -> Double {
  moonbit_c_load_double(pointer, offset)
}

///|
extern "c" fn moonbit_c_store_byte(
  pointer : Pointer[Byte],
  offset : Int,
  value : Byte,
) -> Unit = "moonbit_maria_c_store_byte"

///|
extern "c" fn moonbit_c_store_int16(
  pointer : Pointer[Int16],
  offset : Int,
  value : Int16,
) -> Unit = "moonbit_maria_c_store_int16"

///|
extern "c" fn moonbit_c_store_uint16(
  pointer : Pointer[UInt16],
  offset : Int,
  value : UInt16,
) -> Unit = "moonbit_maria_c_store_uint16"

///|
extern "c" fn moonbit_c_store_int(
  pointer : Pointer[Int],
  offset : Int,
  value : Int,
) -> Unit = "moonbit_maria_c_store_int"

///|
extern "c" fn moonbit_c_store_uint(
  pointer : Pointer[UInt],
  offset : Int,
  value : UInt,
) -> Unit = "moonbit_maria_c_store_uint"

///|
extern "c" fn moonbit_c_store_int64(
  pointer : Pointer[Int64],
  offset : Int,
  value : Int64,
) -> Unit = "moonbit_maria_c_store_int64"

///|
extern "c" fn moonbit_c_store_uint64(
  pointer : Pointer[UInt64],
  offset : Int,
  value : UInt64,
) -> Unit = "moonbit_maria_c_store_uint64"

///|
extern "c" fn moonbit_c_store_float(
  pointer : Pointer[Float],
  offset : Int,
  value : Float,
) -> Unit = "moonbit_maria_c_store_float"

///|
extern "c" fn moonbit_c_store_double(
  pointer : Pointer[Double],
  offset : Int,
  value : Double,
) -> Unit = "moonbit_maria_c_store_double"

///|
trait Store {
  store(Pointer[Self], Int, Self) -> Unit
}

///|
pub impl Store for Byte with store(
  pointer : Pointer[Byte],
  offset : Int,
  value : Byte,
) -> Unit {
  moonbit_c_store_byte(pointer, offset, value)
}

///|
pub impl Store for Int16 with store(
  pointer : Pointer[Int16],
  offset : Int,
  value : Int16,
) -> Unit {
  moonbit_c_store_int16(pointer, offset, value)
}

///|
pub impl Store for UInt16 with store(
  pointer : Pointer[UInt16],
  offset : Int,
  value : UInt16,
) -> Unit {
  moonbit_c_store_uint16(pointer, offset, value)
}

///|
pub impl Store for Int with store(
  pointer : Pointer[Int],
  offset : Int,
  value : Int,
) -> Unit {
  moonbit_c_store_int(pointer, offset, value)
}

///|
pub impl Store for UInt with store(
  pointer : Pointer[UInt],
  offset : Int,
  value : UInt,
) -> Unit {
  moonbit_c_store_uint(pointer, offset, value)
}

///|
pub impl Store for Int64 with store(
  pointer : Pointer[Int64],
  offset : Int,
  value : Int64,
) -> Unit {
  moonbit_c_store_int64(pointer, offset, value)
}

///|
pub impl Store for UInt64 with store(
  pointer : Pointer[UInt64],
  offset : Int,
  value : UInt64,
) -> Unit {
  moonbit_c_store_uint64(pointer, offset, value)
}

///|
pub impl Store for Float with store(
  pointer : Pointer[Float],
  offset : Int,
  value : Float,
) -> Unit {
  moonbit_c_store_float(pointer, offset, value)
}

///|
pub impl Store for Double with store(
  pointer : Pointer[Double],
  offset : Int,
  value : Double,
) -> Unit {
  moonbit_c_store_double(pointer, offset, value)
}
