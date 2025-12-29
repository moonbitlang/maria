///|
pub(all) enum ResponseStreamEvent {
  AudioDelta(ResponseAudioDeltaEvent)
  AudioDone(ResponseAudioDoneEvent)
  AudioTranscriptDelta(ResponseAudioTranscriptDeltaEvent)
  AudioTranscriptDone(ResponseAudioTranscriptDoneEvent)
  CodeInterpreterCallCodeDelta(ResponseCodeInterpreterCallCodeDeltaEvent)
  CodeInterpreterCallCodeDone(ResponseCodeInterpreterCallCodeDoneEvent)
  CodeInterpreterCallCompleted(ResponseCodeInterpreterCallCompletedEvent)
  CodeInterpreterCallInProgress(ResponseCodeInterpreterCallInProgressEvent)
  CodeInterpreterCallInterpreting(ResponseCodeInterpreterCallInterpretingEvent)
  Completed(ResponseCompletedEvent)
  ContentPartAdded(ResponseContentPartAddedEvent)
  ContentPartDone(ResponseContentPartDoneEvent)
  Created(ResponseCreatedEvent)
  CustomToolCallInputDelta(ResponseCustomToolCallInputDeltaEvent)
  CustomToolCallInputDone(ResponseCustomToolCallInputDoneEvent)
  Error(ResponseErrorEvent)
  FileSearchCallCompleted(ResponseFileSearchCallCompletedEvent)
  FileSearchCallInProgress(ResponseFileSearchCallInProgressEvent)
  FileSearchCallSearching(ResponseFileSearchCallSearchingEvent)
  FunctionCallArgumentsDelta(ResponseFunctionCallArgumentsDeltaEvent)
  FunctionCallArgumentsDone(ResponseFunctionCallArgumentsDoneEvent)
  InProgress(ResponseInProgressEvent)
  Failed(ResponseFailedEvent)
  Incomplete(ResponseIncompleteEvent)
  OutputItemAdded(ResponseOutputItemAddedEvent)
  OutputItemDone(ResponseOutputItemDoneEvent)
  OutputTextAnnotationAdded(ResponseOutputTextAnnotationAddedEvent)
  OutputTextDelta(ResponseTextDeltaEvent)
  OutputTextDone(ResponseTextDoneEvent)
  Queued(ResponseQueuedEvent)
  ReasoningSummaryPartAdded(ResponseReasoningSummaryPartAddedEvent)
  ReasoningSummaryPartDone(ResponseReasoningSummaryPartDoneEvent)
  ReasoningSummaryTextDelta(ResponseReasoningSummaryTextDeltaEvent)
  ReasoningSummaryTextDone(ResponseReasoningSummaryTextDoneEvent)
  ReasoningTextDelta(ResponseReasoningTextDeltaEvent)
  ReasoningTextDone(ResponseReasoningTextDoneEvent)
  RefusalDelta(ResponseRefusalDeltaEvent)
  RefusalDone(ResponseRefusalDoneEvent)
  WebSearchCallCompleted(ResponseWebSearchCallCompletedEvent)
  WebSearchCallInProgress(ResponseWebSearchCallInProgressEvent)
  WebSearchCallSearching(ResponseWebSearchCallSearchingEvent)
  ImageGenerationCallCompleted(ResponseImageGenCallCompletedEvent)
  ImageGenerationCallGenerating(ResponseImageGenCallGeneratingEvent)
  ImageGenerationCallInProgress(ResponseImageGenCallInProgressEvent)
  ImageGenerationCallPartialImage(ResponseImageGenCallPartialImageEvent)
  McpCallArgumentsDelta(ResponseMcpCallArgumentsDeltaEvent)
  McpCallArgumentsDone(ResponseMcpCallArgumentsDoneEvent)
  McpCallCompleted(ResponseMcpCallCompletedEvent)
  McpCallFailed(ResponseMcpCallFailedEvent)
  McpCallInProgress(ResponseMcpCallInProgressEvent)
  McpListToolsCompleted(ResponseMcpListToolsCompletedEvent)
  McpListToolsFailed(ResponseMcpListToolsFailedEvent)
  McpListToolsInProgress(ResponseMcpListToolsInProgressEvent)
}

