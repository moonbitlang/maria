///|
/// Sets the system prompt for the agent's conversation history and emits an
/// event notification.
///
/// Parameters:
///
/// * `agent` : The agent instance whose system prompt will be set.
/// * `prompt` : The system prompt text to be set for the agent's conversation.
pub fn Agent::set_system_prompt(agent : Agent, prompt : String?) -> Unit {
  agent.history.set_system_prompt(prompt)
  agent.emit(SystemPromptSet(prompt))
}

///|
/// Retrieves the current system prompt from the agent's conversation history.
pub fn Agent::system_prompt(agent : Agent) -> String? {
  agent.history.system_prompt()
}
