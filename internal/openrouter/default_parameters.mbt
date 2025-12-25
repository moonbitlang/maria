pub struct DefaultParameters {
  temperature: Double?
  top_p: Double?
  frequency_penalty: Double?
}

pub fn DefaultParameters::new(
  temperature? : Double,
  top_p? : Double,
  frequency_penalty? : Double,
) -> DefaultParameters {
  DefaultParameters::{
    temperature,
    top_p,
    frequency_penalty,
  }
}
