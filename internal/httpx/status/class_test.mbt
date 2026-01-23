///|
test "classify" {
  for i in 100..<=199 {
    assert_true(@status.classify(i) is Informational)
  }
  for i in 200..<=299 {
    assert_true(@status.classify(i) is Successful)
  }
  for i in 300..<=399 {
    assert_true(@status.classify(i) is Redirection)
  }
  for i in 400..<=499 {
    assert_true(@status.classify(i) is ClientError)
  }
  for i in 500..<=599 {
    assert_true(@status.classify(i) is ServerError)
  }
  for i in [99, 600, 700, 800, 9999] {
    assert_true(@status.classify(i) is Invalid)
  }
}
