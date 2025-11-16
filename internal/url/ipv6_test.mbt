///|
test "IPv6::parse" {
  let inputs = [
    "::1", "2001:db8::1", "::ffff:192.0.2.1", "::ABCD:192.0.2.1", ":1", "1:2:3:4:5:6:7:8:9",
    "1::1::1", "1:2:3!:4", "1:2:3:", "1:2:3", "1:1:1:1:1:1:1:127.0.0.1", "ffff::.0.0.1",
    "ffff::127.0.xyz.1", "ffff::127.0xyz", "ffff::127.00.0.1", "ffff::127.0.0.1.2",
    "ffff::127.0.0.4000", "ffff::127.0.0",
  ]
  @json.inspect(inputs.map(input => try? IPv6::parse(input)), content=[
    { "Ok": [0, 0, 0, 0, 0, 0, 0, 1] },
    { "Ok": [8193, 3512, 0, 0, 0, 0, 0, 1] },
    { "Ok": [0, 0, 0, 0, 0, 65535, 49152, 513] },
    { "Ok": [0, 0, 0, 0, 0, 43981, 49152, 513] },
    { "Err": "IPv6InvalidCompression" },
    { "Err": "IPv6TooManyPieces" },
    { "Err": "IPv6MultipleCompression" },
    { "Err": "IPv6InvalidCodePoint" },
    { "Err": "IPv6InvalidCodePoint" },
    { "Err": "IPv6TooFewPieces" },
    { "Err": "IPv4InIPv6TooManyPieces" },
    { "Err": "IPv4InIPv6InvalidCodePoint" },
    { "Err": "IPv4InIPv6InvalidCodePoint" },
    { "Err": "IPv4InIPv6InvalidCodePoint" },
    { "Err": "IPv4InIPv6InvalidCodePoint" },
    { "Err": "IPv4InIPv6InvalidCodePoint" },
    { "Err": "IPv4InIPv6OutOfRangePart" },
    { "Err": "IPv4InIPv6TooFewParts" },
  ])
}
