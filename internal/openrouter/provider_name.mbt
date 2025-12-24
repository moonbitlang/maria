///|
pub(all) enum ProviderName {
  Ai21
  AionLabs
  Alibaba
  AmazonBedrock
  AmazonNova
  Anthropic
  ArceeAI
  AtlasCloud
  Avian
  Azure
  BaseTen
  BytePlus
  BlackForestLabs
  Cerebras
  Chutes
  Cirrascale
  Clarifai
  Cloudflare
  Cohere
  Crusoe
  DeepInfra
  DeepSeek
  Featherless
  Fireworks
  Friendli
  GMICloud
  GoPomelo
  Google
  GoogleAIStudio
  Groq
  Hyperbolic
  Inception
  InferenceNet
  Infermatic
  Inflection
  Liquid
  Mara
  Mancer2
  Minimax
  ModelRun
  Mistral
  Modular
  MoonshotAI
  Morph
  NCompass
  Nebius
  NextBit
  Novita
  Nvidia
  OpenAI
  OpenInference
  Parasail
  Perplexity
  Phala
  Relace
  SambaNova
  SiliconFlow
  Sourceful
  Stealth
  StreamLake
  Switchpoint
  Targon
  Together
  Venice
  WandB
  Xiaomi
  XAI
  ZAi
  FakeProvider
  /// Unknown provider name
  Unknown(String)
} derive(Show)

///|
pub fn ProviderName::to_string(self : ProviderName) -> String {
  match self {
    Ai21 => "AI21"
    AionLabs => "AionLabs"
    Alibaba => "Alibaba"
    AmazonBedrock => "Amazon Bedrock"
    AmazonNova => "Amazon Nova"
    Anthropic => "Anthropic"
    ArceeAI => "Arcee AI"
    AtlasCloud => "AtlasCloud"
    Avian => "Avian"
    Azure => "Azure"
    BaseTen => "BaseTen"
    BytePlus => "BytePlus"
    BlackForestLabs => "Black Forest Labs"
    Cerebras => "Cerebras"
    Chutes => "Chutes"
    Cirrascale => "Cirrascale"
    Clarifai => "Clarifai"
    Cloudflare => "Cloudflare"
    Cohere => "Cohere"
    Crusoe => "Crusoe"
    DeepInfra => "DeepInfra"
    DeepSeek => "DeepSeek"
    Featherless => "Featherless"
    Fireworks => "Fireworks"
    Friendli => "Friendli"
    GMICloud => "GMICloud"
    GoPomelo => "GoPomelo"
    Google => "Google"
    GoogleAIStudio => "Google AI Studio"
    Groq => "Groq"
    Hyperbolic => "Hyperbolic"
    Inception => "Inception"
    InferenceNet => "InferenceNet"
    Infermatic => "Infermatic"
    Inflection => "Inflection"
    Liquid => "Liquid"
    Mara => "Mara"
    Mancer2 => "Mancer 2"
    Minimax => "Minimax"
    ModelRun => "ModelRun"
    Mistral => "Mistral"
    Modular => "Modular"
    MoonshotAI => "Moonshot AI"
    Morph => "Morph"
    NCompass => "NCompass"
    Nebius => "Nebius"
    NextBit => "NextBit"
    Novita => "Novita"
    Nvidia => "Nvidia"
    OpenAI => "OpenAI"
    OpenInference => "OpenInference"
    Parasail => "Parasail"
    Perplexity => "Perplexity"
    Phala => "Phala"
    Relace => "Relace"
    SambaNova => "SambaNova"
    SiliconFlow => "SiliconFlow"
    Sourceful => "Sourceful"
    Stealth => "Stealth"
    StreamLake => "StreamLake"
    Switchpoint => "Switchpoint"
    Targon => "Targon"
    Together => "Together"
    Venice => "Venice"
    WandB => "WandB"
    Xiaomi => "Xiaomi"
    XAI => "xAI"
    ZAi => "Z.AI"
    FakeProvider => "FakeProvider"
    Unknown(name) => name
  }
}

