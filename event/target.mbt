///|
struct Target[K, C](Map[K, Array[async (C) -> Unit noraise]])

///|
pub fn[Kind : Eq + Hash, Context] Target::new() -> Target[Kind, Context] {
  Target({})
}

///|
pub async fn[Kind : Eq + Hash, Context] Target::emit(
  target : Target[Kind, Context],
  kind : Kind,
  context : Context,
) -> Unit noraise {
  guard target.0.get(kind) is Some(listeners) else { return }
  for listener in listeners {
    listener(context)
  }
}

///|
pub fn[Kind : Eq + Hash, Context] Target::add_listener(
  target : Target[Kind, Context],
  kind : Kind,
  f : async (Context) -> Unit noraise,
) -> Unit noraise {
  if target.0.get(kind) is Some(listeners) {
    listeners.push(f)
  } else {
    target.0[kind] = [f]
  }
}
