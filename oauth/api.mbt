///|
pub enum Role {
  User
  Assistant
  System
} derive(Show)

///|
pub impl ToJson for Role with to_json(self : Role) -> Json {
  match self {
    User => "user"
    Assistant => "assistant"
    System => "system"
  }
}

///|
pub impl @json.FromJson for Role with from_json(
  json : Json,
  path : @json.JsonPath,
) -> Role raise @json.JsonDecodeError {
  guard json is String(s) else {
    raise @json.JsonDecodeError((path, "Role: expected string"))
  }
  match s {
    "user" => User
    "assistant" => Assistant
    "system" => System
    _ => raise @json.JsonDecodeError((path, "Role: invalid value '\{s}'"))
  }
}

///|
pub enum ContentType {
  InputText
  OutputText
  Text
} derive(Show)

///|
pub impl ToJson for ContentType with to_json(self : ContentType) -> Json {
  match self {
    InputText => "input_text"
    OutputText => "output_text"
    Text => "text"
  }
}

///|
pub impl @json.FromJson for ContentType with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ContentType raise @json.JsonDecodeError {
  guard json is String(s) else {
    raise @json.JsonDecodeError((path, "ContentType: expected string"))
  }
  match s {
    "input_text" => InputText
    "output_text" => OutputText
    "text" => Text
    _ =>
      raise @json.JsonDecodeError((path, "ContentType: invalid value '\{s}'"))
  }
}

///|
pub struct ContentPart {
  type_ : ContentType
  text : String
} derive(Show)

///|
pub fn ContentPart::new(type_~ : ContentType, text~ : String) -> ContentPart {
  { type_, text }
}

///|
pub impl ToJson for ContentPart with to_json(self : ContentPart) -> Json {
  { "type": self.type_, "text": self.text }
}

///|
pub impl @json.FromJson for ContentPart with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ContentPart raise @json.JsonDecodeError {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "ContentPart: expected object"))
  }
  let type_ : ContentType = match obj.get("type") {
    Some(v) => @json.from_json(v, path=path.add_key("type"))
    None => raise @json.JsonDecodeError((path, "ContentPart: missing 'type'"))
  }
  let text : String = match obj.get("text") {
    Some(String(s)) => s
    Some(_) =>
      raise @json.JsonDecodeError((path, "ContentPart: 'text' must be string"))
    None => raise @json.JsonDecodeError((path, "ContentPart: missing 'text'"))
  }
  { type_, text }
}

///|
pub struct InputItem {
  type_ : String
  role : Role
  content : Array[ContentPart]
} derive(Show)

///|
pub fn InputItem::new(
  type_~ : String,
  role~ : Role,
  content~ : Array[ContentPart],
) -> InputItem {
  { type_, role, content }
}

///|
pub impl ToJson for InputItem with to_json(self : InputItem) -> Json {
  { "type": self.type_, "role": self.role, "content": self.content }
}

///|
pub struct ResponsesRequest {
  model : String
  input : Array[InputItem]
  instructions : String
  stream : Bool?
  store : Bool?
} derive(Show)

///|
pub fn ResponsesRequest::new(
  model~ : String,
  input~ : Array[InputItem],
  instructions~ : String,
  stream? : Bool,
  store? : Bool,
) -> ResponsesRequest {
  { model, input, instructions, stream, store }
}

///|
pub impl ToJson for ResponsesRequest with to_json(self : ResponsesRequest) -> Json {
  let obj : Map[String, Json] = {
    "model": self.model.to_json(),
    "input": self.input.to_json(),
    "instructions": self.instructions.to_json(),
  }
  if self.stream is Some(v) {
    obj["stream"] = v.to_json()
  }
  if self.store is Some(v) {
    obj["store"] = v.to_json()
  }
  Json::object(obj)
}

///|
pub suberror ApiError {
  ApiError(code~ : Int, message~ : String)
} derive(Show)

///|
pub struct StreamCallbacks {
  on_chunk : (String) -> Unit
  on_complete : () -> Unit
  on_error : (Error) -> Unit
}

