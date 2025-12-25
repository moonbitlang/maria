///|
/// Controls which (if any) tool is called by the model. `None` means the model
/// will not call any tool and instead generates a message. `Auto` means the
/// model can pick between generating a message or calling one or more tools.
/// `Required` means the model must call one or more tools. Specifying a
/// particular tool via `Function({ name: "my_function" })` forces the model to
/// call that tool.
///
/// `None` is the default when no tools are present. `Auto` is the default if
/// tools are present.
pub(all) enum ChatCompletionToolChoice {
  Disallow
  Auto
  Required
  AllowedTools(ChatCompletionAllowedTools)
  Function(ChatCompletionFunctionToolChoice)
  Custom(ChatCompletionCustomToolChoice)
}
