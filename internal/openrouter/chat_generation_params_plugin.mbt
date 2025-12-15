///|
enum ChatGenerationParamsPlugin {
  Moderation
  Web(ChatGenerationParamsPluginWeb)
  FileParser(ChatGenerationParamsPluginFileParser)
  ResponseHealing(ChatGenerationParamsPluginResponseHealing)
}
