///|
/// Constrains the tools available to the model to a pre-defined set.
pub(all) struct ChatCompletionAllowedTools {
  /// Constrains the tools available to the model to a pre-defined set.
  ///
  /// `Auto` allows the model to pick from among the allowed tools and generate a message.
  ///
  /// `Required` requires the model to call one or more of the allowed tools.
  mode : ChatCompletionAllowedToolsMode
  // /A list of tool definitions that the model should be allowed to call.
  /// For the Chat Completions API, the list of tool definitions might look like:
  tools : Array[ChatCompletionToolChoice]
}
