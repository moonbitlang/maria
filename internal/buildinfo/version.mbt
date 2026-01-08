///|
pub struct Version {
  major : Int
  minor : Int
  patch : Int
  build : Build?
} derive(ToJson)

///|
pub impl Show for Version with output(self : Version, logger : &Logger) -> Unit {
  let string = if self.build is Some(build) {
    "\{self.major}.\{self.minor}.\{self.patch}+\{build.number}.\{build.commit}"
  } else {
    "\{self.major}.\{self.minor}.\{self.patch}"
  }
  logger.write_string(string)
}

///|
pub struct Build {
  number : Int
  commit : String
} derive(ToJson)

///|
pub let version : Version = try! Version::parse(version_string)

///|
pub fn Version::parse(string : String) -> Version raise {
  lexmatch string {
    (
      ("[[:digit:]]+" as major)
      "\."
      ("([[:digit:]]+)" as minor)
      "\."
      ("([[:digit:]]+)" as patch)
    ) => {
      let major = @strconv.parse_int(major)
      let minor = @strconv.parse_int(minor)
      let patch = @strconv.parse_int(patch)
      Version::{ major, minor, patch, build: None }
    }
    (
      ("[[:digit:]]+" as major)
      "\."
      ("([[:digit:]]+)" as minor)
      "\."
      ("([[:digit:]]+)" as patch)
      "\+"
      ("([0-9]+)" as build_number)
      "\."
      ("([0-9a-fA-F]+)" as commit)
    ) => {
      let major = @strconv.parse_int(major)
      let minor = @strconv.parse_int(minor)
      let patch = @strconv.parse_int(patch)
      let build_number = @strconv.parse_int(build_number)
      Version::{
        major,
        minor,
        patch,
        build: Some({ number: build_number, commit: commit.to_string() }),
      }
    }
    _ => fail("Invalid version string format: " + string)
  }
}

///|
pub impl Compare for Version with compare(self, other) -> Int {
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
pub impl Eq for Version with equal(self, other) -> Bool {
  self.major == other.major &&
  self.minor == other.minor &&
  self.patch == other.patch &&
  (match (self.build, other.build) {
    (None, None) => true
    (Some(b1), Some(b2)) => b1.number == b2.number
    _ => false
  })
}
