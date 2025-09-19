// ///|
// test "segment" {
//   let source =
//     #|// Header
//     #|///| a
//     #|let x : Int = 5
//     #|///| b
//     #|let y : String = \"hello\"
//     #|///|
//     #|/// c
//     #|fn greet() -> String {
//     #|  y
//     #|}
//     #|///|
//   let source = Source::new(source)
//   @json.inspect(source, content={
//     "content": "// Header\n///| a\nlet x : Int = 5\n///| b\nlet y : String = \\\"hello\\\"\n///|\n/// c\nfn greet() -> String {\n  y\n}\n///|",
//     "header": { "start": 0, "end": 1, "content": "// Header" },
//     "segments": [
//       { "start": 1, "end": 3, "content": "///| a\nlet x : Int = 5" },
//       {
//         "start": 3,
//         "end": 5,
//         "content": "///| b\nlet y : String = \\\"hello\\\"",
//       },
//       {
//         "start": 5,
//         "end": 10,
//         "content": "///|\n/// c\nfn greet() -> String {\n  y\n}",
//       },
//       { "start": 10, "end": 11, "content": "///|" },
//     ],
//   })
// }
