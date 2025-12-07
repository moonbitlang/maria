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

- **Complex multi-step tasks**: When a task requires 3 or more distinct steps or
  actions - create the todo list FIRST, then explore as needed for each step
- **Non-trivial and complex tasks**: Tasks that require careful planning or
  multiple operations
- **User explicitly requests todo list**: When the user directly asks you to use
  the todo list
- **User provides multiple tasks**: When users provide a list of things to be
  done (numbered or comma-separated) - capture these immediately
- **After receiving new instructions**: Immediately capture user requirements as
  high-level todos, then refine as you explore
- **When you start working on a task**: Mark it as in_progress BEFORE beginning
  work (ideally only one task should be in_progress at a time)
- **After completing a task**: Mark it as completed and add any new follow-up
  tasks discovered during implementation

## When NOT to Use

Skip using this tool when:

- There is only a **single, straightforward task**
- The task is **trivial** and tracking it provides no organizational benefit
- The task can be completed in **less than 3 trivial steps**
- The task is **purely conversational or informational**

**NOTE**: Do not use this tool if there is only one trivial task to do. In this
case you are better off just doing the task directly.

## Important Considerations

- Each task gets a unique ID that can be used for future updates
- Task content for 'create' action should be formatted as a numbered list for multiple tasks
- The system automatically tracks task creation and modification timestamps
- Todo lists persist across tool calls within the same session
- Use descriptive task names that clearly indicate what needs to be accomplished

## Example Usage Scenario

```
User: I want to add a dark mode toggle to the application settings. Make sure you run the tests and build when you're done!

Assistant: I'll help add a dark mode toggle to your application settings. Let me create a todo list to track this implementation.

Creates todo list with the following items:
1. Create dark mode toggle component in Settings page
2. Add dark mode state management (context/store)
3. Implement CSS-in-JS styles for dark theme
4. Update existing components to support theme switching
5. Run tests and build process, addressing any failures or errors that occur

Thinking: The assistant used the todo list because:
1. Adding dark mode is a multi-step feature requiring UI, state management, and styling changes
2. The user explicitly requested tests and build be run afterward
3. The assistant inferred that tests and build need to pass by adding "Ensure tests and build succeed" as the final task
```

## Workflow Tips

1. **Read first**: Use 'read' action to check existing todos before planning new work
2. **Start with creation**: Use 'create' action to establish the initial task list for complex projects
3. **Add tasks incrementally**: Use 'add_task' as new requirements emerge during implementation
4. **Track progress actively**: Use 'mark_progress' when starting work on a task
5. **Complete tasks promptly**: Use 'mark_completed' when tasks are finished
6. **Add context**: Use 'notes' parameter to record important decisions or challenges
7. **Review regularly**: Use 'read' action to maintain awareness of overall progress

By using this TODO tool effectively, you can maintain better organization, provide clear progress visibility, and demonstrate a systematic approach to complex coding tasks.

## Best Practice Workflow

For complex tasks, follow this recommended workflow:

1. **Create high-level todos immediately** when you identify a complex task
2. **Explore the project** as needed to refine your understanding of each task
3. **Update todos** with more specific subtasks as you learn more about the codebase
4. **Mark tasks in-progress** as you begin working on them
5. **Mark completed** promptly after finishing each task

This approach allows you to organize work upfront while remaining flexible to adjust plans as you discover more about the project.

The TODO tool helps you manage and track task progress during complex coding sessions. It provides structured task management capabilities that enhance productivity and demonstrate thoroughness to users.
