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
