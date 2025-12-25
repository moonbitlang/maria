///|
async test "get_models" (t : @test.Test) {
  @mock.run(t, mock => {
    let api_key = mock.getenv("OPENROUTER_API_KEY")
    let openrouter = @openrouter.OpenRouter::new(api_key~)
    let models = openrouter.models.list()
    assert_true(models.length() > 0)
    let count = openrouter.models.count()
    assert_true(count > 0)
  })
}
