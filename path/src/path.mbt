///|
fn parse_windows_relative_path(
  s : StringView,
  start~ : Int,
  root_eliminate~ : Bool,
  kind~ : PathKind,
) -> (WinDirectory, WinFile?) raise PathError {
  let mut rest = s
  let directory : Array[WinPathComponent] = []
  let mut start = start
  let file : WinFile? = for {
    lexmatch rest with longest {
      // pattern: <path_component><backslashes>
      // backslashes elimination
      ((("[^\\]+" as s) "(\\)+") as all, r) => {
        match s {
          "." => ()
          ".." =>
            match (directory.pop(), root_eliminate) {
              (Some(WinPathComponent("..")), _) => {
                directory.push(WinPathComponent(".."))
                directory.push(WinPathComponent(".."))
              }
              (None, true) => ()
              (None, false) => directory.push(WinPathComponent(".."))
              (Some(_), _) => ()
            }
          _ => directory.push(WinPathComponent::from(s, start~))
        }
        start += all.char_length()
        rest = r
      }
      // pattern: <dot-dot>
      "\.\." => {
        match (directory.pop(), root_eliminate) {
          (Some(WinPathComponent("..")), _) => {
            directory.push(WinPathComponent(".."))
            directory.push(WinPathComponent(".."))
          }
          (None, true) => ()
          (None, false) => directory.push(WinPathComponent(".."))
          (Some(_), _) => ()
        }
        break None
      }
      // pattern: <dot>
      "\." => break None
      ((("\.?[^\\]+" as base) "\." ("[^.\\]+" as extension)) as filename) =>
        match kind {
          File => break Some(WinFile::new(base~, extension~))
          Directory => {
            directory.push(WinPathComponent::from(filename, start~))
            break None
          }
        }
      ("\.?[^\\.]+" as base) =>
        match kind {
          File => break Some(WinFile::new(base~))
          Directory => {
            directory.push(WinPathComponent::from(base, start~))
            break None
          }
        }
      "$" => break None
      _ => raise PathError(start~, message="Invalid Windows path")
    }
  }
  (Directory(FixedArray::from_array(directory)), file)
}

///|
fn parse_unix_relative_path(
  s : StringView,
  start~ : Int,
  root_eliminate~ : Bool,
  kind~ : PathKind,
) -> (UnixDirectory, UnixFile?) raise PathError {
  let mut rest = s
  let directory : Array[UnixPathComponent] = []
  let mut start = start
  let file : UnixFile? = for {
    lexmatch rest with longest {
      // pattern: <path_component><slashes>
      // slashes elimination
      ((("[^/]+" as s) "(/)+") as all, r) => {
        match s {
          "." => ()
          ".." =>
            match (directory.pop(), root_eliminate) {
              (Some(UnixPathComponent("..")), _) => {
                directory.push(UnixPathComponent(".."))
                directory.push(UnixPathComponent(".."))
              }
              (None, true) => ()
              (None, false) => directory.push(UnixPathComponent(".."))
              (Some(_), _) => ()
            }
          _ => directory.push(UnixPathComponent::from(s, start~))
        }
        start += all.char_length()
        rest = r
      }
      // pattern: <dot-dot>
      "\.\." => {
        match (directory.pop(), root_eliminate) {
          (Some(UnixPathComponent("..")), _) => {
            directory.push(UnixPathComponent(".."))
            directory.push(UnixPathComponent(".."))
          }
          (None, true) => ()
          (None, false) => directory.push(UnixPathComponent(".."))
          (Some(_), _) => ()
        }
        break None
      }
      // pattern: <dot>
      "\." => break None
      (("\.?[^/]+" as base) "\." ("[^/]+" as extension)) =>
        match kind {
          File => break Some(UnixFile::new(base~, extension~))
          Directory => {
            directory.push(
              UnixPathComponent::from(base + "." + extension, start~),
            )
            break None
          }
        }
      ("\.?[^/.]+" as base) =>
        match kind {
          File => break Some(UnixFile::new(base~))
          Directory => {
            directory.push(UnixPathComponent::from(base, start~))
            break None
          }
        }
      "$" => break None
      _ => raise PathError(start~, message="Invalid Unix path")
    }
  }
  (Directory(FixedArray::from_array(directory)), file)
}

