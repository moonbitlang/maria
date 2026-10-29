///|
/// Opaque raw pointer type used for C interop.
///
/// `Pointer[T]` represents an unmanaged memory address that is assumed to
/// point to a value (or array of values) of type `T`. All operations on
/// pointers are inherently unsafe and should be used with care.
#external
#alias(Ptr)
pub type Pointer[_]

///|
/// Unsafely reinterprets a pointer as pointing to a different element type.
///
/// This does not change the underlying address; only the static type
/// information is updated. The caller must ensure that the cast is valid.
pub fn[T, U] Pointer::cast(self : Pointer[T]) -> Pointer[U] = "%identity"

///|
/// Low-level binding used to check whether a pointer is null.
extern "c" fn Pointer::_is_null(ptr : Pointer[Unit]) -> Bool = "moonbit_maria_c_is_null"

///|
/// Returns `true` when the pointer is equal to the null pointer.
pub fn[T] Pointer::is_null(self : Pointer[T]) -> Bool {
  self.cast()._is_null()
}

///|
/// Returns the canonical null pointer value.
extern "c" fn Pointer::_null() -> Pointer[Unit] = "moonbit_maria_c_null"

///|
/// Creates a null pointer of type `Pointer[T]`.
pub fn[T] Pointer::null() -> Pointer[T] {
  Pointer::_null().cast()
}

///|
/// Compares two raw pointers for address equality.
pub extern "c" fn Pointer::op_equal(
  self : Pointer[Unit],
  other : Pointer[Unit],
) -> Bool = "moonbit_maria_c_pointer_equal"

///|
/// Implements structural equality for pointers via `op_equal`.
pub impl[T] Eq for Pointer[T] with fn equal(
  self : Pointer[T],
  other : Pointer[T],
) -> Bool {
  self.cast().op_equal(other.cast())
}

///|
/// Indexing helper that loads the `index`-th element via `Load`.
#alias("_[_]")
pub fn[T : Load] Pointer::get(self : Pointer[T], index : Int32) -> T {
  T::load(self, index)
}

///|
/// Indexing helper that stores into the `index`-th element via `Store`.
#alias("_[_]=_")
pub fn[T : Store] Pointer::set(
  self : Pointer[T],
  index : Int32,
  value : T,
) -> Unit {
  T::store(self, index, value)
}

///|
/// Loads a value of type `T` from this pointer at `offset`.
pub fn[T : Load] Pointer::load(self : Pointer[T], offset~ : Int32 = 0) -> T {
  T::load(self, offset)
}

///|
/// Stores a value of type `T` into this pointer at `offset`.
pub fn[T : Store] Pointer::store(
  self : Pointer[T],
  offset~ : Int32 = 0,
  value : T,
) -> Unit {
  T::store(self, offset, value)
}

///|
/// Trait for types that can be loaded from raw memory.
///
/// Implementations of `Load` define how to read a value of the given type
/// from a `Pointer[Self]` at a specific element offset.
pub(open) trait Load {
  fn load(Pointer[Self], Int32) -> Self
}

///|
/// Raw C bindings used by `Load` implementations for primitive types.
extern "c" fn moonbit_c_load_byte(
  pointer : Pointer[Byte],
  offset : Int32,
) -> Byte = "moonbit_maria_c_load_byte"

///|
extern "c" fn moonbit_c_load_int16(
  pointer : Pointer[Int16],
  offset : Int32,
) -> Int16 = "moonbit_maria_c_load_int16"

///|
extern "c" fn moonbit_c_load_uint16(
  pointer : Pointer[UInt16],
  offset : Int32,
) -> UInt16 = "moonbit_maria_c_load_uint16"

///|
extern "c" fn moonbit_c_load_int(
  pointer : Pointer[Int32],
  offset : Int32,
) -> Int32 = "moonbit_maria_c_load_int"

///|
extern "c" fn moonbit_c_load_uint(
  pointer : Pointer[UInt32],
  offset : Int32,
) -> UInt32 = "moonbit_maria_c_load_uint"

///|
extern "c" fn moonbit_c_load_int64(
  pointer : Pointer[Int64],
  offset : Int32,
) -> Int64 = "moonbit_maria_c_load_int64"

///|
extern "c" fn moonbit_c_load_uint64(
  pointer : Pointer[UInt64],
  offset : Int32,
) -> UInt64 = "moonbit_maria_c_load_uint64"

///|
extern "c" fn moonbit_c_load_float(
  pointer : Pointer[Float],
  offset : Int32,
) -> Float = "moonbit_maria_c_load_float"

///|
extern "c" fn moonbit_c_load_double(
  pointer : Pointer[Double],
  offset : Int32,
) -> Double = "moonbit_maria_c_load_double"

///|
pub impl Load for Byte with fn load(pointer : Pointer[Byte], offset : Int32) -> Byte {
  moonbit_c_load_byte(pointer, offset)
}

///|
pub impl Load for Int16 with fn load(pointer : Pointer[Int16], offset : Int32) -> Int16 {
  moonbit_c_load_int16(pointer, offset)
}

///|
pub impl Load for UInt16 with fn load(pointer : Pointer[UInt16], offset : Int32) -> UInt16 {
  moonbit_c_load_uint16(pointer, offset)
}

