///|
trait IsString {
  to_string(Self) -> String
}

///|
pub impl IsString for StringView with to_string(self) = "%identity"

///|
pub impl IsString for String with to_string(self) = "%identity"

///|
pub impl IsString for WinPathComponent with to_string(self) = "%identity"

///|
pub impl IsString for UnixPathComponent with to_string(self) = "%identity"

///|
pub impl[A : IsString] Show for Directory[A] with output(self, logger) {
  for component in self {
    logger.write_string(component.to_string())
    logger.write_char('/')
  }
}

///|
pub impl Show for WinPathComponent with output(self, logger) {
  logger.write_string(self.0)
}

///|
pub impl Show for WinPathComponent with to_string(self) = "%identity"

///|
pub impl Show for UnixPathComponent with output(self, logger) {
  logger.write_string(self.0)
}

///|
pub impl Show for UnixPathComponent with to_string(self) = "%identity"

///|
pub impl[A : IsString] Show for File[A] with output(self, logger) {
  logger.write_string(self.base.to_string())
  if self.extension is Some(ext) {
    logger.write_char('.')
    logger.write_string(ext.to_string())
  }
}

///|
const VerbatimPrefix : String =
  #|\\?\

///|
const VerbatimUncPrefix : String =
  #|\\?\UNC\

///|
const ColonBackslash : String =
  #|:\

///|
const VolumePrefix : String =
  #|\\?\Volume{

///|
const VolumeSuffix : String =
  #|}

///|
const DevicePrefix : String =
  #|\\.\

///|
const UncPrefix : String =
  #|\\

///|
const BackSlash : Char = '\\'

///|
pub impl Show for WinPrefix with output(self, logger) {
  match self {
    Root => logger.write_char(BackSlash)
    VerbatimSymlink(symlink~) => {
      logger.write_string(VerbatimPrefix)
      logger.write_string(symlink)
      logger.write_char(BackSlash)
    }
    VerbatimUNC(hostname~, shared_folder~) => {
      logger.write_string(VerbatimUncPrefix)
      logger.write_string(hostname)
      logger.write_char(BackSlash)
      logger.write_string(shared_folder)
      logger.write_char(BackSlash)
    }
    VerbatimVolumeLetter(letter) => {
      logger.write_string(VerbatimPrefix)
      logger.write_char(letter)
      logger.write_string(ColonBackslash)
    }
    VerbatimVolumeGUID(guid) => {
      logger.write_string(VolumePrefix)
      logger.write_string(guid)
      logger.write_string(VolumeSuffix)
    }
    DeviceNS(device~) => {
      logger.write_string(DevicePrefix)
      logger.write_string(device)
      logger.write_char(BackSlash)
    }
    UNC(hostname~, shared_folder~) => {
      logger.write_string(UncPrefix)
      logger.write_string(hostname)
      logger.write_char(BackSlash)
      logger.write_string(shared_folder)
      logger.write_char(BackSlash)
    }
    VolumeLetter(letter) => {
      logger.write_char(letter)
      logger.write_string(ColonBackslash)
    }
    None => ()
  }
}

///|
pub fn WinPath::output(
  self : WinPath,
  logger : &Logger,
  kind? : PathKind = Directory,
) -> Unit {
  let { prefix, directory, file } = self
  logger.write_object(prefix)
  match (file, kind) {
    (Some(file), _) => {
      for component in directory {
        logger.write_object(component)
        logger.write_char(BackSlash)
      }
      logger.write_object(file)
    }
    (None, Directory) =>
      for component in directory {
        logger.write_object(component)
        logger.write_char(BackSlash)
      }
    // output directory without tailing backslash
    (None, File) =>
      match directory[:] {
        [] => ()
        [x, .. xs] => {
          logger.write_object(x)
          for x in xs {
            logger.write_char(BackSlash)
            logger.write_object(x)
          }
        }
      }
  }
}

///|
pub impl Show for WinPath with output(self, logger) {
  WinPath::output(self, logger)
}

///|
const Slash = '/'

///|
pub fn UnixPath::output(
  self : UnixPath,
  logger : &Logger,
  kind? : PathKind = Directory,
) -> Unit {
  let { prefix, directory, file } = self
  match prefix {
    Root => logger.write_char(Slash)
    SlashSlash => logger.write_string("//")
    None => ()
  }
  match (file, kind) {
    (Some(file), _) => {
      for component in directory {
        logger.write_object(component)
        logger.write_char(Slash)
      }
      logger.write_object(file)
    }
    (None, Directory) =>
      for component in directory {
        logger.write_object(component)
        logger.write_char(Slash)
      }
    // output directory without tailing slash
    (None, File) =>
      match directory[:] {
        [] => ()
        [x, .. xs] => {
          logger.write_object(x)
          for x in xs {
            logger.write_char(Slash)
            logger.write_object(x)
          }
        }
      }
  }
}

///|
pub impl Show for UnixPath with output(self, logger) {
  UnixPath::output(self, logger)
}

///|
pub fn Path::output(
  self : Path,
  logger : &Logger,
  kind? : PathKind = Directory,
) -> Unit {
  match self {
    UPath(path) => UnixPath::output(path, logger, kind~)
    WPath(path) => WinPath::output(path, logger, kind~)
  }
}

///|
pub impl Show for Path with output(self, logger) {
  match self {
    UPath(path) => logger.write_object(path)
    WPath(path) => logger.write_object(path)
  }
}

