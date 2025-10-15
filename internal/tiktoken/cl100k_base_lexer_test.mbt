///|
test "basic hello world" {
  let input =
    #|hello world 
  // delimiter 
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=["hello", " world", " "])
}

///|
test "mixed unicode and emoji" {
  let input =
    #|hello world 你好 🐫32 
  // delimiter 
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=[
    "hello", " world", " 你好", " 🐫", "32", " ",
  ])
}

///|
test "Part 1: contractions with apostrophe - case insensitive [sdmt]" {
  let input = "'s's'S'D'd'M'm'T't"
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=[
    "'s", "'s", "'S", "'D", "'d", "'M", "'m", "'T", "'t",
  ])
}

///|
test "Part 1: contractions with ll, ve, re" {
  let input = "'ll'll've're"
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=["'ll", "'ll", "'ve", "'re"])
}

///|
test "Part 2: non-letter prefix with letters" {
  let input = "!hello #world @user $money %percent ^caret"
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=[
    "!hello", " #world", " @user", " $money", " %percent", " ^caret",
  ])
}

///|
test "Part 2: punctuation followed by letters" {
  let input = ".com,org;net:edu?query&param=value"
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=[
    ".com", ",org", ";net", ":edu", "?query", "&param", "=value",
  ])
}

///|
test "Part 2: unicode letters with prefixes" {
  let input = "!你好 @世界 #こんにちは $مرحبا"
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=[
    "!你好", " @世界", " #こんにちは", " $مرحبا",
  ])
}

///|
test "Part 3: numbers 1-3 digits" {
  let input = "1 12 123 1234 0 00 000 999"
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=[
    "1", " ", "12", " ", "123", " ", "123", "4", " ", "0", " ", "00", " ", "000",
    " ", "999",
  ])
}

///|
test "Part 3: unicode numbers" {
  let input = "١٢٣ ௧௨௩ ๑๒๓ 一二三"
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=[
    "١٢٣", " ", "௧௨௩", " ", "๑๒๓", " 一二三",
  ])
}

///|
test "Part 4: space followed by punctuation" {
  let input = " !@# $%^ &*() -_=+ []{}\\|"
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=[" !@#", " $%^", " &*()", " -_=+", " []{}\\|"])
}

///|
test "Part 4: punctuation with newlines" {
  let input = "!@#\r\n$%^\n&*()\r"
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=["!@#\r\n", "$%^\n", "&*()\r"])
}

///|
test "Part 4: mixed symbols and special chars" {
  let input = "©™®°±×÷≠≤≥∞§¶•‰‱"
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=["©™®°±×÷≠≤≥∞§¶•‰‱"])
}

///|
test "Part 5: whitespace at end of string" {
  let input = "text   "
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=["text", "   "])
}

///|
test "Part 5: tabs and spaces at end" {
  let input = "word\t\t  "
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=["word", "\t\t  "])
}

///|
test "Part 6: whitespace followed by newlines" {
  let input = "line1  \nline2\t\rline3   \r\n"
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=[
    "line", "1", "  \n", "line", "2", "\t\r", "line", "3", "   \r\n",
  ])
}

///|
test "Part 6: only whitespace and newlines" {
  let input = "   \n\t\r  \r\n"
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=["   \n\t\r  \r\n"])
}

///|
test "Part 7: whitespace not followed by non-whitespace" {
  let input = "word   end"
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=["word", "   end"])
}

///|
test "Part 8: single whitespace characters" {
  let input = "a b\tc\nd e"
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=["a", " b", "\tc", "\n", "d", " e"])
}

///|
test "complex real-world text" {
  let input = "Hello, I'm testing the tokenizer! It's working well. Numbers: 123, 4567. Symbols: @#$%"
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=[
    "Hello", ", I", "'m", " testing", " the", " tokenizer", "! It", "'s", " working",
    " well", ". Numbers", ":", " ", "123", ",", " ", "456", "7", ". Symbols", ":",
    " @#$%",
  ])
}

///|
test "programming code snippet" {
  let input = "fn main() {\n  let x = 42;\n  println!(\"Hello, world!\");\n}"
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=[
    "fn", " main", "()", " {\n", "  let", " x", " =", " ", "42", ";\n", "  println",
    "!(\"Hello", ", world", "!\");\n", "}",
  ])
}

///|
test "multilingual text" {
  let input = "English, 中文, العربية, Español, français, русский, 日本語"
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=[
    "English", ", 中文", ", العربية", ", Español", ", français", ", русский",
    ", 日本語",
  ])
}

///|
test "mathematical expressions" {
  let input = "x + y = 123, π ≈ 3.14159, ∑(i=1 to n) xi"
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=[
    "x", " + y", " =", " ", "123", ", π", " ≈", " ", "3", ".", "141", "59", ", ∑(i",
    "=", "1", " to", " n", ") xi",
  ])
}

