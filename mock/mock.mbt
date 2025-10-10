///|
struct Directory(String)

///|
#borrow(template)
extern "c" fn fs_mkdtemp(template : Bytes) -> Int = "moonbit_maria_fs_mkdtemp"

///|
#callsite(autofill(loc))
pub async fn directory(name : String, loc~ : SourceLoc) -> Directory {
  let cwd = @os.cwd() catch {
    error => {
      println(
        "[ERROR] \{loc}: failed to get current working directory: \{error}",
      )
      raise error
    }
  }
  let template = "maria-mock-\{name}-XXXXXX"
  let dot_tmp = @path.join(cwd, ".tmp")
  if !(@fs.exists(dot_tmp) catch {
      error => {
        println("[ERROR] \{loc}: failed to check existence of .tmp: \{error}")
        raise error
      }
    }) {
    @fs.mkdir(dot_tmp, permission=0o755) catch {
      error => println("[ERROR] \{loc}: failed to create .tmp: \{error}")
    }
  }
  let template = @encoding/utf8.encode(@path.join(dot_tmp, template))
  let errno = fs_mkdtemp(template)
  if errno != 0 {
    let error = @errno.Errno(errno)
    println("[ERROR] \{loc}: failed to create temporary directory: \{error}")
    raise error
  }
  return Directory(@encoding/utf8.decode(template))
}

///|
#callsite(autofill(loc))
async fn make_directory(path : StringView, loc~ : SourceLoc) -> Unit {
  let path = path.to_string()
  if !(@fs.exists(path) catch {
      error => {
        println(
          "[ERROR] \{loc}: failed to check existence of directory: \{error}",
        )
        raise error
      }
    }) {
    let parent = @path.dirname(path).to_string()
    make_directory(parent) catch {
      error => {
        println("[ERROR] \{loc}: failed to create parent directory: \{error}")
        raise error
      }
    }
    @fs.mkdir(path, permission=0o755) catch {
      error => {
        println("[ERROR] \{loc}: failed to create directory: \{error}")
        raise error
      }
    }
  }
}

///|
#callsite(autofill(loc))
async fn remove_directory(path : String, loc~ : SourceLoc) -> Unit {
  @fs.rmdir(path, recursive=true) catch {
    error =>
      println("[ERROR] \{loc}: failed to remove directory \{path}: \{error}")
  }
}

///|
#callsite(autofill(loc))
pub async fn Directory::close(self : Directory, loc~ : SourceLoc) -> Unit {
  remove_directory(self.0) catch {
    error => {
      println(
        "[ERROR] \{loc}: failed to remove temporary directory: \{self.path()}: \{error}",
      )
      raise error
    }
  }
}

///|
pub fn Directory::path(self : Directory) -> String {
  self.0
}

///|
struct File(String)

///|
pub fn File::path(self : File) -> String {
  self.0
}

///|
#callsite(autofill(loc))
pub async fn Directory::add_file(
  self : Directory,
  name : String,
  content : String,
  loc~ : SourceLoc,
) -> File {
  let name = @path.join(self.0, name)
  let dir = @path.dirname(name)
  make_directory(dir) catch {
    error => {
      println(
        "[ERROR] \{loc}: failed to create parent directory \{dir}: \{error}",
      )
      raise error
    }
  }
  let file = @fs.open(name, mode=WriteOnly, create=0o644) catch {
    error => {
      println("[ERROR] \{loc}: failed to create file \{(name)}: \{error}")
      raise error
    }
  }
  defer file.close()
  file.write(content) catch {
    error => {
      println("[ERROR] \{loc}: failed to write to file \{(name)}: \{error}")
      raise error
    }
  }
  name
}

///|
#callsite(autofill(loc))
pub async fn Directory::add_subdirectory(
  self : Directory,
  name : String,
  loc~ : SourceLoc,
) -> Directory {
  let dir = @path.join(self.0, name)
  @fs.mkdir(dir, permission=0o755) catch {
    error => {
      println("[ERROR] \{loc}: failed to create subdirectory \{dir}: \{error}")
      raise error
    }
  }
  Directory(dir)
}

