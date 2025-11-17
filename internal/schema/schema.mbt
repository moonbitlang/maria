// Copyright 2025 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

///|
enum Schema {
  Integer
  String
  Object(
    Map[String, Schema],
    required~ : Array[String]?,
    additional_properties~ : Bool
  )
  Array(Schema)
  Enum(Array[Json])
}

///|
pub fn integer() -> Schema {
  Schema::Integer
}

///|
pub fn string() -> Schema {
  Schema::String
}

///|
pub fn object(
  object : Map[String, Schema],
  additional_properties? : Bool = true,
  required? : Array[String],
) -> Schema {
  Schema::Object(object, required~, additional_properties~)
}

///|
pub fn enums(values : Array[Json]) -> Schema {
  Schema::Enum(values)
}

///|
pub fn array(schema : Schema) -> Schema {
  Schema::Array(schema)
}

///|
pub fn Schema::to_json(self : Schema) -> Map[String, Json] {
  match self {
    Schema::Integer => { "type": "integer" }
    Schema::String => { "type": "string" }
    Schema::Enum(values) => { "enum": Json::array(values) }
    Schema::Array(schema) => { "type": "array", "items": schema }
    Schema::Object(map, required~, additional_properties~) => {
      let json_object = Map::new()
      for key, value in map {
        json_object[key] = value.to_json()
      }
      let result : Map[String, Json] = {
        "type": "object",
        "properties": json_object,
      }
      if required is Some(required) {
        result["required"] = Json::array(required.map(Json::string))
      }
      if not(additional_properties) {
        result["additionalProperties"] = false
      }
      result
    }
  }
}

///|
pub impl ToJson for Schema with to_json(self) {
  self.to_json().to_json()
}

///|
pub fn Schema::verify(self : Schema, json : Json) -> Bool {
  match (self, json) {
    (Schema::Integer, Number(n, ..)) => n == n && n.to_int().to_double() == n
    (Schema::String, String(_)) => true
    (Schema::Enum(values), _) => values.contains(json)
    (Schema::Array(schema), Array(values)) =>
      values.iter().all(schema.verify(_))
    (
      Schema::Object(map, required~, additional_properties=additionalProperties),
      Object(json),
    ) => {
      let required = @sorted_set.from_array(required.unwrap_or([]))
      for key, value in map {
        if json.get(key) is Some(json) {
          if not(value.verify(json)) {
            return false
          }
        } else if required.contains(key) {
          return false
        }
      }
      for key, _ in json {
        if not(map.contains(key)) && not(additionalProperties) {
          return false
        }
      }
      true
    }
    _ => false
  }
}

///|
test "to_json" {
  @json.inspect(
    object({
      "name": object({
        "firstName": string(),
        "lastName": string(),
        "middleName": string(),
      }),
    }),
    content={
      "type": "object",
      "properties": {
        "name": {
          "type": "object",
          "properties": {
            "firstName": { "type": "string" },
            "lastName": { "type": "string" },
            "middleName": { "type": "string" },
          },
        },
      },
    },
  )
  @json.inspect(
    object({
      "name": object(
        { "firstName": string(), "lastName": string(), "middleName": string() },
        required=["firstName", "lastName"],
      ),
      "age": integer(),
    }),
    content={
      "type": "object",
      "properties": {
        "name": {
          "type": "object",
          "properties": {
            "firstName": { "type": "string" },
            "lastName": { "type": "string" },
            "middleName": { "type": "string" },
          },
          "required": ["firstName", "lastName"],
        },
        "age": { "type": "integer" },
      },
    },
  )
}

///|
test "verify" {
  let schema = object({
    "name": object({
      "firstName": string(),
      "lastName": string(),
      "middleName": string(),
    }),
  })
  assert_true(
    schema.verify({
      "name": { "firstName": "John", "lastName": "Doe", "middleName": "Smith" },
    }),
  )
  assert_false(
    schema.verify({ "name": { "firstName": "John", "lastName": 1 } }),
  )
  let schema = object({
    "name": object(
      { "firstName": string(), "lastName": string(), "middleName": string() },
      required=["firstName", "lastName"],
    ),
    "age": integer(),
  })
  assert_true(
    schema.verify({
      "name": { "firstName": "John", "lastName": "Doe" },
      "age": 30,
    }),
  )
  assert_false(schema.verify({ "name": { "firstName": "John" }, "age": 30 }))
}
