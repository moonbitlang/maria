///|
async test "retry" (t : @test.T) {
  try {
    @mock.run(t, retry=3, _ => assert_false(true))
    fail("should have failed")
  } catch {
    _ => ()
  }
  let mut count = 0
  @mock.run(t, retry=2, _ => {
    count += 1
    if count < 3 {
      fail("fail")
    }
  })
}