///|
test "email and URLs" {
  let input = "Email: user@example.com, URL: https://www.test.org/path?q=123"
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=[
    "Email", ": user", "@example", ".com", ", URL", ": https", "://www", ".test",
    ".org", "/path", "?q", "=", "123",
  ])
}

///|
test "json-like structure" {
  let input = "{\"name\": \"value\", \"number\": 42, \"array\": [1, 2, 3]}"
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=[
    "{\"name", "\": \"value", "\", \"number", "\":", " ", "42", ", \"array", "\":",
    " [", "1", ",", " ", "2", ",", " ", "3", "]}",
  ])
}

///|
test "empty and whitespace-only strings" {
  let input = ""
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=[])
}

///|
test "only whitespace" {
  let input = "   \t\n  "
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=["   \t\n  "])
}

///|
test "mixed newline types" {
  let input = "line1\nline2\rline3\r\nline4"
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=[
    "line", "1", "\n", "line", "2", "\r", "line", "3", "\r", "\n", "line", "4",
  ])
}

///|
test "consecutive punctuation" {
  let input = "...!!!???---___+++"
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=["...!!!???---___+++"])
}

///|
test "edge case: apostrophe variations" {
  let input = "'t'T'not_matched'xyz'll've're's'S'd'D'm'M"
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=[
    "'t", "'T", "'not", "_matched", "'xyz", "'ll", "'ve", "'re", "'s", "'S", "'d",
    "'D", "'m", "'M",
  ])
}

///|
test "numbers at boundaries" {
  let input = "a1b 12c 123d 1234e"
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=[
    "a", "1", "b", " ", "12", "c", " ", "123", "d", " ", "123", "4", "e",
  ])
}

///|
test "unicode combining characters" {
  let input = "café naïve résumé Zürich"
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=["café", " naïve", " résumé", " Zürich"])
}

///|
test "emoji and symbols mix" {
  let input = "Hello 👋 world 🌍! Price: $100.50 😊"
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=[
    "Hello", " 👋 world", " 🌍! Price", ":", " $", "100", ".", "50", " 😊",
  ])
}

///|
test "escaped characters and quotes" {
  let input = "\"quoted text\" 'single quotes' \\n\\t\\r"
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=[
    "\"quoted", " text", "\" 'single", " quotes", "' \\n", "\\t", "\\r",
  ])
}

///|
test "boundary whitespace combinations" {
  let input = "\n\r\t \n  \t\r  "
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=["\n\r\t \n  \t\r  "])
}

///|
test "stress test: all regex parts combined" {
  let input = "'s'll've're 123 hello@world.com !@#$%^&*() \t\n\r 你好🌍"
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=[
    "'s", "'ll", "'ve", "'re", " ", "123", " hello", "@world", ".com", " !@#$%^&*()",
    " \t\n", "\r", " 你好", "🌍",
  ])
}

///|
test "number patterns: floats and scientific notation" {
  let input = "3.14 2.718e10 1E-5 .5 5. 123.456.789"
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=[
    "3", ".", "14", " ", "2", ".", "718", "e", "10", " ", "1", "E", "-", "5", " .",
    "5", " ", "5", ".", " ", "123", ".", "456", ".", "789",
  ])
}

///|
test "nested quotes and escapes" {
  let input = "\"He said 'Hello \"world\"!' to me.\""
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=[
    "\"He", " said", " 'Hello", " \"world", "\"!' to", " me", ".\"",
  ])
}

///|
test "maximum length number sequences" {
  let input = "999888777666555444333222111000"
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=[
    "999", "888", "777", "666", "555", "444", "333", "222", "111", "000",
  ])
}

///|
test "contractions with mixed case and punctuation" {
  let input = "It's, can't, won't, I'd, we'll, they've, 'twas, o'clock"
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=[
    "It", "'s", ", can", "'t", ", won", "'t", ", I", "'d", ", we", "'ll", ", they",
    "'ve", ", 'twas", ", o", "'clock",
  ])
}

///|
test "url-like patterns with different protocols" {
  let input = "http://test.com https://secure.org ftp://files.net file:///local/path"
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=[
    "http", "://test", ".com", " https", "://secure", ".org", " ftp", "://files",
    ".net", " file", ":///local", "/path",
  ])
}

///|
test "mixed directional text (RTL/LTR)" {
  let input = "English العربية עברית English again"
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=[
    "English", " العربية", " עברית", " English", " again",
  ])
}

///|
test "code with mixed brackets and operators" {
  let input = "arr[i][j] = {x: y, z: w} && (a || b) != c"
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=[
    "arr", "[i", "][j", "] = {x", ": y", ", z", ": w", "} && (a", " || b", ") != c",
  ])
}

///|
test "whitespace variations: unicode spaces" {
  let input = "word\u{00A0}non-breaking\u{2003}em-space\u{2009}thin-space"
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=[
    "word", " non", "-breaking", " em", "-space", " thin", "-space",
  ])
}

