///|
pub(open) trait ToJason {
  to_jason(Self) -> Jason
}

///|
pub impl ToJason for Jason with to_jason(self : Jason) -> Jason {
  return self
}

///|
pub impl ToJason for Bool with to_jason(self : Bool) -> Jason {
  return Jason::bool(self)
}

///|
pub impl ToJason for String with to_jason(self : String) -> Jason {
  return Jason::string(self)
}

///|
pub impl ToJason for Int64 with to_jason(self : Int64) -> Jason {
  return Jason::int64(self)
}

///|
pub impl ToJason for Int with to_jason(self : Int) -> Jason {
  return Jason::int(self)
}

///|
pub impl ToJason for Double with to_jason(self : Double) -> Jason {
  return Jason::double(self)
}

///|
pub impl[T : ToJason] ToJason for Array[T] with to_jason(self : Array[T]) -> Jason {
  let jason_array = self.map(item => item.to_jason())
  return Array(jason_array)
}

///|
pub impl[T : ToJason] ToJason for FixedArray[T] with to_jason(
  self : FixedArray[T],
) -> Jason {
  let array = []
  for item in self {
    array.push(item.to_jason())
  }
  return Array(array)
}

///|
pub impl[T : ToJason] ToJason for ArrayView[T] with to_jason(
  self : ArrayView[T],
) -> Jason {
  let array = []
  for item in self {
    array.push(item.to_jason())
  }
  return Array(array)
}

///|
pub impl[T : ToJason] ToJason for Map[String, T] with to_jason(
  self : Map[String, T],
) -> Jason {
  Object(self.map((_, v) => v.to_jason()))
}

///|
pub impl ToJason for Json with to_jason(self : Json) -> Jason {
  Jason::from_json(self)
}
