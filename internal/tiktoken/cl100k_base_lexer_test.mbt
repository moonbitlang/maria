///|
priv struct LexerResult {
  text : String
  pieces : Array[String]
} derive(ToJson)

///|
priv struct SnapshotData {
  data : Array[LexerResult]
} derive(ToJson)

///|
let texts : ReadOnlyArray[String] = [
  "hello world ", "hello world 你好 🐫32 ", "'s's'S'D'd'M'm'T't", "'ll'll've're",
  "!hello #world @user $money %percent ^caret", ".com,org;net:edu?query&param=value",
  "!你好 @世界 #こんにちは $مرحبا", "1 12 123 1234 0 00 000 999", "١٢٣ ௧௨௩ ๑๒๓ 一二三",
  " !@# $%^ &*() -_=+ []{}\\|", "!@#\r\n$%^\n&*()\r", "©™®°±×÷≠≤≥∞§¶•‰‱",
  "text   ", "word\t\t  ", "line1  \nline2\t\rline3   \r\n", "   \n\t\r  \r\n", "a b\tc\nd e",
  "Hello, I'm testing the tokenizer! It's working well. Numbers: 123, 4567. Symbols: @#$%",
  "fn main() {\n  let x = 42;\n  println!(\"Hello, world!\");\n}", "English, 中文, العربية, Español, français, русский, 日本語",
  "x + y = 123, π ≈ 3.14159, ∑(i=1 to n) xi", "Email: user@example.com, URL: https://www.test.org/path?q=123",
  "{\"name\": \"value\", \"number\": 42, \"array\": [1, 2, 3]}", "", "   \t\n  ",
  "...!!!???---___+++", "'t'T'not_matched'xyz'll've're's'S'd'D'm'M", "a1b 12c 123d 1234e",
  "café naïve résumé Zürich", "Hello 👋 world 🌍! Price: $100.50 😊",
  "\"quoted text\" 'single quotes' \\n\\t\\r", "\n\r\t \n  \t\r  ", "'s'll've're 123 hello@world.com !@#$%^&*() \t\n\r 你好🌍",
  "3.14 2.718e10 1E-5 .5 5. 123.456.789", "\"He said 'Hello \"world\"!' to me.\"",
  "999888777666555444333222111000", "It's, can't, won't, I'd, we'll, they've, 'twas, o'clock",
  "http://test.com https://secure.org ftp://files.net file:///local/path", "English العربية עברית English again",
  "arr[i][j] = {x: y, z: w} && (a || b) != c", "word non-breaking em-space thin-space",
  "supercalifragilisticexpialidocious", "' a 1 ! \t\n\r", "<div class=\"test\">Hello &amp; goodbye &lt;/div&gt;",
  "^$.*+?{}[]|()\\ ", "'hello 'world' 'test's", "1,234 567-890 123.456 789/012",
  "text\u{01}control\u{02}chars\u{1f}here", "123 ፩፪፫ ۱۲۳ 一二三四五",
  " \t\n\r \u{00A0}\u{2000}\u{2001}\u{2002} ", "'s's's'll'll've've're're'd'd't't'm'm'S'S'D'D'M'M'T'T",
  "9 99 999 9999 1000 100 10 1", "a1 1a ab12 12ab abc123 123abc", "𝕒𝔟𝑐 𝟭𝟮𝟯 🄰🄱🄲",
  "text\n", "\n\r\n\r", "\"can't\" 'won't' `don't`", "1234567890123456789", "¡¿¡¿ «»«» ''‚„‚„",
  "word123 test456 abc789", "!@#$%^&*()_+-=[]{}|;':\",./<>?", " start  end ", "漢字abc한글def مرحباghi",
  "word   end", "{\n  \"type\": \"object\",\n  \"properties\": {\n    \"path\": {\n      \"type\": \"string\",\n      \"description\": \"The directory path to list files from\"\n    }\n  },\n  \"required\": [\n    \"path\"\n  ]\n}",
  "line1\nline2\rline3\r\nline4", "!!! \t\n ??? \r\n ... ", "\n  start middle end  \t",
]

///|
test (t : @test.Test) {
  let str_regex =
    #|'(?i:[sdmt]|ll|ve|re)|[^\r\n\p{L}\p{N}]?\p{L}+|\p{N}{1,3}| ?[^\s\p{L}\p{N}]+[\r\n]*|\s+$|\s*[\r\n]|\s+(?<Assertion>\s)|\s
  let regex = @regexp.compile(str_regex)
  let data = []
  for text in texts {
    let pieces = cl100k_base_tokenize_all_with_regex(regex, text).map(x => x.to_string())
    data.push(LexerResult::{ text, pieces })
  }
  let snapshot_data = SnapshotData::{ data, }
  let json = snapshot_data.to_json()
  t.writeln(json.stringify(indent=2))
  t.snapshot(filename="cl100k_base.json")
}
