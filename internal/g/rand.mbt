///|
let g_rand : Ref[@random.Rand?] = Ref::new(None)

///|
pub fn rand() -> @random.Rand raise @uv.Errno {
  match g_rand.val {
    None => {
      let uv = uv()
      let seed = Bytes::make(32, 0)
      let mut error = None
      let _ = uv.random(seed, 0, _ => (), e => error = Some(e))
      uv.run(Default)
      if error is Some(error) {
        raise error
      }
      let rand = @random.Rand::chacha8(seed~)
      g_rand.val = Some(rand)
      rand
    }
    Some(rand) => rand
  }
}

///|
pub fn set_seed(seed? : Bytes) -> Unit {
  let rand = @random.Rand::chacha8(seed?)
  g_rand.val = Some(rand)
}
