///|
pub fn PathBuilder::from_path(path : Path) -> PathBuilder {
  match path {
    UPath({ prefix, directory, file }) => {
      let directory = Array::from_fixed_array(directory.0)
      let mut basename = Option::None
      let mut extension = Option::None
      match file {
        None => ()
        Some({ base, extension: Some(ext) }) => {
          basename = Some(base)
          extension = Some(ext)
        }
        Some({ base, extension: None }) => basename = Some(base)
      }
      PathBuilder::UPathBuilder(prefix~, directory~, basename~, extension~)
    }
    WPath({ prefix, directory, file }) => {
      let directory = Array::from_fixed_array(directory.0)
      let mut basename = Option::None
      let mut extension = Option::None
      match file {
        None => ()
        Some({ base, extension: Some(ext) }) => {
          basename = Some(base)
          extension = Some(ext)
        }
        Some({ base, extension: None }) => basename = Some(base)
      }
      PathBuilder::WPathBuilder(prefix~, directory~, basename~, extension~)
    }
  }
}

///|
pub fn PathBuilder::to_path(self : PathBuilder) -> Path {
  match self {
    WPathBuilder(prefix~, directory~, basename~, extension~) => {
      let directory : Directory[_] = FixedArray::from_array(directory)
      let file = match basename {
        Some(base) => Some(File::{ base, extension })
        None => None
      }
      Path::WPath({ prefix, directory, file })
    }
    UPathBuilder(prefix~, directory~, basename~, extension~) => {
      let directory : Directory[_] = FixedArray::from_array(directory)
      let file = match basename {
        Some(base) => Some(File::{ base, extension })
        None => None
      }
      Path::UPath({ prefix, directory, file })
    }
  }
}

///|
/// When PathBuilder contains filename this function would panic
pub fn PathBuilder::add_directory(
  self : PathBuilder,
  directory : StringView,
) -> Unit raise PathError {
  match self {
    WPathBuilder(_) as path => {
      guard path.basename is None && path.extension is None
      path.directory.push(PlatformPath::from(directory))
    }
    UPathBuilder(_) as path => {
      guard path.basename is None && path.extension is None
      path.directory.push(PlatformPath::from(directory))
    }
  }
}

///|
pub fn PathBuilder::set_basename(
  self : PathBuilder,
  basename : StringView,
) -> Unit raise PathError {
  match self {
    UPathBuilder(_) as path =>
      path.basename = Some(PlatformPath::from(basename))
    WPathBuilder(_) as path =>
      path.basename = Some(PlatformPath::from(basename))
  }
}

///|
pub fn PathBuilder::set_extension(
  self : PathBuilder,
  extension : StringView,
) -> Unit raise PathError {
  match self {
    UPathBuilder(_) as path =>
      path.extension = Some(PlatformPath::from(extension))
    WPathBuilder(_) as path =>
      path.extension = Some(PlatformPath::from(extension))
  }
}

///|
pub fn PathBuilder::set_file(
  self : PathBuilder,
  base~ : StringView,
  extension~ : StringView,
) -> Unit raise PathError {
  match self {
    UPathBuilder(_) as path => {
      path.basename = Some(PlatformPath::from(base))
      path.extension = Some(PlatformPath::from(extension))
    }
    WPathBuilder(_) as path => {
      path.basename = Some(PlatformPath::from(base))
      path.extension = Some(PlatformPath::from(extension))
    }
  }
}

///|
pub fn PathBuilder::copy(self : PathBuilder) -> PathBuilder {
  match self {
    WPathBuilder(prefix~, directory~, basename~, extension~) =>
      WPathBuilder(prefix~, directory=directory.copy(), basename~, extension~)
    UPathBuilder(prefix~, directory~, basename~, extension~) =>
      UPathBuilder(prefix~, directory=directory.copy(), basename~, extension~)
  }
}