///|
pub fn StreamCallbacks::new(
  on_chunk~ : (String) -> Unit,
  on_complete~ : () -> Unit,
  on_error~ : (Error) -> Unit,
) -> StreamCallbacks {
  { on_chunk, on_complete, on_error }
}

///|
async fn ensure_credentials() -> Credentials raise Error {
  load_credentials() catch {
    ParseError(x) => raise ParseError(x)
    _ => raise ParseError("Failed to load credentials")
  }
}

///|
priv struct ResponseChunkReader(&@io.Reader)

///|
fn ResponseChunkReader::new(reader : &@io.Reader) -> ResponseChunkReader {
  ResponseChunkReader(reader)
}

///|
async fn ResponseChunkReader::read(self : ResponseChunkReader) -> String? {
  for {
    guard self.0.read_until("\n") is Some(line) else { return None }
    guard line is [.. "data: ", .. rest] else { continue }
    let data = rest.trim_space().to_string()
    if data == "[DONE]" {
      return None
    }
    try {
      let json = @json.parse(data)
      guard json is Object(obj) else { continue }
      if obj.get("type") is Some(String("response.output_text.delta")) {
        if obj.get("delta") is Some(String(delta)) {
          return Some(delta)
        }
      }
      if obj.get("type") is Some(String("response.content_part.delta")) {
        if obj.get("delta") is Some(Object(delta_obj)) {
          if delta_obj.get("text") is Some(String(text)) {
            return Some(text)
          }
        }
      }
      continue
    } catch {
      _ => continue
    }
  }
}

///|
pub async fn stream_responses(
  request : ResponsesRequest,
  callbacks : StreamCallbacks,
) -> Unit {
  try {
    let credentials = ensure_credentials()
    do_stream_request(credentials, request, callbacks)
  } catch {
    error => (callbacks.on_error)(error)
  }
}

///|
async fn do_stream_request(
  credentials : Credentials,
  request : ResponsesRequest,
  callbacks : StreamCallbacks,
) -> Unit {
  try {
    let client = @http.Client::new(CODEX_API_HOST, headers={
      "Authorization": "Bearer \{credentials.accessToken}",
      "ChatGPT-Account-ID": credentials.accountId,
      "Content-Type": "application/json",
      "Accept": "text/event-stream",
      "originator": "codex_cli_rs",
      "User-Agent": "codex_cli_rs/1.0.0",
    })
    defer client.close()
    let body = request.to_json()
    guard body is Object(body_obj) else {
      (callbacks.on_error)(ApiError(code=500, message="Invalid request body"))
      return
    }
    body_obj["stream"] = true
    let response = client.post(
      "\{CODEX_API_PATH}/responses",
      Json::object(body_obj),
    )
    guard response.code is (200..=299) else {
      let error_text = client.read_all().text()
      (callbacks.on_error)(
        ApiError(
          code=response.code,
          message="API request failed: \{error_text}",
        ),
      )
      return
    }
    let reader = ResponseChunkReader::new(client)
    while reader.read() is Some(chunk) {
      (callbacks.on_chunk)(chunk)
    }
    (callbacks.on_complete)()
  } catch {
    error => (callbacks.on_error)(error)
  }
}

///|
pub async fn call_responses(request : ResponsesRequest) -> Json raise Error {
  let credentials = ensure_credentials()
  let client = @http.Client::new(CODEX_API_HOST, headers={
    "Authorization": "Bearer \{credentials.accessToken}",
    "ChatGPT-Account-ID": credentials.accountId,
    "Content-Type": "application/json",
    "originator": "codex_cli_rs",
    "User-Agent": "codex_cli_rs/1.0.0",
  })
  defer client.close()
  let body = request.to_json()
  guard body is Object(body_obj) else {
    raise ApiError(code=500, message="Invalid request body")
  }
  body_obj["stream"] = false
  let response = client.post(
    "\{CODEX_API_PATH}/responses",
    Json::object(body_obj),
  )
  guard response.code is (200..=299) else {
    let error_text = client.read_all().text()
    raise ApiError(
      code=response.code,
      message="API request failed: \{error_text}",
    )
  }
  let response_body = client.read_all().text()
  @json.parse(response_body)
}

