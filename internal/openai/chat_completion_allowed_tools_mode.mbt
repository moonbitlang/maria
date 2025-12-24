///|
/// Constrains the tools available to the model to a pre-defined set.
///
/// `Auto` allows the model to pick from among the allowed tools and generate a message.
///
/// `Required` requires the model to call one or more of the allowed tools.
pub(all) enum ChatCompletionAllowedToolsMode {
  /// Allows the model to pick from among the allowed tools and generate a message.
  Auto
  /// Requires the model to call one or more of the allowed tools.
  Required
}
