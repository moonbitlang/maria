# todo

## Purpose

- Create and manage structured task lists for complex coding sessions
- Read and display the current session's todo list to understand task progress
- Track progress on multi-step operations with status updates
- Organize work into manageable, prioritized tasks
- Provide clear progress visibility to users

## When to Use

### Reading the Todo List (action='read')

Use the read action proactively and frequently to ensure awareness of current task status:

- **At the beginning of conversations** to see what's pending
- **Before starting new tasks** to prioritize work appropriately
- **When the user asks about previous tasks** or plans
- **Whenever you're uncertain about what to do next**
- **After completing tasks** to update understanding of remaining work
- **After every few messages** to ensure you're staying on track
- **Periodically during long sessions** to review progress and stay organized

The read action takes only the `action` parameter set to 'read'. It returns formatted
output showing tasks grouped by status with summary statistics.

### Writing/Managing Tasks

Use write actions (create, add_task, update, mark_progress, mark_completed) proactively in these scenarios:

- **Complex multi-step tasks**: When a task requires 3 or more distinct steps
- **Non-trivial tasks**: Tasks that require careful planning or multiple operations
- **User explicitly requests todo list**: When the user directly asks you to use the todo list
- **User provides multiple tasks**: When users provide a list of things to be done
- **When you start working on a task**: Mark it as in_progress BEFORE beginning work
- **After completing a task**: Mark it as completed immediately

## When NOT to Use

Skip using this tool when:

- There is only a **single, straightforward task**
- The task is **trivial** and can be completed in less than 3 steps
- The task is **purely conversational or informational**

## Parameters

- `action` (required): One of 'read', 'create', 'add_task', 'update', 'mark_progress', 'mark_completed'
- `content`: Task content (required for create/add_task)
- `task_id`: ID of task to update (required for update/mark_progress/mark_completed)
- `priority`: 'high', 'medium', or 'low' (default: medium)
- `status`: 'pending', 'in_progress', or 'completed'
- `notes`: Additional context for the task

## Important Considerations

- Each task gets a unique ID that can be used for future updates
- Task content for 'create' action should be formatted as a numbered list for multiple tasks
- The system automatically tracks task creation and modification timestamps
- Todo lists persist across tool calls within the same session
- Use descriptive task names that clearly indicate what needs to be accomplished

## Example

User request:
> I want to add a dark mode toggle to the application settings. Make sure you run the tests and build when you're done!

Assistant creates todo list:
1. Create dark mode toggle component in Settings page
2. Add dark mode state management (context/store)
3. Implement CSS styles for dark theme
4. Update existing components to support theme switching
5. Run tests and build process

The assistant used the todo list because adding dark mode is a multi-step feature requiring UI, state management, and styling changes, and the user explicitly requested tests and build be run afterward.

## Workflow Tips

1. **Read first**: Use 'read' action to check existing todos before planning new work
2. **Start with creation**: Use 'create' action to establish the initial task list
3. **Add tasks incrementally**: Use 'add_task' as new requirements emerge
4. **Track progress actively**: Use 'mark_progress' when starting work on a task
5. **Complete tasks promptly**: Use 'mark_completed' when tasks are finished
6. **Add context**: Use 'notes' parameter to record important decisions or challenges
