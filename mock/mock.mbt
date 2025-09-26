///|
struct Directory(Bytes)

///|
#callsite(autofill(loc))
pub async fn directory(name : String, loc~ : SourceLoc) -> Directory {
  let cwd = @uv.cwd() catch {
    error => {
      println(
        "[ERROR] \{loc}: failed to get current working directory: \{@encoding/utf8.decode_lossy(error.to_bytes())}",
      )
      raise error
    }
  }
  let template = @encoding/utf8.encode("maria-mock-\{name}-XXXXXX")
  let dot_tmp = @path.join(cwd, ".tmp")
  if !(@fs.exists(dot_tmp) catch {
      error => {
        println("[ERROR] \{loc}: failed to check existence of .tmp: \{error}")
        raise error
      }
    }) {
    @fs.mkdir(dot_tmp, permission=0o755) catch {
      error => {
        println("[ERROR] \{loc}: failed to create .tmp: \{error}")
        raise error
      }
    }
  }
  let tmpdir = @global.uv().fs_mkdtemp_sync(@path.join(dot_tmp, template)) catch {
    error => {
      println(
        "[ERROR] \{loc}: failed to create temporary directory: \{@encoding/utf8.decode_lossy(error.to_bytes())}",
      )
      raise error
    }
  }
  return Directory(tmpdir)
}

///|
#callsite(autofill(loc))
async fn make_directory(path : Bytes, loc~ : SourceLoc) -> Unit {
  if !(@fs.exists(path) catch {
      error => {
        println(
          "[ERROR] \{loc}: failed to check existence of directory: \{error}",
        )
        raise error
      }
    }) {
    let parent = @path.dirname(path).to_bytes()
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
async fn remove_directory(path : Bytes, loc~ : SourceLoc) -> Unit {
  let dir = @fs.opendir(path) catch {
    error => {
      println(
        "[ERROR] \{loc}: failed to open directory \{@encoding/utf8.decode_lossy(path)}: \{error}",
      )
      raise error
    }
  }
  defer dir.close()
  for
    entry in (dir.read_all() catch {
      error => {
        println(
          "[ERROR] \{loc}: failed to read directory \{@encoding/utf8.decode_lossy(path)}: \{error}",
        )
        raise error
      }
    }) {
    let entry = @path.join(path, entry)
    match
      (@fs.kind(entry) catch {
        error => {
          println(
            "[ERROR] \{loc}: failed to get file kind of \{@encoding/utf8.decode_lossy(entry)}: \{error}",
          )
          raise error
        }
      }) {
      Directory =>
        remove_directory(entry) catch {
          error => {
            println(
              "[ERROR] \{loc}: failed to remove subdirectory \{@encoding/utf8.decode_lossy(entry)}: \{error}",
            )
            raise error
          }
        }
      _ =>
        @fs.remove(entry) catch {
          error => {
            println(
              "[ERROR] \{loc}: failed to remove file \{@encoding/utf8.decode_lossy(entry)}: \{error}",
            )
            raise error
          }
        }
    }
  }
  @fs.rmdir(path) catch {
    error => {
      println(
        "[ERROR] \{loc}: failed to remove directory \{@encoding/utf8.decode_lossy(path)}: \{error}",
      )
      raise error
    }
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
pub fn Directory::path(self : Directory) -> String raise {
  @encoding/utf8.decode(self.0)
}

///|
struct File(Bytes)

///|
pub fn File::path(self : File) -> String raise {
  @encoding/utf8.decode(self.0)
}

///|
#callsite(autofill(loc))
pub async fn Directory::add_file(
  self : Directory,
  name : String,
  content : String,
  loc~ : SourceLoc,
) -> File {
  let name = @encoding/utf8.encode(name)
  let name = @path.join(self.0, name)
  let dir = @path.dirname(name)
  make_directory(dir.to_bytes()) catch {
    error => {
      println(
        "[ERROR] \{loc}: failed to create parent directory \{@encoding/utf8.decode_lossy(dir)}: \{error}",
      )
      raise error
    }
  }
  let file = @fs.open(name, mode=WriteOnly, create=0o644) catch {
    error => {
      println(
        "[ERROR] \{loc}: failed to create file \{@encoding/utf8.decode_lossy(name)}: \{error}",
      )
      raise error
    }
  }
  defer file.close()
  file.write(@encoding/utf8.encode(content)) catch {
    error => {
      println(
        "[ERROR] \{loc}: failed to write to file \{@encoding/utf8.decode_lossy(name)}: \{error}",
      )
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
  let name = @encoding/utf8.encode(name)
  let dir = @path.join(self.0, name)
  @fs.mkdir(dir, permission=0o755) catch {
    error => {
      println(
        "[ERROR] \{loc}: failed to create subdirectory \{@encoding/utf8.decode_lossy(dir)}: \{error}",
      )
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
  let name = @encoding/utf8.encode(name)
  let dir = @path.join(self.0, name)
  @fs.mkdir(dir, permission=0o755) catch {
    error => {
      println(
        "[ERROR] \{loc}: failed to create subdirectory \{@encoding/utf8.decode_lossy(dir)}: \{error}",
      )
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
      println(
        "[ERROR] \{loc}: failed to open directory \{@encoding/utf8.decode_lossy(self.0)}: \{error}",
      )
      raise error
    }
  }
  let entries = []
  for
    basename in (dir.read_all() catch {
      error => {
        println(
          "[ERROR] \{loc}: failed to read directory \{@encoding/utf8.decode_lossy(self.0)}: \{error}",
        )
        raise error
      }
    }) {
    let filename = @path.join(self.0, basename)
    let file = @fs.open(filename, mode=ReadOnly) catch {
      error => {
        println(
          "[ERROR] \{loc}: failed to open file \{@encoding/utf8.decode_lossy(filename)}: \{error}",
        )
        raise error
      }
    }
    defer file.close()
    let basename : Bytes = match file.kind() {
      Directory => [..basename, @path.sep]
      _ => basename
    }
    entries.push(@encoding/utf8.decode(basename))
  }
  entries.sort()
  return entries
}

///|
pub fn[T : ToJson] Directory::strip_cwd(
  self : Directory,
  value : T,
) -> Json raise {
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
