///|
test "Host::parse" {
  let inputs = [
    "EXAMPLE.com", "example%2Ecom", "0", "%30", "0x", "0xffffffff", "[0:0::1]", "[0:0::1%5D",
    "[0:0::%31]", "09", "example.255", "example^example",
  ]
  @json.inspect(inputs.map(input => try? Host::parse(input)), content=[
    { "Ok": ["Domain", "example.com"] },
    { "Ok": ["Domain", "example.com"] },
    { "Err": "IPv4NonNumericPart" },
    { "Err": "IPv4NonNumericPart" },
    { "Ok": ["IPv4", [0, 0, 0, 0]] },
    { "Ok": ["IPv4", [255, 255, 255, 255]] },
    { "Ok": ["IPv6", [0, 0, 0, 0, 0, 0, 0, 1]] },
    { "Err": "IPv6Unclosed" },
    { "Err": "IPv6InvalidCodePoint" },
    { "Err": "IPv4NonNumericPart" },
    { "Err": "IPv4NonNumericPart" },
    { "Ok": ["Domain", "example^example"] },
  ])
}
