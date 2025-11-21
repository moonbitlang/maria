///|
async test "get_models" (t : @test.Test) {
  @mock.run(t, mock => {
    let api_key = mock.getenv("OPENROUTER_API_KEY")
    let count = @openrouter.get_models_count(api_key~)
    @json.inspect(count > 0, content=true)
    let models = @openrouter.get_models(api_key~)
    @json.inspect(models.length() == count, content=true)
  })
}