///|
fn win_path(
  prefix? : WinPrefix = None,
  directory? : WinDirectory = [],
  file? : WinFile,
) -> Path {
  WPath(WinPath::{ prefix, directory, file })
}

///|
/// Parsing path from string used prefix based detection to determine the path format style (Windows/Unix)
pub fn Path::parse(
  path : StringView,
  kind? : PathKind = File,
  style? : PathStyle = Unknown,
) -> Path raise PathError {
  lexmatch path with longest {
    //-----------------------------------------------------------------------------
    // without <rest_of_path>
    //-----------------------------------------------------------------------------
    // this pattern exect match the whole path string
    // pattern: `\\?\<symlink>`
    ("\\\\\?\\" ("[^\\]+" as symlink)) =>
      win_path(prefix=VerbatimSymlink(symlink=symlink.to_string()))
    // this pattern exect match the whole path string
    // pattern: `\\?\UNC\<hostname>\<shared_folder>`
    ("\\\\\?UNC\\" ("[^\\]+" as hostname) "\\" ("[^\\]+" as shared_folder)) =>
      win_path(
        prefix=VerbatimUNC(
          hostname=hostname.to_string(),
          shared_folder=shared_folder.to_string(),
        ),
      )
    // this pattern exect match the whole path string
    // pattern: `\\<hostname>\<shared_folder>`
    ("\\\\" ("[^\\]+" as hostname) "\\" ("[^\\]+" as shared_folder)) =>
      win_path(
        prefix=UNC(
          hostname=hostname.to_string(),
          shared_folder=shared_folder.to_string(),
        ),
      )
    // this pattern exect match the whole path string
    // pattern: `\\.\<device>`
    ("\\\\\.\\" ("[^\\]+" as device)) =>
      win_path(prefix=DeviceNS(device=device.to_string()))
    // this pattern exect match the whole path string
    // pattern: `\\?\<letter>:\`
    //
    // backslashes elimination
    ("\\\\\?\\" ("[a-zA-Z]" as letter) ":(\\)+") =>
      win_path(prefix=VerbatimVolumeLetter(letter))
    // this pattern exect match the whole path string
    // pattern: `<letter>:\`
    // 
    // backslashes elimination
    (("[a-zA-Z]" as letter) ":(\\)+") => win_path(prefix=VolumeLetter(letter))
    // this pattern exect match the whole path string
    // pattern: `\\?\` followed by relative path components
    ("\\\\\?\\" "\\|\.\.|\.") =>
      raise PathError(
        start=0,
        message="Invalid Windows path: Verbatim prefix can use for relative path",
      )
    // this pattern exect match the whole path string
    // pattern: `\\?\Volume{<guid>}`
    ("\\\\\?\\Volume[{]" ("[^}]+" as guid) "[}]") =>
      win_path(prefix=VerbatimVolumeGUID(guid.to_string()))
    //-----------------------------------------------------------------------------
    // with <rest_of_path>
    //-----------------------------------------------------------------------------
    // pattern: `\\?\<symlink>\<rest_of_path>`
    //
    // backslashes elimination
    (("\\\\\?\\" ("[^\\]+" as symlink) "(\\)+") as prefix, rest) => {
      // Warning: won't check the symlink name here
      let (directory, file) = parse_windows_relative_path(
        rest,
        start=prefix.char_length(),
        root_eliminate=true,
        kind~,
      )
      win_path(
        prefix=VerbatimSymlink(symlink=symlink.to_string()),
        directory~,
        file?,
      )
    }
    // pattern: `\\?\UNC\<hostname>\<shared_folder>\<rest_of_path>`
    //
    // backslashes elimination
    (
      (
        "\\\\\?UNC\\"
        ("[^\\]+" as hostname)
        "\\"
        ("[^\\]+" as shared_folder)
        "(\\)+"
      ) as prefix,
      rest
    ) => {
      // Warning: won't check the hostname and shared_folder here
      let (directory, file) = parse_windows_relative_path(
        rest,
        start=prefix.char_length(),
        root_eliminate=true,
        kind~,
      )
      win_path(
        prefix=VerbatimUNC(
          hostname=hostname.to_string(),
          shared_folder=shared_folder.to_string(),
        ),
        directory~,
        file?,
      )
    }
    // pattern: `\\<hostname>\<shared_folder>\<rest_of_path>`
    //
    // backslashes elimination
    (
      ("\\\\" ("[^\\]+" as hostname) "\\" ("[^\\]+" as shared_folder) "(\\)+") as prefix,
      rest
    ) => {
      // Warning: won't check the hostname and shared_folder here
      let (directory, file) = parse_windows_relative_path(
        rest,
        start=prefix.char_length(),
        root_eliminate=true,
        kind~,
      )
      win_path(
        prefix=UNC(
          hostname=hostname.to_string(),
          shared_folder=shared_folder.to_string(),
        ),
        directory~,
        file?,
      )
    }
    // pattern: `\\?\Volume{<guid>}<rest_of_path>`
    (("\\\\\?\\Volume[{]" ("[^}]+" as guid) "[}]") as prefix, rest) => {
      let (directory, file) = parse_windows_relative_path(
        rest,
        start=prefix.char_length(),
        root_eliminate=true,
        kind~,
      )
      win_path(prefix=VerbatimVolumeGUID(guid.to_string()), directory~, file?)
    }
    // pattern: `\\.\<device>\<rest_of_path>`
    //
    // backslashes elimination
    (("\\\\\.\\" ("[^\\]+" as device) "(\\)+") as prefix, rest) => {
      // check the device name here
      let (directory, file) = parse_windows_relative_path(
        rest,
        start=prefix.char_length(),
        root_eliminate=true,
        kind~,
      )
      win_path(prefix=DeviceNS(device=device.to_string()), directory~, file?)
    }
    // pattern: `\\?\<letter>:\<rest_of_path>`
    //
    // backslashes elimination
    (("\\\\\?\\" ("[a-zA-Z]" as letter) ":(\\)+") as prefix, rest) => {
      let (directory, file) = parse_windows_relative_path(
        rest,
        start=prefix.char_length(),
        root_eliminate=true,
        kind~,
      )
      win_path(prefix=VerbatimVolumeLetter(letter), directory~, file?)
    }
    // pattern: `\\?\` followed by relative path components
    ("\\\\\?\\" "\\|\.\.|\.", _) =>
      raise PathError(
        start=0,
        message="Invalid Windows path: Verbatim prefix can use for relative path",
      )
    // pattern: `<letter>:\<rest_of_path>`
    //
    // backslashes elimination
    ((("[a-zA-Z]" as letter) ":(\\)+") as prefix, rest) => {
      let (directory, file) = parse_windows_relative_path(
        rest,
        start=prefix.char_length(),
        root_eliminate=true,
        kind~,
      )
      win_path(prefix=VolumeLetter(letter), directory~, file?)
    }
    // current path 
    // syntax: `.\<rest_of_path>`
    // backslashes elimination
    ("\.(\\)+" as prefix, rest) => {
      let (directory, file) = parse_windows_relative_path(
        rest,
        start=prefix.char_length(),
        root_eliminate=false,
        kind~,
      )
      win_path(directory~, file?)
    }
    // syntax: `<path_component>\<rest_of_path>`
    // backslashes elimination
    ("[^\\]+(\\)+", _) => {
      let (directory, file) = parse_windows_relative_path(
        path,
        start=0,
        root_eliminate=false,
        kind~,
      )
      win_path(directory~, file?)
    }

    // current path
    // syntax: `./<rest_of_path>`
    // slashes elimination 
    ("\./+" as prefix, rest) => {
      let (directory, file) = parse_unix_relative_path(
        rest,
        start=prefix.char_length(),
        root_eliminate=false,
        kind~,
      )
      UPath(UnixPath::new(directory~, file?))
    }
    // syntax: `<path_component>/<rest_of_path>`
    // slashes elimination
    ("[^/]+/+", _) => {
      let (directory, file) = parse_unix_relative_path(
        path,
        start=0,
        root_eliminate=false,
        kind~,
      )
      UPath(UnixPath::new(directory~, file?))
    }

    // root path but without derive letter 
    // syntax: `\<rest_of_path>`
    // Warning: here doesn't support backslash elimination, 
    //          because prefix backslashes elimination is conflicted with UNC path format
    ("\\", rest) => {
      let (directory, file) = parse_windows_relative_path(
        rest,
        start=1,
        root_eliminate=true,
        kind~,
      )
      win_path(prefix=Root, directory~, file?)
    }

    // root path 
    // syntax: `/<rest_of_path>` or `/{3,}<rest_of_path>`
    //
    // slashes elimination
    ("/|/{3,}", rest) => {
      let (directory, file) = parse_unix_relative_path(
        rest,
        start=1,
        root_eliminate=true,
        kind~,
      )
      UPath(UnixPath::new(prefix=Root, directory~, file?))
    }
    // syntax: `//<rest_of_path>
    // 
    ("//", rest) => {
      let (directory, file) = parse_unix_relative_path(
        rest,
        start=1,
        root_eliminate=true,
        kind~,
      )
      UPath(UnixPath::new(prefix=SlashSlash, directory~, file?))
    }
    non_prefix_hint_path =>
      match style {
        Unix => {
          let (directory, file) = parse_unix_relative_path(
            non_prefix_hint_path,
            start=0,
            root_eliminate=false,
            kind~,
          )
          UPath(UnixPath::new(directory~, file?))
        }
        Win => {
          let (directory, file) = parse_windows_relative_path(
            non_prefix_hint_path,
            start=0,
            root_eliminate=false,
            kind~,
          )
          win_path(directory~, file?)
        }
        Unknown => raise PathError(start=0, message="Invalid path format")
      }
  }
}

