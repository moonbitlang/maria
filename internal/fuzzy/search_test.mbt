///|
test "find_match exact match" {
  let haystack =
    #|Hello world
    #|This is a test
    #|End of file
  let needle = "This is a test"
  json_inspect(@fuzzy.find_match(haystack, needle), content=[
    { "position": 12, "length": 14, "start_line": 1, "end_line": 1 },
  ])
}

///|
test "find_match line-by-line with whitespace" {
  let haystack =
    #|  line 1  
    #|  line 2  
    #|  line 3  
  let needle =
    #|line 1
    #|line 2
  json_inspect(@fuzzy.find_match(haystack, needle), content=[
    { "position": 0, "length": 21, "start_line": 0, "end_line": 1 },
  ])
  let haystack =
    #|line 1
    #|line 2
    #|line 3
    #|line 4
  let needle =
    #|line 2  
    #|  line 3
  json_inspect(@fuzzy.find_match(haystack, needle), content=[
    { "position": 7, "length": 13, "start_line": 1, "end_line": 2 },
  ])
}

///|
test "find_match/line-by-line/ignore-empty-lines" {
  let haystack =
    #|line 1
    #|
    #|line 2
    #|line 3
  let needle =
    #|line 1
    #|line 2
  json_inspect(@fuzzy.find_match(haystack, needle), content=[
    { "position": 0, "length": 14, "start_line": 0, "end_line": 2 },
  ])
  let haystack =
    #|line 1
    #|line 2
    #|
    #|line 3
    #|line 4
  let needle =
    #|line 2
    #|line 4
  json_inspect(@fuzzy.find_match(haystack, needle), content=null)
}

///|
test "find_match no match found" {
  let haystack = "Hello world"
  let needle = "Not found"
  json_inspect(@fuzzy.find_match(haystack, needle), content=null)
}
