///|
/// Adds line numbers to unified diff output, displaying both original and
/// modified line numbers side by side. This function should only be used for
/// displaying diffs for human consumption. It is not sure if the output can be
/// correctly understood by LLM.
///
/// Parameters:
///
/// * `diff_text` : The unified diff text to process, containing diff headers
///   and hunks with added, removed, and unchanged lines.
///
/// Returns a string with line numbers added to each diff line, formatted as
/// "original\_line modified\_line content".
///
/// Throws an error if the diff text contains malformed hunk headers that cannot
/// be parsed.
fn add_line_number_to_diff(diff_text : String) -> String raise {
  struct State {
    original_start : Int
    mut original_line : Int
    original_count : Int
    modified_start : Int
    mut modified_line : Int
    modified_count : Int
    mut marker : Char
  }
  let lines = diff_text.split("\n")
  let mut last_state : State? = None
  let mut state : State? = None
  let numbered_lines = []
  for line in lines {
    if state is Some(s) {
      if s.original_line >= s.original_start + s.original_count &&
        s.modified_line >= s.modified_start + s.modified_count {
        last_state = Some(s)
        state = None
      }
    }
    if state is Some(state) {
      let number_width = @cmp.maximum(
        (state.original_start + state.original_count).to_string().length(),
        (state.modified_start + state.modified_count).to_string().length(),
      )
      match line {
        [' ', .. line] => {
          let original_line_number = state.original_line
            .to_string()
            .pad_start(number_width, ' ')
          let modified_line_number = state.modified_line
            .to_string()
            .pad_start(number_width, ' ')
          numbered_lines.push(
            "  \{original_line_number} \{modified_line_number} │\{line}",
          )
          state.original_line += 1
          state.modified_line += 1
          state.marker = ' '
        }
        ['+', .. line] => {
          let original_line_number = " ".repeat(number_width)
          let modified_line_number = state.modified_line
            .to_string()
            .pad_start(number_width, ' ')
          numbered_lines.push(
            "+ \{original_line_number} \{modified_line_number} │\{line}",
          )
          state.modified_line += 1
          state.marker = '+'
        }
        ['-', .. line] => {
          let original_line_number = state.original_line
            .to_string()
            .pad_start(number_width, ' ')
          let modified_line_number = " ".repeat(number_width)
          numbered_lines.push(
            "- \{original_line_number} \{modified_line_number} │\{line}",
          )
          state.original_line += 1
          state.marker = '-'
        }
        ['\\', .. line] => {
          let original_line_number = " ".repeat(number_width)
          let modified_line_number = " ".repeat(number_width)
          numbered_lines.push(
            "\{state.marker} \{original_line_number} \{modified_line_number} \\\{line}",
          )
        }
        line => numbered_lines.push(line.to_string())
      }
    } else if last_state is Some(state) && line is ['\\', .. line] {
      let number_width = @cmp.maximum(
        (state.original_start + state.original_count).to_string().length(),
        (state.modified_start + state.modified_count).to_string().length(),
      )
      let original_line_number = " ".repeat(number_width)
      let modified_line_number = " ".repeat(number_width)
      numbered_lines.push(
        "\{state.marker} \{original_line_number} \{modified_line_number} \\\{line}",
      )
    } else {
      lexmatch line {
        (
          "@@\s+-"
          ("\d+" as os)
          ","
          ("\d+" as oc)
          "\s+\+"
          ("\d+" as ms)
          ","
          ("\d+" as mc)
          "\s+@@",
          _
        ) => {
          let original_start = @strconv.parse_int(os)
          let original_count = @strconv.parse_int(oc)
          let modified_start = @strconv.parse_int(ms)
          let modified_count = @strconv.parse_int(mc)
          state = Some({
            original_start,
            original_line: original_start,
            original_count,
            modified_start,
            modified_line: modified_start,
            modified_count,
            marker: ' ',
          })
          numbered_lines.push(line.to_string())
        }
        line => numbered_lines.push(line.to_string())
      }
    }
  }
  numbered_lines.join("\n")
}

///|
test "add_line_number_to_diff" {
  let content =
    #|@@ -1,3 +1,4 @@
    #| line 1
    #|-line 2
    #|-line 3
    #|\ No newline at end of file
    #|+line 2 modified
    #|+line 3
    #|+line 4 added
    #|\ No newline at end of file
    #|
  let numbered = add_line_number_to_diff(content)
  inspect(
    numbered,
    content=(
      #|@@ -1,3 +1,4 @@
      #|  1 1 │line 1
      #|- 2   │line 2
      #|- 3   │line 3
      #|-     \ No newline at end of file
      #|+   2 │line 2 modified
      #|+   3 │line 3
      #|+   4 │line 4 added
      #|+     \ No newline at end of file
      #|
    ),
  )
}

