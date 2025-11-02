///|
priv struct Drop {
  file : String
  index : Int
} derive(ToJson)

///|
priv struct Patched {
  content : String
  name : String
} derive(ToJson)

///|
priv struct Patch {
  drops : Array[Drop]
  patches : Array[Patched]
} derive(ToJson)

///|
pub async fn Module::check_patch_replace(
  self : Module,
  segment : SegmentView,
  content : String,
) -> Array[@diagnostics.Diagnostic] {
  @fs.with_temporary_directory("moon-check-patch-XXXXXXX", target_dir => {
    let pkg = self.locate_package(segment.file.path())
    let file_stem = @path.stem(segment.file.path())
    let patch_name_index = StringBuilder::new()
    patch_name_index.write_string("patch")
    for pat in ["_test", "_wbtest"] {
      if file_stem.has_suffix(pat) {
        patch_name_index.write_string(pat)
        break
      }
    }
    patch_name_index.write_string(".json")
    let patch_name_index = patch_name_index.to_string()
    let mangled_file_stem = file_stem.replace_all(old="/", new="-")
    let patch_path = @path.join(target_dir, patch_name_index)
    let patch_name = "patch-\{mangled_file_stem}-replace-\{segment.index}.\{patch_name_index}"
    let patch = {
      drops: [Drop::{ file: segment.file.path(), index: segment.index }],
      patches: [Patched::{ content, name: patch_name }],
    }
    @fs.write_to_file(patch_path, patch.to_json().stringify())
    let diagnostics = pkg.check(
      target_dir~,
      patch_file=patch_path,
      cwd=self.path,
    )
    diagnostics.filter_map(d => if d.loc.path.has_suffix(patch_name) {
      Some({ ..d, loc: { ..d.loc, path: segment.file.path() } })
    } else {
      None
    })
  })
}

///|
pub async fn Module::check_patch_insert(
  self : Module,
  file_path : String,
  content : String,
) -> Array[@diagnostics.Diagnostic] {
  @fs.with_temporary_directory("moon-check-patch-XXXXXXX", target_dir => {
    let pkg = self.locate_package(file_path)
    let file_base = @path.basename(file_path)
    let file_base_stem = @path.stem(file_base)
    let file_stem = @path.stem(file_path)
    let patch_name_index = StringBuilder::new()
    patch_name_index.write_substring(
      file_base_stem.data(),
      file_base_stem.start_offset(),
      file_base_stem.length(),
    )
    for pat in ["_test", "_wbtest"] {
      if file_stem.has_suffix(pat) {
        patch_name_index.write_string(pat)
        break
      }
    }
    patch_name_index.write_string(".json")
    let patch_name_index = patch_name_index.to_string()
    let mangled_file_stem = file_stem.replace_all(old="/", new="-")
    let patch_path = @path.join(target_dir, patch_name_index)
    let patch_name = "patch-\{mangled_file_stem}-insert.\{patch_name_index}"
    let patch = { drops: [], patches: [Patched::{ content, name: patch_name }] }
    @fs.write_to_file(patch_path, patch.to_json().stringify())
    let diagnostics = pkg.check(
      target_dir~,
      patch_file=patch_path,
      cwd=self.path,
    )
    diagnostics.filter_map(d => if d.loc.path.has_suffix(patch_name) {
      Some({ ..d, loc: { ..d.loc, path: file_path } })
    } else {
      None
    })
  })
}
