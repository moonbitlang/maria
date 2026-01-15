///|
/// Instruction prompt sent to LLM for summarization during context compaction.
///
/// This prompt is used to generate a handoff summary that allows another LLM
/// instance to seamlessly continue the conversation after compaction.
pub const SUMMARIZATION_PROMPT : String =
  #|You are performing a CONTEXT CHECKPOINT COMPACTION. Create a handoff summary for another LLM that will resume the task.
  #|
  #|Include:
  #|- Current progress and key decisions made
  #|- Important context, constraints, or user preferences
  #|- What remains to be done (clear next steps)
  #|- Any critical data, examples, or references needed to continue
  #|
  #|Be concise, structured, and focused on helping the next LLM seamlessly continue the work.

///|
/// Prefix added to the summary when resuming a compacted conversation.
///
/// This prefix provides context to the LLM that it's continuing work started
/// by another model instance.
pub const SUMMARY_PREFIX : String =
  #|Another language model started to solve this problem and produced a summary of its thinking process. You also have access to the state of the tools that were used by that language model. Use this to build on the work that has already been done and avoid duplicating work. Here is the summary produced by the other language model, use the information in this summary to assist with your own analysis:
