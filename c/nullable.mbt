// ///|
// #external
// #deprecated("Nullable[T] can leak memory if T is a managed type. Define a null value for type `T` yourself instead.")
// pub type Nullable[_]

// ///|
// fn[T] Nullable::_some(value : T) -> Nullable[T] = "%identity"

// ///|
// pub fn[T] Nullable::some(value : T) -> Nullable[T] {
//   Nullable::_some(value).cast()
// }

// ///|
// fn[T] Nullable::_unwrap(self : Nullable[T]) -> T = "%identity"

// ///|
// fn[T] Nullable::unwrap(self : Nullable[T]) -> T {
//   self.cast()._unwrap()
// }

// ///|
// extern "c" fn Nullable::_none() -> Nullable[Unit] = "moonbit_c_null"

// ///|
// fn[T, U] Nullable::_type_cast(self : Nullable[T]) -> Nullable[U] = "%identity"

// ///|
// extern "c" fn Nullable::_impl_cast(self : Nullable[Unit]) -> Nullable[Unit] = "moonbit_c_identity"

// ///|
// fn[T, U] Nullable::cast(self : Nullable[T]) -> Nullable[U] {
//   self._type_cast()._impl_cast()._type_cast()
// }

// ///|
// pub fn[T] Nullable::none() -> Nullable[T] {
//   Nullable::_none().cast()
// }

// ///|
// pub fn[T] none() -> Nullable[T] {
//   Nullable::_none().cast()
// }

// ///|
// extern "c" fn Nullable::_is_null(self : Nullable[Unit]) -> Bool = "moonbit_c_is_null"

// ///|
// pub fn[T] Nullable::is_null(self : Nullable[T]) -> Bool {
//   self.cast()._is_null()
// }

// ///|
// pub fn[T] Nullable::of(option : T?) -> Nullable[T] {
//   match option {
//     Some(value) => Nullable::some(value)
//     None => Nullable::none()
//   }
// }

// ///|
// pub fn[T] Nullable::to(self : Nullable[T]) -> T? {
//   if self.is_null() {
//     return None
//   } else {
//     return Some(self.unwrap())
//   }
// }

///|
#external
pub type Null

///|
extern "c" fn c_null() -> Null = "moonbit_c_null"

///|
pub let null : Null = c_null()