///|
pub fn[A : PlatformPath] File::new(
  base~ : StringView,
  extension? : StringView,
) -> File[A] raise PathError {
  let ext = if extension is Some(extension) {
    for i, ch in extension {
      guard ch != '.' else {
        raise PathError::PathError(
          start=i,
          message="Invalid file extension at position \{i}: extension '\{extension}' cannot contain '.' character",
        )
      }
    }
    Some(A::from(extension))
  } else {
    None
  }
  let base_component = A::from(base)
  File::{ base: base_component, extension: ext }
}

///|
pub fn[A : PlatformPath] Directory::new(
  components : ArrayView[StringView],
) -> Directory[A] raise PathError {
  let result : Array[A] = []
  for i = 0; i < components.length(); i = i + 1 {
    result.push(A::from(components[i]))
  }
  Directory(FixedArray::from_array(result))
}

///|
fn WinPathComponent::from(
  s : StringView,
  start~ : Int,
) -> WinPathComponent raise PathError {
  guard !s.is_empty() else {
    raise PathError::PathError(
      start~,
      message="Windows path: empty path component not allowed",
    )
  }
  guard !windows_reserved_names_set.contains(s) else {
    raise PathError::PathError(
      start~,
      message="Windows path: '\{s}' is a reserved name (CON, PRN, AUX, NUL, COM1-9, LPT1-9)",
    )
  }
  for i, ch in s {
    guard !is_windows_reserved_character(ch) else {
      raise PathError::PathError(
        start=start + i,
        message="Windows path: character '\{ch}' at position \{start+i} is not allowed (reserved characters: < > : \" / \\ | ? * and control characters)",
      )
    }
    guard ch != '\\' else {
      raise PathError::PathError(
        start=start + i,
        message="Windows path: backslash '\\' at position \{start+i} not allowed in path component",
      )
    }
  }
  WinPathComponent(s.to_string())
}

