///|
struct Manager {
  cwd : String
  access : Map[String, Int64]
}

///|
pub fn manager(cwd~ : String) -> Manager {
  Manager::{ cwd, access: {} }
}

///|
pub fn Manager::tools(self : Manager) -> Iter[@tool.Tool] {
  return [
    self.get_read_file_tool(),
    self.get_write_to_file_tool(),
    self.get_list_files_tool(),
  ].iter()
}
