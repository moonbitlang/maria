///|
test "Timestamp::to_json" {
  let timestamp = @clock.Timestamp::from_ms(1625079600)
  @debug.assert_eq(timestamp.to_json(), 1625079600)
}

///|
test "Timestamp::from_json" {
  let json : Json = 1625079600
  let timestamp = @json.from_json(json)
  guard timestamp == @clock.Timestamp::from_ms(1625079600) else {
    fail("\{timestamp.ms()} != 1625079600")
  }
}

///|
test "Timestamp::ms_since" {
  let t1 = @clock.Timestamp::from_ms(2000)
  let t2 = @clock.Timestamp::from_ms(1500)
  @debug.assert_eq(t1.ms_since(t2), 500)
  @debug.assert_eq(t2.ms_since(t1), -500)
}

///|
test "Timestamp::truncate_to_s" {
  let t = @clock.Timestamp::from_ms(1625079600123)
  @debug.assert_eq(t.truncate_to_s(), 1625079600)
}

///|
test "Timestamp::ms" {
  let t = @clock.Timestamp::from_ms(1625079600123)
  @debug.assert_eq(t.ms(), 1625079600123)
}

///|
test "Timestamp::equal" {
  let t1 = @clock.Timestamp::from_ms(1000)
  let t2 = @clock.Timestamp::from_ms(1000)
  @debug.assert_eq(t1, t2)
}

///|
test "Timestamp::to_string" {
  let t = @clock.Timestamp::from_ms(1625079600123)
  inspect(@debug.to_string(t), content="1625079600123")
}