///|
fn UnixPathComponent::from(
  s : StringView,
  start~ : Int,
) -> UnixPathComponent raise PathError {
  guard !s.is_empty() else {
    raise PathError::PathError(
      start~,
      message="Unix path: empty path component not allowed",
    )
  }
  guard s.get_char(0) != Some('-') else {
    raise PathError::PathError(
      start~,
      message="Unix path: component '\{s}' cannot start with '-' (not portable according to POSIX standard)",
    )
  }
  for i, ch in s {
    guard ch != '/' else {
      raise PathError::PathError(
        start=start + i,
        message="Unix path: forward slash '/' at position \{start + i} not allowed in path component",
      )
    }
    guard ch != '\u0000' else {
      raise PathError::PathError(
        start=start + i,
        message="Unix path: null character (\\u0000) at position \{start + i} not allowed in path component",
      )
    }
  }
  UnixPathComponent(s.to_string())
}

///|
pub impl PlatformPath for UnixPathComponent with from(s) {
  guard !s.is_empty() else {
    raise PathError::PathError(
      start=0,
      message="Unix path: empty path component not allowed",
    )
  }
  guard s.get_char(0) != Some('-') else {
    raise PathError::PathError(
      start=0,
      message="Unix path: component '\{s}' cannot start with '-' (not portable according to POSIX standard)",
    )
  }
  for i, ch in s {
    guard ch != '/' else {
      raise PathError::PathError(
        start=i,
        message="Unix path: forward slash '/' at position \{i} not allowed in path component",
      )
    }
    guard ch != '\u0000' else {
      raise PathError::PathError(
        start=i,
        message="Unix path: null character (\\u0000) at position \{i} not allowed in path component",
      )
    }
  }
  UnixPathComponent(s.to_string())
}