///|
pub impl Load for Int32 with fn load(pointer : Pointer[Int32], offset : Int32) -> Int32 {
  moonbit_c_load_int(pointer, offset)
}

///|
pub impl Load for UInt32 with fn load(pointer : Pointer[UInt32], offset : Int32) -> UInt32 {
  moonbit_c_load_uint(pointer, offset)
}

///|
pub impl Load for Int64 with fn load(pointer : Pointer[Int64], offset : Int32) -> Int64 {
  moonbit_c_load_int64(pointer, offset)
}

///|
pub impl Load for UInt64 with fn load(pointer : Pointer[UInt64], offset : Int32) -> UInt64 {
  moonbit_c_load_uint64(pointer, offset)
}

///|
pub impl Load for Float with fn load(pointer : Pointer[Float], offset : Int32) -> Float {
  moonbit_c_load_float(pointer, offset)
}

///|
pub impl Load for Double with fn load(pointer : Pointer[Double], offset : Int32) -> Double {
  moonbit_c_load_double(pointer, offset)
}

///|
/// Raw C bindings used by `Store` implementations for primitive types.
extern "c" fn moonbit_c_store_byte(
  pointer : Pointer[Byte],
  offset : Int32,
  value : Byte,
) -> Unit = "moonbit_maria_c_store_byte"

///|
extern "c" fn moonbit_c_store_int16(
  pointer : Pointer[Int16],
  offset : Int32,
  value : Int16,
) -> Unit = "moonbit_maria_c_store_int16"

///|
extern "c" fn moonbit_c_store_uint16(
  pointer : Pointer[UInt16],
  offset : Int32,
  value : UInt16,
) -> Unit = "moonbit_maria_c_store_uint16"

///|
extern "c" fn moonbit_c_store_int(
  pointer : Pointer[Int32],
  offset : Int32,
  value : Int32,
) -> Unit = "moonbit_maria_c_store_int"

///|
extern "c" fn moonbit_c_store_uint(
  pointer : Pointer[UInt32],
  offset : Int32,
  value : UInt32,
) -> Unit = "moonbit_maria_c_store_uint"

///|
extern "c" fn moonbit_c_store_int64(
  pointer : Pointer[Int64],
  offset : Int32,
  value : Int64,
) -> Unit = "moonbit_maria_c_store_int64"

///|
extern "c" fn moonbit_c_store_uint64(
  pointer : Pointer[UInt64],
  offset : Int32,
  value : UInt64,
) -> Unit = "moonbit_maria_c_store_uint64"

///|
extern "c" fn moonbit_c_store_float(
  pointer : Pointer[Float],
  offset : Int32,
  value : Float,
) -> Unit = "moonbit_maria_c_store_float"

///|
extern "c" fn moonbit_c_store_double(
  pointer : Pointer[Double],
  offset : Int32,
  value : Double,
) -> Unit = "moonbit_maria_c_store_double"

///|
/// Trait for types that can be stored into raw memory.
///
/// Implementations of `Store` define how to write a value of the given type
/// into a `Pointer[Self]` at a specific element offset.
trait Store {
  fn store(Pointer[Self], Int32, Self) -> Unit
}

///|
pub impl Store for Byte with fn store(
  pointer : Pointer[Byte],
  offset : Int32,
  value : Byte,
) -> Unit {
  moonbit_c_store_byte(pointer, offset, value)
}

///|
pub impl Store for Int16 with fn store(
  pointer : Pointer[Int16],
  offset : Int32,
  value : Int16,
) -> Unit {
  moonbit_c_store_int16(pointer, offset, value)
}

///|
pub impl Store for UInt16 with fn store(
  pointer : Pointer[UInt16],
  offset : Int32,
  value : UInt16,
) -> Unit {
  moonbit_c_store_uint16(pointer, offset, value)
}

///|
pub impl Store for Int32 with fn store(
  pointer : Pointer[Int32],
  offset : Int32,
  value : Int32,
) -> Unit {
  moonbit_c_store_int(pointer, offset, value)
}

///|
pub impl Store for UInt32 with fn store(
  pointer : Pointer[UInt32],
  offset : Int32,
  value : UInt32,
) -> Unit {
  moonbit_c_store_uint(pointer, offset, value)
}

///|
pub impl Store for Int64 with fn store(
  pointer : Pointer[Int64],
  offset : Int32,
  value : Int64,
) -> Unit {
  moonbit_c_store_int64(pointer, offset, value)
}

///|
pub impl Store for UInt64 with fn store(
  pointer : Pointer[UInt64],
  offset : Int32,
  value : UInt64,
) -> Unit {
  moonbit_c_store_uint64(pointer, offset, value)
}

///|
pub impl Store for Float with fn store(
  pointer : Pointer[Float],
  offset : Int32,
  value : Float,
) -> Unit {
  moonbit_c_store_float(pointer, offset, value)
}

///|
pub impl Store for Double with fn store(
  pointer : Pointer[Double],
  offset : Int32,
  value : Double,
) -> Unit {
  moonbit_c_store_double(pointer, offset, value)
}

///|
pub extend Pointer with Eq::{not_equal, equal}
