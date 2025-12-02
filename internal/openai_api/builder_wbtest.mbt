///|
test "ChatCompletionMessageToolCallBuilder" {
  let builder = ChatCompletionMessageToolCallBuilder::new(
    id="tool_call_1",
    name="get_weather",
  )
  builder.add_delta(
    @openai.chunk_choice_delta_tool_call(
      index=0,
      function=@openai.chunk_choice_delta_tool_call_function(
        arguments=(
          #|{ "location
        ),
      ),
    ),
  )
  builder.add_delta(
    @openai.chunk_choice_delta_tool_call(
      index=0,
      function=@openai.chunk_choice_delta_tool_call_function(
        arguments=(
          #|": "San
        ),
      ),
    ),
  )
  builder.add_delta(
    @openai.chunk_choice_delta_tool_call(
      index=0,
      function=@openai.chunk_choice_delta_tool_call_function(
        arguments=(
          #| Francisco" }
        ),
      ),
    ),
  )
  let tool_call = builder.to_tool_call()
  @json.inspect(tool_call, content={
    "id": "tool_call_1",
    "function": {
      "name": "get_weather",
      "arguments": "{ \"location\": \"San Francisco\" }",
    },
    "type": "function",
  })
}

///|
test "ChatCompletionMessageBuilder" {
  let builder = ChatCompletionMessageBuilder::new()
  builder.add_delta(@openai.chunk_choice_delta(content="I will call"))
  builder.add_delta(
    @openai.chunk_choice_delta(content=" the tool to get the weather."),
  )
  builder.add_delta(
    @openai.chunk_choice_delta(tool_calls=[
      @openai.chunk_choice_delta_tool_call(
        index=0,
        id="tool_call_1",
        function=@openai.chunk_choice_delta_tool_call_function(
          name="get_weather",
        ),
      ),
    ]),
  )
  builder.add_delta(
    @openai.chunk_choice_delta(tool_calls=[
      @openai.chunk_choice_delta_tool_call(
        index=0,
        function=@openai.chunk_choice_delta_tool_call_function(
          arguments=(
            #|{ "location
          ),
        ),
      ),
    ]),
  )
  builder.add_delta(
    @openai.chunk_choice_delta(tool_calls=[
      @openai.chunk_choice_delta_tool_call(
        index=0,
        function=@openai.chunk_choice_delta_tool_call_function(
          arguments=(
            #|": "San
          ),
        ),
      ),
    ]),
  )
  builder.add_delta(
    @openai.chunk_choice_delta(tool_calls=[
      @openai.chunk_choice_delta_tool_call(
        index=0,
        function=@openai.chunk_choice_delta_tool_call_function(
          arguments=(
            #| Francisco" }
          ),
        ),
      ),
    ]),
  )
  let message = builder.to_message()
  @json.inspect(message, content={
    "content": "I will call the tool to get the weather.",
    "role": "assistant",
    "tool_calls": [
      {
        "id": "tool_call_1",
        "function": {
          "name": "get_weather",
          "arguments": "{ \"location\": \"San Francisco\" }",
        },
        "type": "function",
      },
    ],
  })
}

///|
test "ChatCompletionBuilder" {
  let builder = ChatCompletionBuilder::new()
  builder.add_chunk(
    @openai.chunk(
      id="chatcmpl-123",
      created=1677652288,
      model="gpt-4o",
      choices=[
        @openai.chunk_choice(
          index=0,
          delta=@openai.chunk_choice_delta(
            content="Sure, I can",
            role=@openai.ChatCompletionRole::Assistant,
          ),
        ),
      ],
      system_fingerprint="fingerprint_abc",
      service_tier=@openai.ChatCompletionServiceTier::Flex,
    ),
  )
  builder.add_chunk(
    @openai.chunk(id="chatcmpl-123", created=1677652288, model="gpt-4o", choices=[
      @openai.chunk_choice(
        index=0,
        delta=@openai.chunk_choice_delta(
          content=" help with that.",
          role=@openai.ChatCompletionRole::Assistant,
        ),
      ),
    ]),
  )
  builder.add_chunk(
    @openai.chunk(id="chatcmpl-123", created=1677652288, model="gpt-4o", choices=[
      @openai.chunk_choice(
        index=0,
        delta=@openai.chunk_choice_delta(
          role=@openai.ChatCompletionRole::Assistant,
          tool_calls=[
            @openai.chunk_choice_delta_tool_call(
              index=0,
              id="tool_call_1",
              function=@openai.chunk_choice_delta_tool_call_function(
                name="get_weather",
              ),
            ),
          ],
        ),
      ),
    ]),
  )
  builder.add_chunk(
    @openai.chunk(id="chatcmpl-123", created=1677652288, model="gpt-4o", choices=[
      @openai.chunk_choice(
        index=0,
        delta=@openai.chunk_choice_delta(
          role=@openai.ChatCompletionRole::Assistant,
          tool_calls=[
            @openai.chunk_choice_delta_tool_call(
              index=0,
              function=@openai.chunk_choice_delta_tool_call_function(
                arguments=(
                  #|{ "location": "
                ),
              ),
            ),
          ],
        ),
      ),
    ]),
  )
  builder.add_chunk(
    @openai.chunk(
      id="chatcmpl-123",
      created=1677652288,
      model="gpt-4o",
      choices=[
        @openai.chunk_choice(
          index=0,
          delta=@openai.chunk_choice_delta(
            role=@openai.ChatCompletionRole::Assistant,
            tool_calls=[
              @openai.chunk_choice_delta_tool_call(
                index=0,
                function=@openai.chunk_choice_delta_tool_call_function(
                  arguments=(
                    #|San Francisco" }
                  ),
                ),
              ),
            ],
          ),
          finish_reason=@openai.ChatCompletionChoiceFinishReason::Stop,
        ),
      ],
      usage=@openai.CompletionUsage::new(
        prompt_tokens=10,
        completion_tokens=20,
        total_tokens=30,
        cost=0.002,
      ),
    ),
  )
  @json.inspect(builder.to_chat_completion(), content={
    "id": "chatcmpl-123",
    "choices": [
      {
        "index": 0,
        "message": {
          "content": "Sure, I can help with that.",
          "role": "assistant",
          "tool_calls": [
            {
              "id": "tool_call_1",
              "function": {
                "name": "get_weather",
                "arguments": "{ \"location\": \"San Francisco\" }",
              },
              "type": "function",
            },
          ],
        },
        "finish_reason": "stop",
      },
    ],
    "created": 1677652288,
    "model": "gpt-4o",
    "usage": {
      "completion_tokens": 20,
      "cost": 0.002,
      "prompt_tokens": 10,
      "total_tokens": 30,
    },
    "system_fingerprint": "fingerprint_abc",
    "service_tier": "flex",
  })
}
