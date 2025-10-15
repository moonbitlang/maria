///|
priv struct SplitItem {
  text : String
  splitteds : Array[String]
} derive(ToJson)

///|
typealias Map[String, SplitItem] as SplitResult

///|
test "snapshot testing" (t : @test.T) {
  let inputs : Map[String, String] = {
    "basic hello world": "hello world ",
    "mixed unicode and emoji": "hello world 你好 🐫32 ",
    "contractions with apostrophe - case insensitive": "'s's'S'D'd'M'm'T't",
    "contractions with ll, ve, re": "'ll'll've're",
    "non-letter prefix with letters": "!hello #world @user $money %percent ^caret",
    "punctuation followed by letters": ".com,org;net:edu?query&param=value",
    "unicode letters with prefixes": "!你好 @世界 #こんにちは $مرحبا",
    "numbers 1-3 digits": "1 12 123 1234 0 00 000 999",
    "unicode numbers": "١٢٣ ௧௨௩ ๑๒๓ 一二三",
    "space followed by punctuation": " !@# $%^ &*() -_=+ []{}\\|",
    "punctuation with newlines": "!@#\r\n$%^\n&*()\r",
    "mixed symbols and special chars": "©™®°±×÷≠≤≥∞§¶•‰‱",
    "whitespace at end of string": "text   ",
    "tabs and spaces at end": "word\t\t  ",
    "whitespace followed by newlines": "line1  \nline2\t\rline3   \r\n",
    "only whitespace and newlines": "   \n\t\r  \r\n",
    "whitespace not followed by non-whitespace": "word   end",
    "single whitespace characters": "a b\tc\nd e",
    "complex real-world text": "Hello, I'm testing the tokenizer! It's working well. Numbers: 123, 4567. Symbols: @#$%",
    "programming code snippet": "fn main() {\n  let x = 42;\n  println!(\"Hello, world!\");\n}",
    "multilingual text": "English, 中文, العربية, Español, français, русский, 日本語",
    "mathematical expressions": "x + y = 123, π ≈ 3.14159, ∑(i=1 to n) xi",
    "email and URLs": "Email: user@example.com, URL: https://www.test.org/path?q=123",
    "json-like structure": "{\"name\": \"value\", \"number\": 42, \"array\": [1, 2, 3]}",
    "json with indent=2": "{\n  \"type\": \"object\",\n  \"properties\": {\n    \"path\": {\n      \"type\": \"string\",\n      \"description\": \"The directory path to list files from\"\n    }\n  },\n  \"required\": [\n    \"path\"\n  ]\n}",
    "empty string": "",
    "only whitespace": "   \t\n  ",
    "mixed newline types": "line1\nline2\rline3\r\nline4",
    "consecutive punctuation": "...!!!???---___+++",
    "apostrophe variations": "'t'T'not_matched'xyz'll've're's'S'd'D'm'M",
    "numbers at boundaries": "a1b 12c 123d 1234e",
    "unicode combining characters": "café naïve résumé Zürich",
    "emoji and symbols mix": "Hello 👋 world 🌍! Price: $100.50 😊",
    "escaped characters and quotes": "\"quoted text\" 'single quotes' \\n\\t\\r",
    "boundary whitespace combinations": "\n\r\t \n  \t\r  ",
    "stress test: all regex parts combined": "'s'll've're 123 hello@world.com !@#$%^&*() \t\n\r 你好🌍",
    "number patterns: floats and scientific notation": "3.14 2.718e10 1E-5 .5 5. 123.456.789",
    "nested quotes and escapes": "\"He said 'Hello \"world\"!' to me.\"",
    "maximum length number sequences": "999888777666555444333222111000",
    "contractions with mixed case and punctuation": "It's, can't, won't, I'd, we'll, they've, 'twas, o'clock",
    "url-like patterns with different protocols": "http://test.com https://secure.org ftp://files.net file:///local/path",
    "mixed directional text (RTL/LTR)": "English العربية עברית English again",
    "code with mixed brackets and operators": "arr[i][j] = {x: y, z: w} && (a || b) != c",
    "whitespace variations: unicode spaces": "word\u{00A0}non-breaking\u{2003}em-space\u{2009}thin-space",
    "extremely long word": "supercalifragilisticexpialidocious",
    "single characters from each pattern": "' a 1 ! \t\n\r",
    "boundary conditions: string start/end": "\n  start middle end  \t",
    "html-like tags and entities": "<div class=\"test\">Hello &amp; goodbye &lt;/div&gt;",
    "regex special chars as literal text": "^$.*+?{}[]|()\\ ",
    "apostrophe edge cases not contractions": "'hello 'world' 'test's",
    "sequential numbers with separators": "1,234 567-890 123.456 789/012",
    "unicode control characters": "text\u{0001}control\u{0002}chars\u{001F}here",
    "mixed script numbers": "123 ፩፪፫ ۱۲۳ 一二三四五",
    "pathological whitespace cases": " \t\n\r \u{00A0}\u{2000}\u{2001}\u{2002} ",
    "repeated apostrophe patterns": "'s's's'll'll've've're're'd'd't't'm'm'S'S'D'D'M'M'T'T",
    "numbers at 1-3 digit boundaries": "9 99 999 9999 1000 100 10 1",
    "letter-number boundaries": "a1 1a ab12 12ab abc123 123abc",
    "unicode category edge cases": "𝕒𝔟𝑐 𝟭𝟮𝟯 🄰🄱🄲",
    "punctuation clusters with whitespace": "!!! \t\n ??? \r\n ... ",
    "string ending variations": "text\n",
    "only newlines": "\n\r\n\r",
    "mixed apostrophe and quotation marks": "\"can't\" 'won't' `don't`",
    "very long number sequence beyond 3 digits": "1234567890123456789",
    "unicode punctuation and symbols": "¡¿¡¿ «»«» ''‚„‚„",
    "letters followed by numbers without space": "word123 test456 abc789",
    "complex punctuation sequences": "!@#$%^&*()_+-=[]{}|;':\",./<>?",
    "whitespace at string boundaries": " start  end ",
    "CJK ideographs mixed with other scripts": "漢字abc한글def مرحباghi",
  }
  let map : SplitResult = {}
  for key, text in inputs {
    let tokens = cl100k_base_tokenize_all(text)
    let result = SplitItem::{ text, splitteds: tokens.map(x => x.to_string()) }
    map[key] = result
  }
  t.writeln(map.to_json().stringify(indent=2))
  t.snapshot(filename="splitted.json")
}
