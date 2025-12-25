# Model Selection

Maria supports three model providers, each with different authentication methods and available models. This document explains how to select models and the fallback behavior when no model is explicitly specified.

## Model Providers

### 1. OpenRouter / OpenAI API

**Authentication**: Environment variable (`OPENROUTER_API_KEY` or `OPENAI_API_KEY`)

**Usage**: Specify the model name directly (e.g., `-m anthropic/claude-sonnet-4.5`)

**Available Models**:

| Model Name | Context Window | Prompt Caching |
|------------|----------------|----------------|
| `anthropic/claude-sonnet-4.5` | 200K | ✓ |
| `anthropic/claude-opus-4.5` | 200K | ✓ |
| `anthropic/claude-haiku-4.5` | 200K | ✓ |
| `openai/gpt-5` | 400K | ✗ |
| `openai/gpt-5-mini` | 400K | ✗ |
| `openai/gpt-5-nano` | 400K | ✗ |
| `openai/gpt-5-codex` | 400K | ✗ |
| `qwen/qwen3-coder-plus` | 128K | ✗ |
| `qwen/qwen3-coder-flash` | 128K | ✗ |
| `x-ai/grok-4-fast` | 2M | ✗ |
| `x-ai/grok-code-fast-1` | 256K | ✗ |
| `moonshotai/kimi-k2-0905` | 262K | ✗ |
| `z-ai/glm-4.6` | 202K | ✗ |
| `minimax/minimax-m2` | 204K | ✗ |
| `deepseek/deepseek-v3.2` | 200K | ✗ |

Any other model name will be passed through to OpenRouter with a default 128K context window.

### 2. Codex OAuth (ChatGPT Plus/Pro)

**Authentication**: Browser-based OAuth flow (credentials stored in `~/.moonagent/codex-credentials.json`)

**Usage**: Use the `codex/` prefix (e.g., `-m codex/gpt-5.2`)

**Available Models**:

| Model Name | Context Window |
|------------|----------------|
| `codex/gpt-5.2` | 400K |

When you specify a `codex/` model and no credentials are found, Maria will automatically open a browser for OAuth authentication.

### 3. GitHub Copilot

**Authentication**: GitHub Device Code flow (credentials stored in `~/.moonagent/copilot-credentials.json`)

**Usage**: Use the `copilot/` prefix (e.g., `-m copilot/claude-opus-4.5`)

**Available Models**:

#### OpenAI Models
| Model Name | Context Window |
|------------|----------------|
| `copilot/gpt-4.1` | 1M |
| `copilot/gpt-4o` | 128K |
| `copilot/gpt-5` | 400K |
| `copilot/gpt-5-mini` | 400K |
| `copilot/gpt-5-codex` | 400K |
| `copilot/gpt-5.1` | 400K |
| `copilot/gpt-5.1-codex` | 400K |
| `copilot/gpt-5.1-codex-max` | 400K |
| `copilot/gpt-5.1-codex-mini` | 400K |
| `copilot/gpt-5.2` | 400K |
| `copilot/o3` | 200K |
| `copilot/o3-mini` | 200K |
| `copilot/o4-mini` | 200K |

#### Anthropic Models
| Model Name | Context Window |
|------------|----------------|
| `copilot/claude-3.5-sonnet` | 200K |
| `copilot/claude-3.7-sonnet` | 200K |
| `copilot/claude-3.7-sonnet-thought` | 200K |
| `copilot/claude-haiku-4.5` | 200K |
| `copilot/claude-opus-4` | 200K |
| `copilot/claude-opus-4.5` | 200K |
| `copilot/claude-opus-41` | 200K |
| `copilot/claude-sonnet-4` | 200K |
| `copilot/claude-sonnet-4.5` | 200K |

#### Google Models
| Model Name | Context Window |
|------------|----------------|
| `copilot/gemini-2.0-flash-001` | 1M |
| `copilot/gemini-2.5-pro` | 1M |
| `copilot/gemini-3-flash-preview` | 1M |
| `copilot/gemini-3-pro-preview` | 1M |

#### xAI Models
| Model Name | Context Window |
|------------|----------------|
| `copilot/grok-code-fast-1` | 256K |

When you specify a `copilot/` model and no credentials are found, Maria will automatically guide you through the GitHub Device Code authentication flow.

## Configuration File

You can also define custom models in a configuration file. Maria looks for models in:

1. `<project>/.moonagent/models/models.json` (project-specific)
2. `~/.moonagent/models/models.json` (user-wide)

Example configuration:

```json
[
  {
    "name": "my-custom-model",
    "model_name": "anthropic/claude-sonnet-4.5",
    "model_type": "saas/openai",
    "api_key": "your-api-key",
    "base_url": "https://openrouter.ai/api/v1",
    "safe_zone_tokens": 200000
  }
]
```

## Fallback Rules

When no model is explicitly specified (`-m` flag omitted), Maria attempts to find an available model in the following order:

```
1. Check configuration files
   └─ If models.json exists and contains models → use first model

2. Check OpenRouter/OpenAI API key
   └─ If OPENROUTER_API_KEY or OPENAI_API_KEY is set → use anthropic/claude-sonnet-4.5

3. Check Codex OAuth credentials (without auto-login)
   └─ If ~/.moonagent/codex-credentials.json exists and valid → use codex/gpt-5.2

4. Check Copilot credentials (without auto-login)
   └─ If ~/.moonagent/copilot-credentials.json exists and valid → use copilot/claude-sonnet-4.5

5. No model available
   └─ Display error message and exit
```

**Important**: During fallback, Maria will **not** automatically open a browser for OAuth authentication. Auto-login only occurs when you explicitly request a `codex/` or `copilot/` model.

## Examples

```bash
# Use a specific OpenRouter model
maria -m anthropic/claude-opus-4.5

# Use Codex OAuth (will prompt for login if needed)
maria -m codex/gpt-5.2

# Use GitHub Copilot (will prompt for login if needed)
maria -m copilot/claude-sonnet-4.5
```