///|
pub impl ToJson for ResponseStreamEvent with to_json(self : ResponseStreamEvent) -> Json {
  match self {
    AudioDelta(event) => event.to_json()
    AudioDone(event) => event.to_json()
    AudioTranscriptDelta(event) => event.to_json()
    AudioTranscriptDone(event) => event.to_json()
    CodeInterpreterCallCodeDelta(event) => event.to_json()
    CodeInterpreterCallCodeDone(event) => event.to_json()
    CodeInterpreterCallCompleted(event) => event.to_json()
    CodeInterpreterCallInProgress(event) => event.to_json()
    CodeInterpreterCallInterpreting(event) => event.to_json()
    Completed(event) => event.to_json()
    ContentPartAdded(event) => event.to_json()
    ContentPartDone(event) => event.to_json()
    Created(event) => event.to_json()
    CustomToolCallInputDelta(event) => event.to_json()
    CustomToolCallInputDone(event) => event.to_json()
    Error(event) => event.to_json()
    FileSearchCallCompleted(event) => event.to_json()
    FileSearchCallInProgress(event) => event.to_json()
    FileSearchCallSearching(event) => event.to_json()
    FunctionCallArgumentsDelta(event) => event.to_json()
    FunctionCallArgumentsDone(event) => event.to_json()
    InProgress(event) => event.to_json()
    Failed(event) => event.to_json()
    Incomplete(event) => event.to_json()
    OutputItemAdded(event) => event.to_json()
    OutputItemDone(event) => event.to_json()
    OutputTextAnnotationAdded(event) => event.to_json()
    OutputTextDelta(event) => event.to_json()
    OutputTextDone(event) => event.to_json()
    Queued(event) => event.to_json()
    ReasoningSummaryPartAdded(event) => event.to_json()
    ReasoningSummaryPartDone(event) => event.to_json()
    ReasoningSummaryTextDelta(event) => event.to_json()
    ReasoningSummaryTextDone(event) => event.to_json()
    ReasoningTextDelta(event) => event.to_json()
    ReasoningTextDone(event) => event.to_json()
    RefusalDelta(event) => event.to_json()
    RefusalDone(event) => event.to_json()
    WebSearchCallCompleted(event) => event.to_json()
    WebSearchCallInProgress(event) => event.to_json()
    WebSearchCallSearching(event) => event.to_json()
    ImageGenerationCallCompleted(event) => event.to_json()
    ImageGenerationCallGenerating(event) => event.to_json()
    ImageGenerationCallInProgress(event) => event.to_json()
    ImageGenerationCallPartialImage(event) => event.to_json()
    McpCallArgumentsDelta(event) => event.to_json()
    McpCallArgumentsDone(event) => event.to_json()
    McpCallCompleted(event) => event.to_json()
    McpCallFailed(event) => event.to_json()
    McpCallInProgress(event) => event.to_json()
    McpListToolsCompleted(event) => event.to_json()
    McpListToolsFailed(event) => event.to_json()
    McpListToolsInProgress(event) => event.to_json()
  }
}

