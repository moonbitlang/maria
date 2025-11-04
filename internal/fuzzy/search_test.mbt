///|
test "find_match exact match" {
  let haystack = "Hello world\nThis is a test\nEnd of file"
  let needle = "This is a test"
  @json.inspect(@fuzzy.find_match(haystack, needle), content=[
    { "position": 12, "length": 14 },
  ])
}

///|
test "find_match line-by-line with whitespace" {
  let haystack = "  line 1  \n  line 2  \n  line 3  "
  let needle = "line 1\nline 2"
  @json.inspect(@fuzzy.find_match(haystack, needle), content=[
    { "position": 0, "length": 21 },
  ])
}

///|
test "find_match no match found" {
  let haystack = "Hello world"
  let needle = "Not found"
  @json.inspect(@fuzzy.find_match(haystack, needle), content=null)
}
