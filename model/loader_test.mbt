///|
async test "Loader" (t : @test.Test) {
  @mock.run(t, mock => {
    let api_key = mock.getenv("OPENAI_API_KEY")
    let model = @model.new(
      api_key~,
      base_url="https://openrouter.ai/api/v1",
      name="haiku",
      model_name="anthropic/claude-haiku-4.5",
      safe_zone_tokens=200000,
    )
    let models = [model]
    let models_file = mock.cwd
      .add_directory(".moonagent")
      .add_directory("models")
      .add_file("models.json")
    models_file.write_string(models.to_json().stringify(indent=2))
    @json.inspect(mock.json(@json.parse(models_file.read())), content=[
      {
        "name": "haiku",
        "model_name": "anthropic/claude-haiku-4.5",
        "model_type": "saas/openai",
        "api_key": "(mock:env:OPENAI_API_KEY)",
        "base_url": "https://openrouter.ai/api/v1",
        "safe_zone_tokens": 200000,
        "supports_anthropic_prompt_caching": false,
      },
    ])
    let loader = @model.Loader::new(home=mock.cwd.path(), cwd=mock.cwd.path())
    @json.inspect(mock.json(loader.get_model(name="haiku")), content=[
      {
        "name": "haiku",
        "model_name": "anthropic/claude-haiku-4.5",
        "model_type": "saas/openai",
        "api_key": "(mock:env:OPENAI_API_KEY)",
        "base_url": "https://openrouter.ai/api/v1",
        "safe_zone_tokens": 200000,
        "supports_anthropic_prompt_caching": false,
      },
    ])
  })
}

///|
async test "load" (t : @test.Test) {
  @mock.run(t, mock => {
    let api_key = mock.getenv("OPENAI_API_KEY")
    let model = @model.new(
      api_key~,
      base_url="https://openrouter.ai/api/v1",
      name="haiku",
      model_name="anthropic/claude-haiku-4.5",
      safe_zone_tokens=200000,
    )
    let models = [model]
    let models_file = mock.cwd
      .add_directory(".moonagent")
      .add_directory("models")
      .add_file("models.json")
    models_file.write_string(models.to_json().stringify(indent=2))
    @json.inspect(mock.json(@json.parse(models_file.read())), content=[
      {
        "name": "haiku",
        "model_name": "anthropic/claude-haiku-4.5",
        "model_type": "saas/openai",
        "api_key": "(mock:env:OPENAI_API_KEY)",
        "base_url": "https://openrouter.ai/api/v1",
        "safe_zone_tokens": 200000,
        "supports_anthropic_prompt_caching": false,
      },
    ])
    @json.inspect(
      mock.json(
        @model.load(home=mock.cwd.path(), cwd=mock.cwd.path(), name="haiku"),
      ),
      content=[
        {
          "name": "haiku",
          "model_name": "anthropic/claude-haiku-4.5",
          "model_type": "saas/openai",
          "api_key": "(mock:env:OPENAI_API_KEY)",
          "base_url": "https://openrouter.ai/api/v1",
          "safe_zone_tokens": 200000,
          "supports_anthropic_prompt_caching": false,
        },
      ],
    )
  })
}

///|
async test "removes-old-models" (t : @test.Test) {
  @mock.run(t, mock => {
    let old_model = @model.new(
      api_key="old_api_key",
      base_url="https://old-base-url.com",
      name="old_model",
      model_name="old/model-name",
      safe_zone_tokens=100000,
    )
    let models_file = mock.cwd
      .add_directory(".moonagent")
      .add_directory("models")
      .add_file("models.json")
    let models = [old_model]
    models_file.write_string(models.to_json().stringify(indent=2))
    let loader = @model.Loader::new(home=mock.cwd.path(), cwd=mock.cwd.path())
    @json.inspect(loader.get_model(), content=[
      {
        "name": "old_model",
        "model_name": "old/model-name",
        "model_type": "saas/openai",
        "api_key": "old_api_key",
        "base_url": "https://old-base-url.com",
        "safe_zone_tokens": 100000,
        "supports_anthropic_prompt_caching": false,
      },
    ])
    let new_model = @model.new(
      api_key="new_api_key",
      base_url="https://openrouter.ai/api/v1",
      name="new_model",
      model_name="anthropic/claude-haiku-4.5",
      safe_zone_tokens=200000,
    )
    let models = [new_model]
    models_file.write_string(models.to_json().stringify(indent=2))
    @json.inspect(loader.get_model(), content=[
      {
        "name": "new_model",
        "model_name": "anthropic/claude-haiku-4.5",
        "model_type": "saas/openai",
        "api_key": "new_api_key",
        "base_url": "https://openrouter.ai/api/v1",
        "safe_zone_tokens": 200000,
        "supports_anthropic_prompt_caching": false,
      },
    ])
  })
}
