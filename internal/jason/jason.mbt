///|
pub enum Jason {
  Null
  Bool(Bool)
  String(String)
  Number(Number)
  Array(Array[Jason])
  Object(Object)
}

///|
pub fn Jason::type_(self : Jason) -> JasonType {
  match self {
    Number(_) => Number
    String(_) => String
    Array(_) => Array
    Object(_) => Object
    Null => Null
    Bool(_) => Bool
  }
}

///|
pub let null : Jason = Null

///|
pub fn Jason::bool(value : Bool) -> Jason {
  Bool(value)
}

///|
pub fn Jason::number(number : Number) -> Jason {
  Number(number)
}

///|
pub fn Jason::int(value : Int) -> Jason {
  Number(Number::from_int(value))
}

///|
pub fn Jason::int64(value : Int64) -> Jason {
  Number(Number::from_int64(value))
}

///|
pub fn Jason::double(value : Double) -> Jason {
  Number(Number::from_double(value))
}

///|
#as_free_fn
pub fn Jason::string(string : String) -> Jason {
  String(string)
}

///|
#as_free_fn
pub fn Jason::object(object : Object) -> Jason {
  Object(object)
}

///|
#as_free_fn
pub fn Jason::array(array : Array[Jason]) -> Jason {
  Array(array.map(item => item.to_jason()))
}

///|
pub fn Jason::as_string(
  jason : Jason,
  path~ : JasonPath,
) -> String raise DecodeError {
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
pub fn Jason::as_number(
  jason : Jason,
  path~ : JasonPath,
) -> Number raise DecodeError {
  guard jason is Number(value) else {
    raise DecodeError::TypeMismatch(
      path,
      expect=[JasonType::Number],
      actual=jason,
    )
  }
  value
}

///|
pub fn Jason::as_array(
  jason : Jason,
  path~ : JasonPath,
) -> Array[Jason] raise DecodeError {
  guard jason is Array(array) else {
    raise DecodeError::TypeMismatch(
      path,
      expect=[JasonType::Array],
      actual=jason,
    )
  }
  array
}

///|
pub fn Jason::from_json(json : Json) -> Jason {
  match json {
    Null => Null
    True => Bool(true)
    False => Bool(false)
    Number(number, repr=None) => Number(number.to_string())
    Number(_, repr=Some(number)) => Number(number)
    String(string) => String(string)
    Array(array) => Array(array.map(item => Jason::from_json(item)))
    Object(object) => Object(object.map((_, v) => Jason::from_json(v)))
  }
}

///|
pub impl FromJson for Jason with from_json(json : Json, _ : @json.JsonPath) -> Jason {
  Jason::from_json(json)
}

///|
pub fn Jason::to_json(self : Jason) -> Json {
  match self {
    Null => Json::null()
    Bool(value) => Json::boolean(value)
    String(value) => Json::string(value)
    Number(number) => Json::number(0.0, repr=number.0)
    Array(array) => {
      let json_array = array.map(item => item.to_json())
      Json::array(json_array)
    }
    Object(object) => {
      let json_object = Map::new()
      for k, v in object.0 {
        json_object[k] = v.to_json()
      }
      Json::object(json_object)
    }
  }
}

///|
pub impl ToJson for Jason with to_json(self : Jason) -> Json {
  self.to_json()
}

///|
pub fn Jason::stringify(
  self : Jason,
  indent? : Int = 0,
  escape_slash? : Bool = true,
) -> String {
  self.to_json().stringify(indent~, escape_slash~)
}