///|
test "extremely long word" {
  let input = "supercalifragilisticexpialidocious"
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=["supercalifragilisticexpialidocious"])
}

///|
test "single characters from each pattern" {
  let input = "' a 1 ! \t\n\r"
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=["' a", " ", "1", " !", " \t\n\r"])
}

///|
test "boundary conditions: string start/end" {
  let input = "\n  start middle end  \t"
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=["\n", "  start", " middle", " end", "  \t"])
}

///|
test "html-like tags and entities" {
  let input = "<div class=\"test\">Hello &amp; goodbye &lt;/div&gt;"
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=[
    "<div", " class", "=\"test", "\">Hello", " &amp", "; goodbye", " &lt", ";/div",
    "&gt", ";",
  ])
}

///|
test "regex special chars as literal text" {
  let input = "^$.*+?{}[]|()\\"
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=["^$.*+?{}[]|()\\"])
}

///|
test "apostrophe edge cases: not contractions" {
  let input = "'hello 'world' 'test's"
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=["'hello", " 'world", "' 'test", "'s"])
}

///|
test "sequential numbers with separators" {
  let input = "1,234 567-890 123.456 789/012"
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=[
    "1", ",", "234", " ", "567", "-", "890", " ", "123", ".", "456", " ", "789",
    "/", "012",
  ])
}

///|
test "unicode control characters" {
  let input = "text\u{0001}control\u{0002}chars\u{001F}here"
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=[
    "text", "\u0001control", "\u0002chars", "\u001fhere",
  ])
}

///|
test "mixed script numbers" {
  let input = "123 ፩፪፫ ۱۲۳ 一二三四五"
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=[
    "123", " ", "፩፪፫", " ", "۱۲۳", " 一二三四五",
  ])
}

///|
test "pathological whitespace cases" {
  let input = " \t\n\r \u{00A0}\u{2000}\u{2001}\u{2002} "
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=[" \t\n\r      "])
}

///|
test "repeated apostrophe patterns" {
  let input = "'s's's'll'll've've're're'd'd't't'm'm'S'S'D'D'M'M'T'T"
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=[
    "'s", "'s", "'s", "'ll", "'ll", "'ve", "'ve", "'re", "'re", "'d", "'d", "'t",
    "'t", "'m", "'m", "'S", "'S", "'D", "'D", "'M", "'M", "'T", "'T",
  ])
}

///|
test "numbers at 1-3 digit boundaries" {
  let input = "9 99 999 9999 1000 100 10 1"
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=[
    "9", " ", "99", " ", "999", " ", "999", "9", " ", "100", "0", " ", "100", " ",
    "10", " ", "1",
  ])
}

///|
test "letter-number boundaries" {
  let input = "a1 1a ab12 12ab abc123 123abc"
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=[
    "a", "1", " ", "1", "a", " ab", "12", " ", "12", "ab", " abc", "123", " ", "123",
    "abc",
  ])
}

///|
test "unicode category edge cases" {
  let input = "𝕒𝔟𝑐 𝟭𝟮𝟯 🄰🄱🄲"
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=[
    "𝕒𝔟𝑐", " ", "𝟭𝟮𝟯", " 🄰🄱🄲",
  ])
}

///|
test "punctuation clusters with whitespace" {
  let input = "!!! \t\n ??? \r\n ... "
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=[
    "!!!", " \t\n", " ???", " \r", "\n", " ...", " ",
  ])
}

///|
test "string ending variations" {
  let input = "text\n"
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=["text", "\n"])
}

///|
test "only newlines" {
  let input = "\n\r\n\r"
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=["\n\r\n\r"])
}

///|
test "mixed apostrophe and quotation marks" {
  let input = "\"can't\" 'won't' `don't`"
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=[
    "\"can", "'t", "\" 'won", "'t", "' `don", "'t", "`",
  ])
}

///|
test "very long number sequence beyond 3 digits" {
  let input = "1234567890123456789"
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=["123", "456", "789", "012", "345", "678", "9"])
}

///|
test "unicode punctuation and symbols" {
  let input = "¡¿¡¿ «»«» ''‚„‚„"
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=["¡¿¡¿", " «»«»", " ''‚„‚„"])
}

///|
test "letters followed by numbers without space" {
  let input = "word123 test456 abc789"
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=["word", "123", " test", "456", " abc", "789"])
}

///|
test "complex punctuation sequences" {
  let input = "!@#$%^&*()_+-=[]{}|;':\",./<>?"
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=["!@#$%^&*()_+-=[]{}|;':\",./<>?"])
}

///|
test "whitespace at string boundaries" {
  let input = " start  end "
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=[" start", "  end", " "])
}

///|
test "CJK ideographs mixed with other scripts" {
  let input = "漢字abc한글def مرحباghi"
  let result = cl100k_base_tokenize_all(input)
  @json.inspect(result, content=["漢字abc한글def", " مرحباghi"])
}