///|
const BASE_INSTRUCTIONS : String =
  #|You are Codex, based on GPT-5. You are running as a coding agent in the Codex CLI on a user's computer.
  #|
  #|## General
  #|
  #|- When searching for text or files, prefer using `rg` or `rg --files` respectively because `rg` is much faster than alternatives like `grep`. (If the `rg` command is not found, then use alternatives.)
  #|
  #|## Editing constraints
  #|
  #|- Default to ASCII when editing or creating files. Only introduce non-ASCII or other Unicode characters when there is a clear justification and the file already uses them.
  #|- Add succinct code comments that explain what is going on if code is not self-explanatory. You should not add comments like "Assigns the value to the variable", but a brief comment might be useful ahead of a complex code block that the user would otherwise have to spend time parsing out. Usage of these comments should be rare.
  #|- Try to use apply_patch for single file edits, but it is fine to explore other options to make the edit if it does not work well. Do not use apply_patch for changes that are auto-generated (i.e. generating package.json or running a lint or format command like gofmt) or when scripting is more efficient (such as search and replacing a string across a codebase).
  #|- You may be in a dirty git worktree.
  #|    * NEVER revert existing changes you did not make unless explicitly requested, since these changes were made by the user.
  #|    * If asked to make a commit or code edits and there are unrelated changes to your work or changes that you didn't make in those files, don't revert those changes.
  #|    * If the changes are in files you've touched recently, you should read carefully and understand how you can work with the changes rather than reverting them.
  #|    * If the changes are in unrelated files, just ignore them and don't revert them.
  #|- Do not amend a commit unless explicitly requested to do so.
  #|- While you are working, you might notice unexpected changes that you didn't make. If this happens, STOP IMMEDIATELY and ask the user how they would like to proceed.
  #|- **NEVER** use destructive commands like `git reset --hard` or `git checkout --` unless specifically requested or approved by the user.
  #|
  #|## Plan tool
  #|
  #|When using the planning tool:
  #|- Skip using the planning tool for straightforward tasks (roughly the easiest 25%).
  #|- Do not make single-step plans.
  #|- When you made a plan, update it after having performed one of the sub-tasks that you shared on the plan.
  #|
  #|## Codex CLI harness, sandboxing, and approvals
  #|
  #|The Codex CLI harness supports several different configurations for sandboxing and escalation approvals that the user can choose from.
  #|
  #|Filesystem sandboxing defines which files can be read or written. The options for `sandbox_mode` are:
  #|- **read-only**: The sandbox only permits reading files.
  #|- **workspace-write**: The sandbox permits reading files, and editing files in `cwd` and `writable_roots`. Editing files in other directories requires approval.
  #|- **danger-full-access**: No filesystem sandboxing - all commands are permitted.
  #|
  #|Network sandboxing defines whether network can be accessed without approval. Options for `network_access` are:
  #|- **restricted**: Requires approval
  #|- **enabled**: No approval needed
  #|
  #|Approvals are your mechanism to get user consent to run shell commands without the sandbox. Possible configuration options for `approval_policy` are
  #|- **untrusted**: The harness will escalate most commands for user approval, apart from a limited allowlist of safe "read" commands.
  #|- **on-failure**: The harness will allow all commands to run in the sandbox (if enabled), and failures will be escalated to the user for approval to run again without the sandbox.
  #|- **on-request**: Commands will be run in the sandbox by default, and you can specify in your tool call if you want to escalate a command to run without sandboxing. (Note that this mode is not always available. If it is, you'll see parameters for it in the `shell` command description.)
  #|- **never**: This is a non-interactive mode where you may NEVER ask the user for approval to run commands. Instead, you must always persist and work around constraints to solve the task for the user. You MUST do your utmost best to finish the task and validate your work before yielding. If this mode is paired with `danger-full-access`, take advantage of it to deliver the best outcome for the user. Further, in this mode, your default testing philosophy is overridden: Even if you don't see local patterns for testing, you may add tests and scripts to validate your work. Just remove them before yielding.
  #|
  #|When you are running with `approval_policy == on-request`, and sandboxing enabled, here are scenarios where you'll need to request approval:
  #|- You need to run a command that writes to a directory that requires it (e.g. running tests that write to /var)
  #|- You need to run a GUI app (e.g., open/xdg-open/osascript) to open browsers or files.
  #|- You are running sandboxed and need to run a command that requires network access (e.g. installing packages)
  #|- If you run a command that is important to solving the user's query, but it fails because of sandboxing, rerun the command with approval. ALWAYS proceed to use the `sandbox_permissions` and `justification` parameters - do not message the user before requesting approval for the command.
  #|- You are about to take a potentially destructive action such as an `rm` or `git reset` that the user did not explicitly ask for
  #|- (for all of these, you should weigh alternative paths that do not require approval)
  #|
  #|When `sandbox_mode` is set to read-only, you'll need to request approval for any command that isn't a read.
  #|
  #|You will be told what filesystem sandboxing, network sandboxing, and approval mode are active in a developer or user message. If you are not told about this, assume that you are running with workspace-write, network sandboxing enabled, and approval on-failure.
  #|
  #|Although they introduce friction to the user because your work is paused until the user responds, you should leverage them when necessary to accomplish important work. If the completing the task requires escalated permissions, Do not let these settings or the sandbox deter you from attempting to accomplish the user's task unless it is set to "never", in which case never ask for approvals.
  #|
  #|When requesting approval to execute a command that will require escalated privileges:
  #|  - Provide the `sandbox_permissions` parameter with the value `"require_escalated"`
  #|  - Include a short, 1 sentence explanation for why you need escalated permissions in the justification parameter
  #|
  #|## Special user requests
  #|
  #|- If the user makes a simple request (such as asking for the time) which you can fulfill by running a terminal command (such as `date`), you should do so.
  #|- If the user asks for a "review", default to a code review mindset: prioritise identifying bugs, risks, behavioural regressions, and missing tests. Findings must be the primary focus of the response - keep summaries or overviews brief and only after enumerating the issues. Present findings first (ordered by severity with file/line references), follow with open questions or assumptions, and offer a change-summary only as a secondary detail. If no findings are discovered, state that explicitly and mention any residual risks or testing gaps.
  #|
  #|## Frontend tasks
  #|When doing frontend design tasks, avoid collapsing into "AI slop" or safe, average-looking layouts.
  #|Aim for interfaces that feel intentional, bold, and a bit surprising.
  #|- Typography: Use expressive, purposeful fonts and avoid default stacks (Inter, Roboto, Arial, system).
  #|- Color & Look: Choose a clear visual direction; define CSS variables; avoid purple-on-white defaults. No purple bias or dark mode bias.
  #|- Motion: Use a few meaningful animations (page-load, staggered reveals) instead of generic micro-motions.
  #|- Background: Don't rely on flat, single-color backgrounds; use gradients, shapes, or subtle patterns to build atmosphere.
  #|- Overall: Avoid boilerplate layouts and interchangeable UI patterns. Vary themes, type families, and visual languages across outputs.
  #|- Ensure the page loads properly on both desktop and mobile
  #|
  #|Exception: If working within an existing website or design system, preserve the established patterns, structure, and visual language.
  #|
  #|## Presenting your work and final message
  #|
  #|You are producing plain text that will later be styled by the CLI. Follow these rules exactly. Formatting should make results easy to scan, but not feel mechanical. Use judgment to decide how much structure adds value.
  #|
  #|- Default: be very concise; friendly coding teammate tone.
  #|- Ask only when needed; suggest ideas; mirror the user's style.
  #|- For substantial work, summarize clearly; follow final-answer formatting.
  #|- Skip heavy formatting for simple confirmations.
  #|- Don't dump large files you've written; reference paths only.
  #|- No "save/copy this file" - User is on the same machine.
  #|- Offer logical next steps (tests, commits, build) briefly; add verify steps if you couldn't do something.
  #|- For code changes:
  #|  * Lead with a quick explanation of the change, and then give more details on the context covering where and why a change was made. Do not start this explanation with "summary", just jump right in.
  #|  * If there are natural next steps the user may want to take, suggest them at the end of your response. Do not make suggestions if there are no natural next steps.
  #|  * When suggesting multiple options, use numeric lists for the suggestions so the user can quickly respond with a single number.
  #|- The user does not command execution outputs. When asked to show the output of a command (e.g. `git show`), relay the important details in your answer or summarize the key lines so the user understands the result.
  #|
  #|### Final answer structure and style guidelines
  #|
  #|- Plain text; CLI handles styling. Use structure only when it helps scanability.
  #|- Headers: optional; short Title Case (1-3 words) wrapped in **...**; no blank line before the first bullet; add only if they truly help.
  #|- Bullets: use - ; merge related points; keep to one line when possible; 4-6 per list ordered by importance; keep phrasing consistent.
  #|- Monospace: backticks for commands/paths/env vars/code ids and inline examples; use for literal keyword bullets; never combine with **.
  #|- Code samples or multi-line snippets should be wrapped in fenced code blocks; include an info string as often as possible.
  #|- Structure: group related bullets; order sections general -> specific -> supporting; for subsections, start with a bolded keyword bullet, then items; match complexity to the task.
  #|- Tone: collaborative, concise, factual; present tense, active voice; self-contained; no "above/below"; parallel wording.
  #|- Don'ts: no nested bullets/hierarchies; no ANSI codes; don't cram unrelated keywords; keep keyword lists short-wrap/reformat if long; avoid naming formatting styles in answers.
  #|- Adaptation: code explanations -> precise, structured with code refs; simple tasks -> lead with outcome; big changes -> logical walkthrough + rationale + next actions; casual one-offs -> plain sentences, no headers/bullets.
  #|- File References: When referencing files in your response follow the below rules:
  #|  * Use inline code to make file paths clickable.
  #|  * Each reference should have a stand alone path. Even if it's the same file.
  #|  * Accepted: absolute, workspace-relative, a/ or b/ diff prefixes, or bare filename/suffix.
  #|  * Optionally include line/column (1-based): :line[:column] or #Lline[Ccolumn] (column defaults to 1).
  #|  * Do not use URIs like file://, vscode://, or https://.
  #|  * Do not provide range of lines
  #|  * Examples: src/app.ts, src/app.ts:42, b/server/index.js#L10, C:\repo\project\main.rs:12:5

///|
pub async fn chat(message : String, model? : String = "gpt-5.2") -> String {
  let result = Ref::new("")
  let done = Ref::new(false)
  let error_ref : Ref[Error?] = Ref::new(None)
  stream_responses(
    {
      model,
      input: [
        {
          type_: "message",
          role: User,
          content: [{ type_: InputText, text: message }],
        },
      ],
      instructions: BASE_INSTRUCTIONS,
      store: Some(false),
      stream: None,
    },
    {
      on_chunk: fn(chunk) { result.val = result.val + chunk },
      on_complete: fn() { done.val = true },
      on_error: fn(err) { error_ref.val = Some(err) },
    },
  )
  if error_ref.val is Some(err) {
    raise err
  }
  result.val
}

///|
pub fn user_message(text : String) -> InputItem {
  { type_: "message", role: User, content: [{ type_: InputText, text }] }
}

///|
pub fn system_message(text : String) -> InputItem {
  { type_: "message", role: System, content: [{ type_: InputText, text }] }
}

///|
pub fn assistant_message(text : String) -> InputItem {
  { type_: "message", role: Assistant, content: [{ type_: OutputText, text }] }
}
