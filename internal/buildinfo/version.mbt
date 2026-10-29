///|
pub struct Version {
  major : Int32
  minor : Int32
  patch : Int32
  build : Build?
} derive(ToJson)

///|
pub impl Show for Version with fn output(self : Version, logger : &Logger) -> Unit {
  let string = if self.build is Some(build) {
    "\{self.major}.\{self.minor}.\{self.patch}+\{build.number}.\{build.commit}"
  } else {
    "\{self.major}.\{self.minor}.\{self.patch}"
  }
  logger.write_string(string)
}

///|
pub struct Build {
  number : Int32
  commit : String
} derive(ToJson)

///|
pub let version : Version = try! Version::parse(version_string)

///|
pub fn Version::parse(string : String) -> Version raise {
  lexmatch string with longest {
    (re"^[[:digit:]]+" as major) +
    re"\." +
    (re"([[:digit:]]+)" as minor) +
    re"\." +
    (re"([[:digit:]]+)" as patch) +
    re"$" => {
      let major = @string.parse_int(major)
      let minor = @string.parse_int(minor)
      let patch = @string.parse_int(patch)
      Version::{ major, minor, patch, build: None, }
    }
    (re"^[[:digit:]]+" as major) +
    re"\." +
    (re"([[:digit:]]+)" as minor) +
    re"\." +
    (re"([[:digit:]]+)" as patch) +
    re"\+" +
    (re"([0-9]+)" as build_number) +
    re"\." +
    (re"([0-9a-fA-F]+)" as commit) +
    re"$" => {
      let major = @string.parse_int(major)
      let minor = @string.parse_int(minor)
      let patch = @string.parse_int(patch)
      let build_number = @string.parse_int(build_number)
      Version::{
        major,
        minor,
        patch,
        build: Some({ number: build_number, commit: commit.to_owned(), }),
      }
    }
    _ => fail("Invalid version string format: " + string)
  }
}

///|
pub impl Compare for Version with fn compare(self, other) -> Int32 {
  if self.major != other.major {
    return self.major.compare(other.major)
  }
  if self.minor != other.minor {
    return self.minor.compare(other.minor)
  }
  if self.patch != other.patch {
    return self.patch.compare(other.patch)
  }
  match (self.build, other.build) {
    (None, None) => 0
    (Some(_), None) => 1
    (None, Some(_)) => -1
    (Some(b1), Some(b2)) => return b1.number.compare(b2.number)
  }
}

///|
pub impl Eq for Version with fn equal(self, other) -> Bool {
  self.major == other.major &&
  self.minor == other.minor &&
  self.patch == other.patch &&
  (match (self.build, other.build) {
    (None, None) => true
    (Some(b1), Some(b2)) => b1.number == b2.number
    _ => false
  })
}

///|
pub extend Version with ToJson::{to_json}

///|
pub extend Version with Show::{to_string, output}

///|
pub extend Build with ToJson::{to_json}

///|
pub extend Version with Compare::{op_lt, op_le, op_ge, compare, op_gt}

///|
pub extend Version with Eq::{not_equal, equal}
