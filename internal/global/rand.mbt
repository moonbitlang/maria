///|
let g_rand : Ref[@random.Rand?] = Ref::new(None)

///|
pub fn rand() -> @random.Rand {
  match g_rand.val {
    None => {
      let seed = Bytes::make(32, 0)
      let mut error = None
      try {
        let uv = uv()
        let _ = uv.random(seed, 0, _ => (), e => error = Some(e))
        uv.run(Default)
        if error is Some(error) {
          raise error
        }
      } catch {
        error => abort("uv.random: \{@utf8.decode_lossy(error.to_bytes())}")
      }
      let rand = @random.Rand::chacha8(seed~)
      g_rand.val = Some(rand)
      rand
    }
    Some(rand) => rand
  }
}

///|
pub fn seed(seed? : Bytes) -> Unit {
  let rand = @random.Rand::chacha8(seed?)
  g_rand.val = Some(rand)
}