///|
#callsite(autofill(loc))
pub async fn Directory::with_subdirectory(
  self : Directory,
  name : String,
  f : async (Directory) -> Unit,
  loc~ : SourceLoc,
) -> Unit {
  let dir = @path.join(self.0, name)
  @fs.mkdir(dir, permission=0o755) catch {
    error => {
      println("[ERROR] \{loc}: failed to create subdirectory \{dir}: \{error}")
      raise error
    }
  }
  f(Directory(dir))
}

///|
#callsite(autofill(loc))
pub async fn Directory::list(
  self : Directory,
  loc~ : SourceLoc,
) -> Array[String] {
  let dir = @fs.opendir(self.0) catch {
    error => {
      println("[ERROR] \{loc}: failed to open directory \{self.0}: \{error}")
      raise error
    }
  }
  let entries = []
  for
    basename in (dir.read_all() catch {
      error => {
        println("[ERROR] \{loc}: failed to read directory \{self.0}: \{error}")
        raise error
      }
    }) {
    let filename = @path.join(self.0, basename)
    let file = @fs.open(filename, mode=ReadOnly) catch {
      error => {
        println("[ERROR] \{loc}: failed to open file \{filename}: \{error}")
        raise error
      }
    }
    defer file.close()
    let basename : String = match file.kind() {
      Directory => [..basename, @path.sep]
      _ => basename
    }
    entries.push(basename)
  }
  entries.sort()
  return entries
}

///|
pub fn[T : ToJson] Directory::strip_cwd(self : Directory, value : T) -> Json {
  let cwd = self.path()
  let json = value.to_json()
  fn strip_cwd_from_json(json : Json, cwd : String) -> Json {
    match json {
      String(string) => Json::string(string.replace(old=cwd, new="."))
      Array(array) => Json::array(array.map(e => strip_cwd_from_json(e, cwd)))
      Object(old_object) => {
        let new_object = {}
        for k, v in old_object {
          new_object[k.replace(old=cwd, new=".")] = strip_cwd_from_json(v, cwd)
        }
        Json::object(new_object)
      }
      _ => json
    }
  }

  strip_cwd_from_json(json, cwd)
}

///|
pub fn model() -> @model.Model {
  @model.new(
    api_key="",
    name="mock",
    base_url="mock:model",
    context_window=8192,
  )
}

///|
#callsite(autofill(loc))
pub async fn with_temporary_directory(
  name~ : String,
  f : async (Directory) -> Unit,
  loc~ : SourceLoc,
) -> Unit {
  let dir = directory(name) catch {
    error => {
      println("[ERROR] \{loc}: failed to create temporary directory: \{error}")
      raise error
    }
  }
  f(dir) catch {
    error => {
      dir.close() catch {
        err =>
          println(
            "[ERROR] \{loc}: failed to remove temporary directory: \{dir.path()}: \{err}",
          )
      }
      raise error
    }
  }
  dir.close() catch {
    error => {
      println(
        "[ERROR] \{loc}: failed to remove temporary directory: \{dir.path()}: \{error}",
      )
      raise error
    }
  }
}

///|
pub fn[T : ToJson] strip_uuid(value : T) -> Json {
  match value.to_json() {
    Object(object_) =>
      object_
      .map((key, value) => if key is ("id" | "uuid") &&
        value is String(value) &&
        (try? @uuid.parse(value)) is Ok(_) {
        String("...")
      } else {
        strip_uuid(value)
      })
      .to_json()
    Array(array) => Json::array(array.map(item => strip_uuid(item)))
    other => other
  }
}

///|
pub fn[T : ToJson] strip_timestamp(value : T) -> Json {
  match value.to_json() {
    Object(object_) =>
      object_
      .map((key, value) => if key is ("created_at" | "updated_at" | "timestamp") &&
        (value is String(_) || value is Number(_)) {
        String("...")
      } else {
        strip_timestamp(value)
      })
      .to_json()
    Array(array) => Json::array(array.map(item => strip_timestamp(item)))
    other => other
  }
}
