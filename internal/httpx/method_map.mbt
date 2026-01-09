///|
priv struct MethodMap[T] {
  mut get : T?
  mut head : T?
  mut post : T?
  mut put : T?
  mut delete : T?
  mut connect : T?
  mut options : T?
  mut trace : T?
  mut patch : T?
}

///|
fn[T] MethodMap::get(self : MethodMap[T], method_ : Method) -> T? {
  match method_ {
    Method::Get => self.get
    Method::Head => self.head
    Method::Post => self.post
    Method::Put => self.put
    Method::Delete => self.delete
    Method::Connect => self.connect
    Method::Options => self.options
    Method::Trace => self.trace
    Method::Patch => self.patch
  }
}

///|
fn[T] MethodMap::op_get(self : MethodMap[T], method_ : Method) -> T {
  guard self.get(method_) is Some(value) else {
    abort("MethodMap: no value for method \{method_}")
  }
  value
}

///|
fn[T] MethodMap::op_set(
  self : MethodMap[T],
  method_ : Method,
  value : T,
) -> Unit {
  match method_ {
    Method::Get => self.get = Some(value)
    Method::Head => self.head = Some(value)
    Method::Post => self.post = Some(value)
    Method::Put => self.put = Some(value)
    Method::Delete => self.delete = Some(value)
    Method::Connect => self.connect = Some(value)
    Method::Options => self.options = Some(value)
    Method::Trace => self.trace = Some(value)
    Method::Patch => self.patch = Some(value)
  }
}

///|
fn[T] MethodMap::new() -> MethodMap[T] {
  MethodMap::{
    get: None,
    head: None,
    post: None,
    put: None,
    delete: None,
    connect: None,
    options: None,
    trace: None,
    patch: None,
  }
}

///|
fn[T] MethodMap::keys(self : MethodMap[T]) -> Iter[Method] {
  let mut i = 0
  Iter::new(() => while i < methods.length() {
    let method_ = methods[i]
    i += 1
    if self.get(method_) is Some(_) {
      break Some(method_)
    }
  } else {
    None
  })
}
