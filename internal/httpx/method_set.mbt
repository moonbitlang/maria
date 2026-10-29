///|
priv struct MethodSet {
  mut get : Bool
  mut head : Bool
  mut post : Bool
  mut put : Bool
  mut delete : Bool
  mut connect : Bool
  mut options : Bool
  mut trace : Bool
  mut patch : Bool
}

///|
#alias("_[_]")
fn MethodSet::get_exn(self : MethodSet, method_ : Method) -> Bool {
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
#alias("_[_]=_")
fn MethodSet::set(self : MethodSet, method_ : Method, value : Bool) -> Unit {
  match method_ {
    Method::Get => self.get = value
    Method::Head => self.head = value
    Method::Post => self.post = value
    Method::Put => self.put = value
    Method::Delete => self.delete = value
    Method::Connect => self.connect = value
    Method::Options => self.options = value
    Method::Trace => self.trace = value
    Method::Patch => self.patch = value
  }
}

///|
fn MethodSet::iterator(self : MethodSet) -> Iter[Method] {
  methods.iter().filter(method_ => self[method_])
}

///|
fn MethodSet::new() -> MethodSet {
  MethodSet::{
    get: false,
    head: false,
    post: false,
    put: false,
    delete: false,
    connect: false,
    options: false,
    trace: false,
    patch: false,
  }
}
