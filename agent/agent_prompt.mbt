///|
/// Retrieves the current system prompt from the agent's conversation history.
pub fn Agent::system_prompt(agent : Agent) -> String? {
  agent.history.system_prompt()
}