///|
test "add_line_number_to_diff_insert" {
  let content =
    #|diff --git original modified
    #|index 3072eaa..847cf83 100644
    #|--- original
    #|+++ modified
    #|@@ -1,19 +1,18 @@
    #| enum Color {
    #|-  Red,
    #|-  Green,
    #|-  Blue,
    #|+  Red
    #|+  Green
    #|+  Blue
    #| }
    #| 
    #| fn Color::to_string(self : Color) -> String {
    #|-  switch self {
    #|-    Red => "red",
    #|-    Green => "green",
    #|-    Blue => "blue",
    #|+  match self {
    #|+    Red => "red"
    #|+    Green => "green"
    #|+    Blue => "blue"
    #|   }
    #| }
    #| 
    #|-fn main() {
    #|-
    #|-  let color : Color = Blue
    #|+fn main {
    #|+  let color : Color = Color::Blue
    #|   println(color.to_string())
    #|-}
    #|+}
    #|\ No newline at end of file
    #|
  let numbered = add_line_number_to_diff(content)
  inspect(
    numbered,
    content=(
      #|diff --git original modified
      #|index 3072eaa..847cf83 100644
      #|--- original
      #|+++ modified
      #|@@ -1,19 +1,18 @@
      #|   1  1 │enum Color {
      #|-  2    │  Red,
      #|-  3    │  Green,
      #|-  4    │  Blue,
      #|+     2 │  Red
      #|+     3 │  Green
      #|+     4 │  Blue
      #|   5  5 │}
      #|   6  6 │
      #|   7  7 │fn Color::to_string(self : Color) -> String {
      #|-  8    │  switch self {
      #|-  9    │    Red => "red",
      #|- 10    │    Green => "green",
      #|- 11    │    Blue => "blue",
      #|+     8 │  match self {
      #|+     9 │    Red => "red"
      #|+    10 │    Green => "green"
      #|+    11 │    Blue => "blue"
      #|  12 12 │  }
      #|  13 13 │}
      #|  14 14 │
      #|- 15    │fn main() {
      #|- 16    │
      #|- 17    │  let color : Color = Blue
      #|+    15 │fn main {
      #|+    16 │  let color : Color = Color::Blue
      #|  18 17 │  println(color.to_string())
      #|- 19    │}
      #|+    18 │}
      #|+       \ No newline at end of file
      #|
    ),
  )
}

///|
test "add_line_number_to_diff_no_hunks" {
  let content =
    #|diff --git a/file.txt b/file.txt
    #|index e69de29..4b825dc 100644
    #|--- a/file.txt
    #|+++ b/file.txt
    #|
  let numbered = add_line_number_to_diff(content)
  inspect(
    numbered,
    content=(
      #|diff --git a/file.txt b/file.txt
      #|index e69de29..4b825dc 100644
      #|--- a/file.txt
      #|+++ b/file.txt
      #|
    ),
  )
}

///|
async test "add_line_number_to_diff_slash" (t : @test.Test) {
  @mock.run(t, _ => {
    let original =
      #|line 1
      #|line 2
      #|line 3
      #|line 4
      #|line 5
    let modified =
      #|line 1
      #|line 2 modified
      #|line 3
      #|line 4
      #|line 5 modified
      #|line 6 added
    inspect(
      generate_git_diff(original~, modified~, line_number=false),
      content=(
        #|diff --git original modified
        #|index a751413..30797a1 100644
        #|--- original
        #|+++ modified
        #|@@ -1,5 +1,6 @@
        #| line 1
        #|-line 2
        #|+line 2 modified
        #| line 3
        #| line 4
        #|-line 5
        #|\ No newline at end of file
        #|+line 5 modified
        #|+line 6 added
        #|\ No newline at end of file
      ),
    )
    inspect(
      generate_git_diff(original~, modified~, line_number=true),
      content=(
        #|diff --git original modified
        #|index a751413..30797a1 100644
        #|--- original
        #|+++ modified
        #|@@ -1,5 +1,6 @@
        #|  1 1 │line 1
        #|- 2   │line 2
        #|+   2 │line 2 modified
        #|  3 3 │line 3
        #|  4 4 │line 4
        #|- 5   │line 5
        #|-     \ No newline at end of file
        #|+   5 │line 5 modified
        #|+   6 │line 6 added
        #|+     \ No newline at end of file
      ),
    )
  })
}

///|
async test "add_line_number_to_diff_multiple_hunks" (t : @test.Test) {
  @mock.run(t, _ => {
    let original =
      #|line 1
      #|line 2
      #|line 3
      #|line 4
      #|line 5
      #|line 6
      #|line 7
      #|line 8
      #|line 9
      #|line 10
      #|line 11
      #|line 12
      #|line 13
      #|line 14
      #|line 15
    let modified =
      #|line 1
      #|line 2 modified
      #|line 3
      #|line 4
      #|line 5
      #|line 6
      #|line 7
      #|line 8
      #|line 9
      #|line 10
      #|line 11
      #|line 12
      #|line 13
      #|line 14 modified
      #|line 15
    inspect(
      generate_git_diff(original~, modified~, line_number=false),
      content=(
        #|diff --git original modified
        #|index af9f7cc..89f4457 100644
        #|--- original
        #|+++ modified
        #|@@ -1,5 +1,5 @@
        #| line 1
        #|-line 2
        #|+line 2 modified
        #| line 3
        #| line 4
        #| line 5
        #|@@ -11,5 +11,5 @@ line 10
        #| line 11
        #| line 12
        #| line 13
        #|-line 14
        #|+line 14 modified
        #| line 15
        #|\ No newline at end of file
      ),
    )
    inspect(
      generate_git_diff(original~, modified~, line_number=true),
      content=(
        #|diff --git original modified
        #|index af9f7cc..89f4457 100644
        #|--- original
        #|+++ modified
        #|@@ -1,5 +1,5 @@
        #|  1 1 │line 1
        #|- 2   │line 2
        #|+   2 │line 2 modified
        #|  3 3 │line 3
        #|  4 4 │line 4
        #|  5 5 │line 5
        #|@@ -11,5 +11,5 @@ line 10
        #|  11 11 │line 11
        #|  12 12 │line 12
        #|  13 13 │line 13
        #|- 14    │line 14
        #|+    14 │line 14 modified
        #|  15 15 │line 15
        #|        \ No newline at end of file
      ),
    )
  })
}
