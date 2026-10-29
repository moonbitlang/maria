///|
pub(all) suberror InvalidArgument {
  InvalidArgument(String)
} derive(Debug, ToJson)

///|
pub extend InvalidArgument with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend InvalidArgument with ToJson::{to_json}