///|
pub fn PathBuilder::output(
  self : PathBuilder,
  logger : &Logger,
  kind? : PathKind = Directory,
) -> Unit {
  match self {
    UPathBuilder(prefix~, directory~, basename~, extension~) => {
      match prefix {
        Root => logger.write_char(Slash)
        SlashSlash => logger.write_string("//")
        None => ()
      }
      match (basename, kind) {
        (Some(basename), _) => {
          for component in directory {
            logger.write_object(component)
            logger.write_char(Slash)
          }
          logger.write_object(basename)
          if extension is Some(ext) {
            logger.write_string(".")
            logger.write_object(ext)
          }
        }
        (None, Directory) =>
          for component in directory {
            logger.write_object(component)
            logger.write_char(Slash)
          }
        // output directory without tailing slash
        (None, File) =>
          match directory[:] {
            [] => ()
            [x, .. xs] => {
              logger.write_object(x)
              for x in xs {
                logger.write_char(Slash)
                logger.write_object(x)
              }
            }
          }
      }
    }
    WPathBuilder(prefix~, directory~, basename~, extension~) => {
      logger.write_object(prefix)
      match (basename, kind) {
        (Some(basename), _) => {
          for component in directory {
            logger.write_object(component)
            logger.write_char(BackSlash)
          }
          logger.write_object(basename)
          if extension is Some(ext) {
            logger.write_string(".")
            logger.write_object(ext)
          }
        }
        (None, Directory) =>
          for component in directory {
            logger.write_object(component)
            logger.write_char(BackSlash)
          }
        // output directory without tailing backslash
        (None, File) =>
          match directory[:] {
            [] => ()
            [x, .. xs] => {
              logger.write_object(x)
              for x in xs {
                logger.write_char(BackSlash)
                logger.write_object(x)
              }
            }
          }
      }
    }
  }
}

///|
pub impl Show for PathBuilder with output(self, logger) {
  PathBuilder::output(self, logger)
}

///|
pub fn Path::to_string(self : Path, kind? : PathKind = Directory) -> String {
  let logger = StringBuilder::new()
  Path::output(self, logger, kind~)
  logger.to_string()
}

///|
pub fn WinPath::to_string(
  self : WinPath,
  kind? : PathKind = Directory,
) -> String {
  let logger = StringBuilder::new()
  WinPath::output(self, logger, kind~)
  logger.to_string()
}

///|
pub fn UnixPath::to_string(
  self : UnixPath,
  kind? : PathKind = Directory,
) -> String {
  let logger = StringBuilder::new()
  UnixPath::output(self, logger, kind~)
  logger.to_string()
}

///|
pub fn PathBuilder::to_string(
  self : PathBuilder,
  kind? : PathKind = Directory,
) -> String {
  let logger = StringBuilder::new()
  PathBuilder::output(self, logger, kind~)
  logger.to_string()
}

///|
test "unix path" {
  let path = UnixPath::new(directory=Directory::new(["username", ".moon"]))
  inspect(path, content="username/.moon/")
  let path = UnixPath::new(
    prefix=Root,
    directory=Directory::new(["home", "username", ".moon"]),
  )
  inspect(path, content="/home/username/.moon/")
  let path = UnixPath::new(directory=Directory::new([]))
  inspect(path, content="")
  let path = UnixPath::new(prefix=Root, directory=Directory::new([]))
  inspect(path, content="/")
}

///|
test "windows path" {
  let path = WinPath::new(
    prefix=VolumeLetter('C'),
    directory=Directory::new(["Users", "username", "Documents"]),
    file=File::new(base="file", extension="txt"),
  )
  inspect(path, content="C:\\Users\\username\\Documents\\file.txt")
  let path = WinPath::new(directory=Directory::new(["develop", "my_project"]))
  inspect(path, content="develop\\my_project\\")
  let path = WinPath::new(
    directory=Directory::new(["develop", "my_project"]),
    file=File::new(base="readme", extension="md"),
  )
  inspect(path, content="develop\\my_project\\readme.md")
  let path = WinPath::new(
    prefix=UNC(hostname="server", shared_folder="share"),
    directory=Directory::new(["folder"]),
  )
  inspect(path, content="\\\\server\\share\\folder\\")
  let path = WinPath::new(
    prefix=VerbatimUNC(hostname="server", shared_folder="share"),
    directory=Directory::new(["folder"]),
  )
  inspect(path, content="\\\\?\\UNC\\server\\share\\folder\\")
  let path = WinPath::new(
    prefix=VerbatimVolumeLetter('D'),
    directory=Directory::new(["Pictures"]),
    file=File::new(base="apple", extension="png"),
  )
  inspect(path, content="\\\\?\\D:\\Pictures\\apple.png")
  let path = WinPath::new(
    prefix=VerbatimVolumeGUID("12345678-1234-1234-1234-1234567890AB"),
    directory=Directory::new(["folder"]),
  )
  inspect(
    path,
    content="\\\\?\\Volume{12345678-1234-1234-1234-1234567890AB}folder\\",
  )
  let path = WinPath::new(
    prefix=DeviceNS(device="COM56"),
    directory=Directory::new(["folder"]),
  )
  inspect(path, content="\\\\.\\COM56\\folder\\")
}

///|
test "to_string specify File format" {
  let path = Path::parse("./a/b/")
  inspect(path, content="a/b/")
  inspect(path.to_string(kind=File), content="a/b")
  let path = Path::parse("C:\\a\\b\\")
  inspect(path, content="C:\\a\\b\\")
  inspect(path.to_string(kind=File), content="C:\\a\\b")
}