///|
pub fn WinPath::new(
  prefix? : WinPrefix = None,
  directory~ : WinDirectory,
  file? : WinFile,
) -> WinPath {
  WinPath::{ prefix, directory, file }
}

///|
pub fn UnixPath::new(
  prefix? : UnixPrefix = None,
  directory~ : UnixDirectory,
  file? : UnixFile,
) -> UnixPath {
  UnixPath::{ prefix, directory, file }
}

///|
pub fn[T] Directory::op_get(self : Directory[T], index : Int) -> T = "%fixedarray.get"

///|
pub fn[T] Directory::length(self : Directory[T]) -> Int = "%fixedarray.length"

///|
pub fn[T] Directory::iter(self : Directory[T]) -> Iter[T] {
  FixedArray::iter(self.0)
}

///|
#alias("_[_:_]")
pub fn[T] Directory::sub(
  self : Directory[T],
  start? : Int = 0,
  end? : Int = self.length(),
) -> ArrayView[T] {
  FixedArray::sub(self.0, start~, end~)
}

///|
pub fn WinPath::is_absolute(self : WinPath) -> Bool {
  !self.is_relative()
}

///|
pub fn WinPath::is_relative(self : WinPath) -> Bool {
  self.prefix is (Root | None)
}

///|
pub fn WinPath::is_root_path(self : WinPath) -> Bool {
  !(self.prefix is None)
}

///|
pub fn UnixPath::is_absolute(self : UnixPath) -> Bool {
  self.prefix is (Root | SlashSlash)
}

///|
pub fn UnixPath::is_relative(self : UnixPath) -> Bool {
  !self.is_absolute()
}

///|
pub fn UnixPath::is_root_path(self : UnixPath) -> Bool {
  self.prefix is Root
}

///|
pub fn Path::is_absolute(self : Path) -> Bool {
  match self {
    UPath(path) => path.is_absolute()
    WPath(path) => path.is_absolute()
  }
}

///|
pub fn Path::is_relative(self : Path) -> Bool {
  match self {
    UPath(path) => path.is_relative()
    WPath(path) => path.is_relative()
  }
}

///|
pub fn Path::is_root_path(self : Path) -> Bool {
  match self {
    UPath(path) => path.is_root_path()
    WPath(path) => path.is_root_path()
  }
}

///|
pub fn Path::file(self : Path) -> File[String]? {
  match self {
    WPath({ file: Some({ base, extension: Some(ext) }), .. }) =>
      Some(File::{ base: base.0, extension: Some(ext.0) })
    WPath({ file: Some({ base, extension: None }), .. }) =>
      Some(File::{ base: base.0, extension: None })
    UPath({ file: Some({ base, extension: Some(ext) }), .. }) =>
      Some(File::{ base: base.0, extension: Some(ext.0) })
    UPath({ file: Some({ base, extension: None }), .. }) =>
      Some(File::{ base: base.0, extension: None })
    WPath({ file: None, .. }) => None
    UPath({ file: None, .. }) => None
  }
}

///|
pub fn Path::prefix(self : Path) -> String {
  match self {
    WPath({ prefix, .. }) => prefix.to_string()
    UPath({ prefix: Root, .. }) => "/"
    UPath({ prefix: SlashSlash, .. }) => "//"
    UPath({ prefix: None, .. }) => ""
  }
}

///|
pub fn Path::directory(self : Path) -> Directory[String] {
  match self {
    // if compiler can optimize this overhead, we not need use `"%identity"` intrinsic instruction
    WPath({ directory, .. }) => directory.0.map(IsString::to_string)
    UPath({ directory, .. }) => directory.0.map(IsString::to_string)
  }
}

///|
pub fn[A : IsString] File::extension(self : File[A]) -> String? {
  // if compiler can optimize this overhead, we not need use `"%identity"` intrinsic instruction
  self.extension.map(IsString::to_string)
}
