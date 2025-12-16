///|
enum Quantizations {
  Int4
  Int8
  Fp4
  Fp6
  Fp8
  Fp16
  Bf16
  Fp32
  Unknown
}

///|
pub impl ToJson for Quantizations with to_json(self : Quantizations) -> Json {
  match self {
    Int4 => "int4"
    Int8 => "int8"
    Fp4 => "fp4"
    Fp6 => "fp6"
    Fp8 => "fp8"
    Fp16 => "fp16"
    Bf16 => "bf16"
    Fp32 => "fp32"
    Unknown => "unknown"
  }
}

///|
pub impl @json.FromJson for Quantizations with from_json(
  json : Json,
  path : @json.JsonPath,
) -> Quantizations raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.Quantizations::from_json"
  guard json is String(s) else {
    raise @json.JsonDecodeError((path, "\{func_name}: expect string"))
  }
  match s {
    "int4" => Quantizations::Int4
    "int8" => Quantizations::Int8
    "fp4" => Quantizations::Fp4
    "fp6" => Quantizations::Fp6
    "fp8" => Quantizations::Fp8
    "fp16" => Quantizations::Fp16
    "bf16" => Quantizations::Bf16
    "fp32" => Quantizations::Fp32
    "unknown" => Quantizations::Unknown
    _ =>
      raise @json.JsonDecodeError(
        (path, "\{func_name}: invalid value \"\{s}\""),
      )
  }
}
