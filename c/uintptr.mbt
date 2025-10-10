///|
#external
pub type UIntPtr

///|
pub extern "c" fn UIntPtr::to_byte(self : UIntPtr) -> Byte = "moonbit_maria_c_uintptr_to_byte"

///|
pub extern "c" fn UIntPtr::to_int16(self : UIntPtr) -> Int16 = "moonbit_maria_c_uintptr_to_int16"

///|
pub extern "c" fn UIntPtr::to_uint16(self : UIntPtr) -> UInt16 = "moonbit_maria_c_uintptr_to_uint16"

///|
pub extern "c" fn UIntPtr::to_int(self : UIntPtr) -> Int = "moonbit_maria_c_uintptr_to_int"

///|
pub extern "c" fn UIntPtr::to_uint(self : UIntPtr) -> Int = "moonbit_maria_c_uintptr_to_uint"

///|
pub extern "c" fn UIntPtr::to_int64(self : UIntPtr) -> Int64 = "moonbit_maria_c_uintptr_to_int64"

///|
pub extern "c" fn UIntPtr::to_uint64(self : UIntPtr) -> Int64 = "moonbit_maria_c_uintptr_to_uint64"

///|
pub extern "c" fn UIntPtr::from_byte(value : Byte) -> UIntPtr = "moonbit_maria_c_uintptr_from_byte"

///|
pub extern "c" fn UIntPtr::from_int16(value : Int16) -> UIntPtr = "moonbit_maria_c_uintptr_from_int16"

///|
pub extern "c" fn UIntPtr::from_uint16(value : UInt16) -> UIntPtr = "moonbit_maria_c_uintptr_from_uint16"

///|
pub extern "c" fn UIntPtr::from_int(value : Int) -> UIntPtr = "moonbit_maria_c_uintptr_from_int"

///|
pub extern "c" fn UIntPtr::from_uint(value : UInt) -> UIntPtr = "moonbit_maria_c_uintptr_from_uint"

///|
pub extern "c" fn UIntPtr::from_int64(value : Int64) -> UIntPtr = "moonbit_maria_c_uintptr_from_int64"

///|
pub extern "c" fn UIntPtr::from_uint64(value : UInt64) -> UIntPtr = "moonbit_maria_c_uintptr_from_uint64"

///|
extern "c" fn uintptr_from_pointer(value : Pointer[Byte]) -> UIntPtr = "moonbit_maria_c_uintptr_from_pointer"

///|
pub fn[T] UIntPtr::from_pointer(value : Pointer[T]) -> UIntPtr {
  uintptr_from_pointer(value.cast())
}

///|
pub impl Show for UIntPtr with output(self : UIntPtr, logger : &Logger) -> Unit {
  logger.write_string("0x\{self.to_uint64().to_string(radix=16)}")
}

///|
pub impl ToJson for UIntPtr with to_json(self : UIntPtr) -> Json {
  self.to_string().to_json()
}