///|
pub impl ToJson for ProviderName with to_json(self : ProviderName) -> Json {
  self.to_string().to_json()
}

///|
pub impl @json.FromJson for ProviderName with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ProviderName raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.ProviderName::from_json"
  guard json is String(name) else {
    raise @json.JsonDecodeError((path, "\{func_name}: expect string"))
  }
  match name {
    "AI21" => ProviderName::Ai21
    "AionLabs" => ProviderName::AionLabs
    "Alibaba" => ProviderName::Alibaba
    "Amazon Bedrock" => ProviderName::AmazonBedrock
    "Amazon Nova" => ProviderName::AmazonNova
    "Anthropic" => ProviderName::Anthropic
    "Arcee AI" => ProviderName::ArceeAI
    "AtlasCloud" => ProviderName::AtlasCloud
    "Avian" => ProviderName::Avian
    "Azure" => ProviderName::Azure
    "BaseTen" => ProviderName::BaseTen
    "BytePlus" => ProviderName::BytePlus
    "Black Forest Labs" => ProviderName::BlackForestLabs
    "Cerebras" => ProviderName::Cerebras
    "Chutes" => ProviderName::Chutes
    "Cirrascale" => ProviderName::Cirrascale
    "Clarifai" => ProviderName::Clarifai
    "Cloudflare" => ProviderName::Cloudflare
    "Cohere" => ProviderName::Cohere
    "Crusoe" => ProviderName::Crusoe
    "DeepInfra" => ProviderName::DeepInfra
    "DeepSeek" => ProviderName::DeepSeek
    "Featherless" => ProviderName::Featherless
    "Fireworks" => ProviderName::Fireworks
    "Friendli" => ProviderName::Friendli
    "GMICloud" => ProviderName::GMICloud
    "GoPomelo" => ProviderName::GoPomelo
    "Google" => ProviderName::Google
    "Google AI Studio" => ProviderName::GoogleAIStudio
    "Groq" => ProviderName::Groq
    "Hyperbolic" => ProviderName::Hyperbolic
    "Inception" => ProviderName::Inception
    "InferenceNet" => ProviderName::InferenceNet
    "Infermatic" => ProviderName::Infermatic
    "Inflection" => ProviderName::Inflection
    "Liquid" => ProviderName::Liquid
    "Mara" => ProviderName::Mara
    "Mancer 2" => ProviderName::Mancer2
    "Minimax" => ProviderName::Minimax
    "ModelRun" => ProviderName::ModelRun
    "Mistral" => ProviderName::Mistral
    "Modular" => ProviderName::Modular
    "Moonshot AI" => ProviderName::MoonshotAI
    "Morph" => ProviderName::Morph
    "NCompass" => ProviderName::NCompass
    "Nebius" => ProviderName::Nebius
    "NextBit" => ProviderName::NextBit
    "Novita" => ProviderName::Novita
    "Nvidia" => ProviderName::Nvidia
    "OpenAI" => ProviderName::OpenAI
    "OpenInference" => ProviderName::OpenInference
    "Parasail" => ProviderName::Parasail
    "Perplexity" => ProviderName::Perplexity
    "Phala" => ProviderName::Phala
    "Relace" => ProviderName::Relace
    "SambaNova" => ProviderName::SambaNova
    "SiliconFlow" => ProviderName::SiliconFlow
    "Sourceful" => ProviderName::Sourceful
    "Stealth" => ProviderName::Stealth
    "StreamLake" => ProviderName::StreamLake
    "Switchpoint" => ProviderName::Switchpoint
    "Targon" => ProviderName::Targon
    "Together" => ProviderName::Together
    "Venice" => ProviderName::Venice
    "WandB" => ProviderName::WandB
    "Xiaomi" => ProviderName::Xiaomi
    "xAI" => ProviderName::XAI
    "Z.AI" => ProviderName::ZAi
    "FakeProvider" => ProviderName::FakeProvider
    name => Unknown(name)
  }
}
