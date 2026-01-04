///|
pub enum JasonPath {
  Root
  Key(JasonPath, String)
  Index(JasonPath, Int)
}

///|
pub fn JasonPath::root() -> JasonPath {
  Root
}

///|
pub fn JasonPath::add_index(self : JasonPath, index : Int) -> JasonPath {
  Index(self, index)
}

///|
pub fn JasonPath::add_key(self : JasonPath, key : String) -> JasonPath {
  Key(self, key)
}
