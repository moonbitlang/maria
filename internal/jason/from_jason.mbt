///|
pub(open) trait FromJason {
  from_jason(Jason, path~ : JasonPath) -> Self raise DecodeError
}

///|
pub fn[T : FromJason] from_jason(
  jason : Jason,
  path? : JasonPath = JasonPath::Root,
) -> T raise DecodeError {
  FromJason::from_jason(jason, path~)
}

///|
pub impl FromJason for Jason with from_jason(jason : Jason, path~ : JasonPath) -> Jason raise DecodeError {
  ignore(path)
  jason
}

///|
pub impl FromJason for Bool with from_jason(jason : Jason, path~ : JasonPath) -> Bool raise DecodeError {
  guard jason is Bool(value) else {
    raise DecodeError::TypeMismatch(
      path,
      expect=[JasonType::Bool],
      actual=jason,
    )
  }
  value
}

///|
pub impl FromJason for String with from_jason(jason : Jason, path~ : JasonPath) -> String raise DecodeError {
  guard jason is String(value) else {
    raise DecodeError::TypeMismatch(
      path,
      expect=[JasonType::String],
      actual=jason,
    )
  }
  value
}

///|
pub impl FromJason for Int64 with from_jason(jason : Jason, path~ : JasonPath) -> Int64 raise DecodeError {
  let number = Jason::as_number(jason, path~)
  number.to_int64(path~)
}

///|
pub impl FromJason for Int with from_jason(jason : Jason, path~ : JasonPath) -> Int raise DecodeError {
  let number = Jason::as_number(jason, path~)
  number.to_int(path~)
}

///|
pub impl FromJason for Double with from_jason(jason : Jason, path~ : JasonPath) -> Double raise DecodeError {
  let number = Jason::as_number(jason, path~)
  number.to_double(path~)
}

///|
pub impl FromJason for Number with from_jason(jason : Jason, path~ : JasonPath) -> Number raise DecodeError {
  Jason::as_number(jason, path~)
}

///|
pub impl FromJason for Object with from_jason(jason : Jason, path~ : JasonPath) -> Object raise DecodeError {
  Jason::as_object(jason, path~)
}

///|
pub impl[T : FromJason] FromJason for Array[T] with from_jason(
  jason : Jason,
  path~ : JasonPath,
) -> Array[T] raise DecodeError {
  let array = Jason::as_array(jason, path~)
  let result = Array::new(capacity=array.length())
  for i in 0..<array.length() {
    let item_path = path.add_index(i)
    let item = T::from_jason(array[i], path=item_path)
    result.push(item)
  }
  result
}

///|
pub impl[T : FromJason] FromJason for ArrayView[T] with from_jason(
  jason : Jason,
  path~ : JasonPath,
) -> ArrayView[T] raise DecodeError {
  let array : Array[T] = from_jason(jason, path~)
  array[:]
}

///|
pub impl[T : FromJason] FromJason for FixedArray[T] with from_jason(
  jason : Jason,
  path~ : JasonPath,
) -> FixedArray[T] raise DecodeError {
  let array = Jason::as_array(jason, path~)
  let length = array.length()
  FixedArray::makei(length, i => {
    let item_path = path.add_index(i)
    T::from_jason(array[i], path=item_path)
  })
}

///|
pub impl[T : FromJason] FromJason for Map[String, T] with from_jason(
  jason : Jason,
  path~ : JasonPath,
) -> Map[String, T] raise DecodeError {
  let object = Jason::as_object(jason, path~)
  let result = Map::new()
  for k, v in object.0 {
    let field_path = path.add_key(k)
    let value = T::from_jason(v, path=field_path)
    result[k] = value
  }
  result
}