///|
pub impl @json.FromJson for ResponseStreamEvent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseStreamEvent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let type_str : String = object.required("type", path~)
  match type_str {
    "response.audio.delta" => AudioDelta(@json.from_json(json, path~))
    "response.audio.done" => AudioDone(@json.from_json(json, path~))
    "response.audio.transcript.delta" =>
      AudioTranscriptDelta(@json.from_json(json, path~))
    "response.audio.transcript.done" =>
      AudioTranscriptDone(@json.from_json(json, path~))
    "response.code_interpreter_call_code.delta" =>
      CodeInterpreterCallCodeDelta(@json.from_json(json, path~))
    "response.code_interpreter_call_code.done" =>
      CodeInterpreterCallCodeDone(@json.from_json(json, path~))
    "response.code_interpreter_call.completed" =>
      CodeInterpreterCallCompleted(@json.from_json(json, path~))
    "response.code_interpreter_call.in_progress" =>
      CodeInterpreterCallInProgress(@json.from_json(json, path~))
    "response.code_interpreter_call.interpreting" =>
      CodeInterpreterCallInterpreting(@json.from_json(json, path~))
    "response.completed" => Completed(@json.from_json(json, path~))
    "response.content_part.added" =>
      ContentPartAdded(@json.from_json(json, path~))
    "response.content_part.done" =>
      ContentPartDone(@json.from_json(json, path~))
    "response.created" => Created(@json.from_json(json, path~))
    "response.custom_tool_call_input.delta" =>
      CustomToolCallInputDelta(@json.from_json(json, path~))
    "response.custom_tool_call_input.done" =>
      CustomToolCallInputDone(@json.from_json(json, path~))
    "error" => Error(@json.from_json(json, path~))
    "response.file_search_call.completed" =>
      FileSearchCallCompleted(@json.from_json(json, path~))
    "response.file_search_call.in_progress" =>
      FileSearchCallInProgress(@json.from_json(json, path~))
    "response.file_search_call.searching" =>
      FileSearchCallSearching(@json.from_json(json, path~))
    "response.function_call_arguments.delta" =>
      FunctionCallArgumentsDelta(@json.from_json(json, path~))
    "response.function_call_arguments.done" =>
      FunctionCallArgumentsDone(@json.from_json(json, path~))
    "response.in_progress" => InProgress(@json.from_json(json, path~))
    "response.failed" => Failed(@json.from_json(json, path~))
    "response.incomplete" => Incomplete(@json.from_json(json, path~))
    "response.output_item.added" =>
      OutputItemAdded(@json.from_json(json, path~))
    "response.output_item.done" => OutputItemDone(@json.from_json(json, path~))
    "response.output_text.annotation.added" =>
      OutputTextAnnotationAdded(@json.from_json(json, path~))
    "response.output_text.delta" =>
      OutputTextDelta(@json.from_json(json, path~))
    "response.output_text.done" => OutputTextDone(@json.from_json(json, path~))
    "response.queued" => Queued(@json.from_json(json, path~))
    "response.reasoning_summary_part.added" =>
      ReasoningSummaryPartAdded(@json.from_json(json, path~))
    "response.reasoning_summary_part.done" =>
      ReasoningSummaryPartDone(@json.from_json(json, path~))
    "response.reasoning_summary_text.delta" =>
      ReasoningSummaryTextDelta(@json.from_json(json, path~))
    "response.reasoning_summary_text.done" =>
      ReasoningSummaryTextDone(@json.from_json(json, path~))
    "response.reasoning_text.delta" =>
      ReasoningTextDelta(@json.from_json(json, path~))
    "response.reasoning_text.done" =>
      ReasoningTextDone(@json.from_json(json, path~))
    "response.refusal.delta" => RefusalDelta(@json.from_json(json, path~))
    "response.refusal.done" => RefusalDone(@json.from_json(json, path~))
    "response.web_search_call.completed" =>
      WebSearchCallCompleted(@json.from_json(json, path~))
    "response.web_search_call.in_progress" =>
      WebSearchCallInProgress(@json.from_json(json, path~))
    "response.web_search_call.searching" =>
      WebSearchCallSearching(@json.from_json(json, path~))
    "response.image_generation_call.completed" =>
      ImageGenerationCallCompleted(@json.from_json(json, path~))
    "response.image_generation_call.generating" =>
      ImageGenerationCallGenerating(@json.from_json(json, path~))
    "response.image_generation_call.in_progress" =>
      ImageGenerationCallInProgress(@json.from_json(json, path~))
    "response.image_generation_call.partial_image" =>
      ImageGenerationCallPartialImage(@json.from_json(json, path~))
    "response.mcp_call_arguments.delta" =>
      McpCallArgumentsDelta(@json.from_json(json, path~))
    "response.mcp_call_arguments.done" =>
      McpCallArgumentsDone(@json.from_json(json, path~))
    "response.mcp_call.completed" =>
      McpCallCompleted(@json.from_json(json, path~))
    "response.mcp_call.failed" => McpCallFailed(@json.from_json(json, path~))
    "response.mcp_call.in_progress" =>
      McpCallInProgress(@json.from_json(json, path~))
    "response.mcp_list_tools.completed" =>
      McpListToolsCompleted(@json.from_json(json, path~))
    "response.mcp_list_tools.failed" =>
      McpListToolsFailed(@json.from_json(json, path~))
    "response.mcp_list_tools.in_progress" =>
      McpListToolsInProgress(@json.from_json(json, path~))
    _ =>
      raise @json.JsonDecodeError(
        (
          path.add_key("type"),
          "ResponseStreamEvent: invalid type '\{type_str}'",
        ),
      )
  }
}
