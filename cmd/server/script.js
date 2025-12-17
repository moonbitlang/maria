let eventSource = null;
const messagesDiv = document.getElementById("messages");
const statusDiv = document.getElementById("status");
const messageInput = document.getElementById("messageInput");
const sendBtn = document.getElementById("sendBtn");
const cancelBtn = document.getElementById("cancelBtn");
const modulesListDiv = document.getElementById("modulesList");
const refreshModulesBtn = document.getElementById("refreshModulesBtn");

// Task status
let isTaskRunning = false;

// Tools state
let availableTools = {};

// Todo list state
let currentTodos = { todos: [], created_at: null, updated_at: null };

// Update UI based on task status
function updateTaskStatus(running) {
  isTaskRunning = running;
  if (cancelBtn) {
    cancelBtn.disabled = !running;
  }
}

// Message queue state
let queuedMessages = [];
let queuePanel, queueHeader, queueList, queueCount, queueToggle;

// Toggle queue panel
function toggleQueuePanel() {
  queuePanel.classList.toggle("expanded");
  queueToggle.textContent = queuePanel.classList.contains("expanded")
    ? "▲"
    : "▼";
}

// Update queue display
function updateQueueDisplay() {
  // Guard: Don't update if elements aren't initialized yet
  if (!queueCount || !queueList || !queuePanel) {
    return;
  }

  queueCount.textContent = queuedMessages.length;

  if (queuedMessages.length === 0) {
    queueList.innerHTML =
      '<div class="no-queue-items">No queued messages</div>';
  } else {
    queueList.innerHTML = queuedMessages
      .map((item) => {
        const content = extractMessageContent(item.message);
        const preview =
          content.length > 100 ? content.substring(0, 100) + "..." : content;
        return `
          <div class="queue-item">
            <div class="queue-item-id">ID: ${escapeHtml(item.id)}</div>
            <div class="queue-item-content">${escapeHtml(preview)}</div>
          </div>
        `;
      })
      .join("");
  }

  // Auto-expand if there are queued messages
  if (queuedMessages.length > 0 && !queuePanel.classList.contains("expanded")) {
    toggleQueuePanel();
  }
}

// MoonBit Modules Management
async function loadModules() {
  try {
    modulesListDiv.innerHTML = '<div class="loading">Loading modules...</div>';
    const response = await fetch("/v1/moonbit/modules");

    if (!response.ok) {
      throw new Error(`Failed to load modules: ${response.statusText}`);
    }

    const data = await response.json();
    displayModules(data.modules || []);
  } catch (error) {
    modulesListDiv.innerHTML = `<div class="no-modules">Error: ${escapeHtml(
      error.message
    )}</div>`;
    addMessage(`✗ Failed to load modules: ${error.message}`);
  }
}

function displayModules(modules) {
  if (modules.length === 0) {
    modulesListDiv.innerHTML =
      '<div class="no-modules">No MoonBit modules found in the current directory.</div>';
    return;
  }

  modulesListDiv.innerHTML = modules
    .map(
      (module, index) => `
    <div class="module-item">
      <div class="module-info">
        <div>
          <span class="module-name">${escapeHtml(
            module.name || "Unknown"
          )}</span>
          <span class="module-version">v${escapeHtml(
            module.version || "0.0.0"
          )}</span>
        </div>
        ${
          module.description
            ? `<div class="module-description">${escapeHtml(
                module.description
              )}</div>`
            : ""
        }
        <div class="module-path">${escapeHtml(module.path || "")}</div>
      </div>
      <div class="module-actions">
        <button class="publish-btn" onclick="publishModule('${escapeHtml(
          module.path
        )}', ${index})">
          Publish
        </button>
      </div>
    </div>
  `
    )
    .join("");
}

async function publishModule(modulePath, moduleIndex) {
  const buttons = document.querySelectorAll(".publish-btn");
  const button = buttons[moduleIndex];

  if (!button) return;

  button.disabled = true;
  button.textContent = "Publishing...";

  try {
    const response = await fetch("/v1/moonbit/publish", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        module: {
          path: modulePath,
        },
      }),
    });

    const data = await response.json();

    if (response.ok) {
      addMessage(
        `✓ Successfully published module: ${data.module.name}@${data.module.version}`
      );
      button.textContent = "✓ Published";
      button.style.background = "#45a049";

      // Reset button after 3 seconds
      setTimeout(() => {
        button.textContent = "Publish";
        button.style.background = "";
        button.disabled = false;
      }, 3000);
    } else {
      const errorMsg = data.error?.message || response.statusText;
      addMessage(`✗ Failed to publish module: ${errorMsg}`);

      if (data.error?.metadata?.process) {
        const process = data.error.metadata.process;
        if (process.stderr) {
          addMessage(`stderr: ${process.stderr}`);
        }
      }

      button.textContent = "✗ Failed";
      button.style.background = "#f44336";

      // Reset button after 3 seconds
      setTimeout(() => {
        button.textContent = "Publish";
        button.style.background = "";
        button.disabled = false;
      }, 3000);
    }
  } catch (error) {
    addMessage(`✗ Error publishing module: ${error.message}`);
    button.textContent = "✗ Error";
    button.style.background = "#f44336";

    // Reset button after 3 seconds
    setTimeout(() => {
      button.textContent = "Publish";
      button.style.background = "";
      button.disabled = false;
    }, 3000);
  }
}

refreshModulesBtn.addEventListener("click", loadModules);

// Tools Management
async function loadTools() {
  try {
    const toolsListDiv = document.getElementById("toolsList");
    toolsListDiv.innerHTML = '<div class="loading">Loading tools...</div>';
    const response = await fetch("/v1/tools");

    if (!response.ok) {
      throw new Error(`Failed to load tools: ${response.statusText}`);
    }

    const data = await response.json();
    availableTools = data;
    displayTools(data);
  } catch (error) {
    const toolsListDiv = document.getElementById("toolsList");
    toolsListDiv.innerHTML = `<div class="no-modules">Error: ${escapeHtml(
      error.message
    )}</div>`;
    addMessage(`✗ Failed to load tools: ${error.message}`);
  }
}

function displayTools(tools) {
  const toolsListDiv = document.getElementById("toolsList");
  const toolEntries = Object.entries(tools);

  if (toolEntries.length === 0) {
    toolsListDiv.innerHTML = '<div class="no-modules">No tools available.</div>';
    return;
  }

  toolsListDiv.innerHTML = toolEntries
    .map(
      ([toolName, toolInfo]) => `
    <div class="tool-item">
      <input
        type="checkbox"
        id="tool-${escapeHtml(toolName)}"
        data-tool-name="${escapeHtml(toolName)}"
        ${toolInfo.enabled ? "checked" : ""}
      />
      <label for="tool-${escapeHtml(toolName)}">${escapeHtml(toolName)}</label>
    </div>
  `
    )
    .join("");
}

async function updateEnabledTools() {
  const checkboxes = document.querySelectorAll('.tool-item input[type="checkbox"]');
  const enabledTools = Array.from(checkboxes)
    .filter((cb) => cb.checked)
    .map((cb) => cb.getAttribute("data-tool-name"));

  try {
    const response = await fetch("/v1/enabled-tools", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(enabledTools),
    });

    if (response.ok) {
      addMessage(`✓ Successfully updated enabled tools`);
      await loadTools(); // Reload to show updated state
    } else {
      const data = await response.json();
      const errorMsg = data.error?.message || response.statusText;
      addMessage(`✗ Failed to update tools: ${errorMsg}`);
    }
  } catch (error) {
    addMessage(`✗ Error updating tools: ${error.message}`);
  }
}

const updateToolsBtn = document.getElementById("updateToolsBtn");
if (updateToolsBtn) {
  updateToolsBtn.addEventListener("click", updateEnabledTools);
}

// Todo List Management
function getStatusIcon(status) {
  switch (status) {
    case "Pending":
      return "⏳";
    case "InProgress":
      return "🔄";
    case "Completed":
      return "✅";
    default:
      return "❓";
  }
}

function getPriorityIcon(priority) {
  switch (priority) {
    case "High":
      return "🔴";
    case "Medium":
      return "🟡";
    case "Low":
      return "🟢";
    default:
      return "⚪";
  }
}

function getStatusClass(status) {
  switch (status) {
    case "Pending":
      return "pending";
    case "InProgress":
      return "in-progress";
    case "Completed":
      return "completed";
    default:
      return "";
  }
}

function renderTodoList(todoData) {
  const todoListDiv = document.getElementById("todoList");
  if (!todoListDiv) return;

  const todos = todoData.todos || [];

  if (todos.length === 0) {
    todoListDiv.innerHTML = '<div class="no-todos">No todos yet</div>';
    return;
  }

  // Count todos by status
  const statusCounts = {
    Pending: 0,
    InProgress: 0,
    Completed: 0,
  };

  todos.forEach((todo) => {
    if (statusCounts.hasOwnProperty(todo.status)) {
      statusCounts[todo.status]++;
    }
  });

  // Build summary text
  const summaryParts = [`Total: ${todos.length}`];
  if (statusCounts.Completed > 0)
    summaryParts.push(`✅ Completed: ${statusCounts.Completed}`);
  if (statusCounts.InProgress > 0)
    summaryParts.push(`🔄 In Progress: ${statusCounts.InProgress}`);
  if (statusCounts.Pending > 0)
    summaryParts.push(`⏳ Pending: ${statusCounts.Pending}`);

  const summaryText = summaryParts.join(" | ");

  // Render todos
  const todoItems = todos
    .map(
      (todo, index) => `
    <div class="todo-item ${getStatusClass(todo.status)}">
      <div class="todo-header">
        <span class="todo-status-icon">${getStatusIcon(todo.status)}</span>
        <span class="todo-priority-icon">${getPriorityIcon(todo.priority)}</span>
        <span class="todo-id">[${escapeHtml(todo.id)}]</span>
        <span class="todo-content">${escapeHtml(todo.content)}</span>
      </div>
      ${todo.notes ? `<div class="todo-notes">📝 ${escapeHtml(todo.notes)}</div>` : ""}
    </div>
  `
    )
    .join("");

  todoListDiv.innerHTML = `
    ${todoItems}
    <div class="todo-summary">📊 ${summaryText}</div>
  `;
}

function updateTodoList(todoData) {
  currentTodos = todoData;
  renderTodoList(todoData);
}

// System Prompt Management
async function loadSystemPrompt() {
  try {
    const response = await fetch("/v1/system-prompt");

    if (!response.ok) {
      throw new Error(`Failed to load system prompt: ${response.statusText}`);
    }

    const systemPrompt = await response.json();
    const systemPromptInput = document.getElementById("systemPromptInput");
    if (systemPromptInput) {
      systemPromptInput.value = systemPrompt || "";
    }
  } catch (error) {
    addMessage(`✗ Failed to load system prompt: ${error.message}`);
  }
}

async function saveSystemPrompt() {
  const systemPromptInput = document.getElementById("systemPromptInput");
  const systemPrompt = systemPromptInput.value.trim();

  try {
    const response = await fetch("/v1/system-prompt", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(systemPrompt || null),
    });

    if (response.ok) {
      addMessage(`✓ Successfully saved system prompt`);
    } else {
      const data = await response.json();
      const errorMsg = data.error?.message || response.statusText;
      addMessage(`✗ Failed to save system prompt: ${errorMsg}`);
    }
  } catch (error) {
    addMessage(`✗ Error saving system prompt: ${error.message}`);
  }
}

async function clearSystemPrompt() {
  try {
    const response = await fetch("/v1/system-prompt", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(null),
    });

    if (response.ok) {
      const systemPromptInput = document.getElementById("systemPromptInput");
      if (systemPromptInput) {
        systemPromptInput.value = "";
      }
      addMessage(`✓ Successfully cleared system prompt`);
    } else {
      const data = await response.json();
      const errorMsg = data.error?.message || response.statusText;
      addMessage(`✗ Failed to clear system prompt: ${errorMsg}`);
    }
  } catch (error) {
    addMessage(`✗ Error clearing system prompt: ${error.message}`);
  }
}

const saveSystemPromptBtn = document.getElementById("saveSystemPromptBtn");
if (saveSystemPromptBtn) {
  saveSystemPromptBtn.addEventListener("click", saveSystemPrompt);
}

const clearSystemPromptBtn = document.getElementById("clearSystemPromptBtn");
if (clearSystemPromptBtn) {
  clearSystemPromptBtn.addEventListener("click", clearSystemPrompt);
}

// Pretty-print utilities based on cmd/jsonl2md formatting logic
function escapeHtml(text) {
  const div = document.createElement("div");
  div.textContent = text;
  return div.innerHTML;
}

function formatTimestamp(timestamp) {
  if (!timestamp) return "";
  const date = new Date(timestamp);
  return date.toLocaleTimeString();
}

function formatToolCallArguments(name, args) {
  if (args.path) {
    return `<span class="tool-name">&lt;${name} path="${escapeHtml(
      args.path
    )}"&gt;</span>`;
  } else if (args.command) {
    return `<span class="tool-name">&lt;${name} command="${escapeHtml(
      args.command
    )}"&gt;</span>`;
  } else {
    return `<span class="tool-name">&lt;${name}&gt;</span>`;
  }
}

function formatMessageRole(message) {
  if (message.role === "user") return "User";
  if (message.role === "assistant") return "Assistant";
  if (message.role === "system") return "System";
  if (message.role === "tool") return "Tool";
  return message.role;
}

function extractMessageContent(message) {
  if (typeof message.content === "string") {
    return message.content;
  }
  if (Array.isArray(message.content)) {
    return message.content
      .filter((part) => part.type === "text")
      .map((part) => part.text)
      .join("");
  }
  return "";
}

function formatLogEntry(data) {
  // Extract desc from the new event format
  const desc = data.desc || data; // Fallback to data for backward compatibility
  const timestamp = data.time ? formatTimestamp(data.time) : "";

  // Handle different message types
  switch (desc.msg) {
    case "ModelLoaded": {
      const modelName = Array.isArray(desc.name) ? desc.name[0] : desc.name;
      return `
        <div class="log-entry model-loaded">
          <div class="log-header">
            <span class="log-type">System Information</span>
            ${timestamp ? `<span class="timestamp">${timestamp}</span>` : ""}
          </div>
          <div class="log-content">Model: ${escapeHtml(modelName)}</div>
        </div>
      `;
    }

    case "UserMessage": {
      const content = desc.content.trim();
      const firstLine = content.split("\n").find((line) => line.trim());
      const title = firstLine ? `User: ${firstLine}` : "User";

      return `
        <div class="log-entry message-added">
          <div class="log-header">
            <span class="log-type">${escapeHtml(title)}</span>
            ${timestamp ? `<span class="timestamp">${timestamp}</span>` : ""}
          </div>
          <div class="log-content">
            <details open>
              <summary>Show content</summary>
              <pre>${escapeHtml(content)}</pre>
            </details>
          </div>
        </div>
      `;
    }

    case "SystemPromptSet": {
      // Don't render system prompt messages in the UI
      return "";
    }

    case "AssistantMessage": {
      const content = (desc.content || "").trim();
      const firstLine = content.split("\n").find((line) => line.trim());
      const title = firstLine ? `Assistant: ${firstLine}` : "Assistant";

      let toolCallsHtml = "";
      if (desc.tool_calls && desc.tool_calls.length > 0) {
        toolCallsHtml = desc.tool_calls
          .map((toolCall) => {
            const args = JSON.parse(toolCall.function.arguments || "{}");
            return `
            <div class="tool-call">
              <div class="tool-header">
                ${formatToolCallArguments(toolCall.function.name, args)}
              </div>
              <details>
                <summary>Show arguments</summary>
                <pre class="tool-args">${escapeHtml(
                  JSON.stringify(args, null, 2)
                )}</pre>
              </details>
            </div>
          `;
          })
          .join("");
      }

      return `
        <div class="log-entry request-completed">
          <div class="log-header">
            <span class="log-type">${escapeHtml(title)}</span>
            ${timestamp ? `<span class="timestamp">${timestamp}</span>` : ""}
          </div>
          ${
            content
              ? `<div class="log-content">
                  <details open>
                    <summary>Show content</summary>
                    <pre>${escapeHtml(content)}</pre>
                  </details>
                </div>`
              : ""
          }
          ${toolCallsHtml}
        </div>
      `;
    }

    case "PostToolCall": {
      // Extract tool name from tool_call structure
      const toolCall = desc.tool_call;
      const name = toolCall && toolCall.function ? toolCall.function.name : (desc.name || "unknown");
      const text = desc.rendered || desc.text || "";
      const hasError = desc.error !== undefined;
      const hasResult = desc.result !== undefined;

      let titlePrefix = "Tool call result";
      if (hasError) {
        titlePrefix = "❌ Tool call error";
      }

      let titleSuffix = `&lt;${name}&gt;`;
      if (hasResult && desc.result) {
        const result = desc.result;
        // Handle Result type: [operation_type, value] for tools like todo, execute_command
        const resultValue = Array.isArray(result) && result.length > 1 ? result[1] : result;
        if (
          name === "execute_command" &&
          resultValue &&
          resultValue.command
        ) {
          titleSuffix = `&lt;${name} command="${escapeHtml(
            resultValue.command
          )}"&gt;`;
          if (resultValue.status !== 0) {
            titlePrefix = "❌ Tool call error";
          }
        } else if (resultValue && resultValue.path) {
          titleSuffix = `&lt;${name} path="${escapeHtml(resultValue.path)}"&gt;`;
        }
      } else if (hasError && desc.error) {
        // Error information is in desc.error
        const errorValue = Array.isArray(desc.error) && desc.error.length > 1 ? desc.error[1] : desc.error;
        // Error details are already in titlePrefix
      }

      return `
        <div class="log-entry post-tool-call ${hasError ? "error" : ""}">
          <div class="log-header">
            <span class="log-type">${titlePrefix}: ${titleSuffix}</span>
            ${timestamp ? `<span class="timestamp">${timestamp}</span>` : ""}
          </div>
          <div class="log-content">
            <details open>
              <summary>Output</summary>
              <pre class="tool-output">${escapeHtml(text)}</pre>
            </details>
          </div>
        </div>
      `;
    }

    default:
      return `
        <div class="log-entry generic">
          <div class="log-header">
            <span class="log-type">${escapeHtml(desc.msg || "Unknown")}</span>
            ${timestamp ? `<span class="timestamp">${timestamp}</span>` : ""}
          </div>
          <div class="log-content">
            <details>
              <summary>Show details</summary>
              <pre>${escapeHtml(JSON.stringify(desc, null, 2))}</pre>
            </details>
          </div>
        </div>
      `;
  }
}

function addMessage(text, type = "info") {
  const msg = document.createElement("div");
  msg.className = "message";
  const time = new Date().toLocaleTimeString();
  msg.innerHTML = `<span class="time">[${time}]</span> ${text}`;
  messagesDiv.appendChild(msg);
  messagesDiv.scrollTop = messagesDiv.scrollHeight;
}

function connect() {
  eventSource = new EventSource("/v1/events");

  eventSource.onopen = () => {
    statusDiv.textContent = "Status: Connected";
    statusDiv.style.color = "green";
    addMessage("✓ Connected to server");
  };

  eventSource.addEventListener(
    "maria.queued_messages.synchronized",
    (event) => {
      const data = JSON.parse(event.data);
      if (!Array.isArray(data)) {
        console.error(
          "Expected array for maria.queued_messages.synchronized event, got:",
          data
        );
        return;
      }
      queuedMessages = data;
      updateQueueDisplay();
      addMessage(`✓ Queue synchronized: ${queuedMessages.length} message(s)`);
    }
  );

  eventSource.addEventListener("maria", (event) => {
    const data = JSON.parse(event.data);
    // Extract desc from the new event format
    const desc = data.desc || data; // Fallback to data for backward compatibility

    console.log("Received maria event:", desc);

    if (desc.msg === "TokenCounted") {
      // There are too many of these events; ignore them to reduce noise
      return;
    }

    // Update task status based on events
    if (desc.msg === "PreConversation") {
      updateTaskStatus(true);
    } else if (desc.msg === "PostConversation" || desc.msg === "Failed" || desc.msg === "Cancelled") {
      updateTaskStatus(false);
    }

    // Handle PostToolCall event for todo tool (only on success, not error)
    if (desc.msg === "PostToolCall" && desc.tool_call && !desc.error) {
      const toolName = desc.tool_call.function ? desc.tool_call.function.name : null;
      if (toolName === "todo" && desc.result) {
        // Result format: ["Read"|"Write", {...}]
        if (Array.isArray(desc.result) && desc.result.length === 2) {
          const operation = desc.result[0]; // "Read" or "Write"
          const todoData = desc.result[1];
          // Check if the result contains a todo list structure
          if (todoData && todoData.todos) {
            updateTodoList(todoData);
          }
        }
      }
    }

    // Handle queue events
    if (desc.msg === "MessageQueued") {
      queuedMessages.push({
        id: desc.message ? desc.message.id : data.id,
        message: desc.message,
      });
      updateQueueDisplay();
    } else if (desc.msg === "MessageUnqueued") {
      const unqueuedId = desc.message ? desc.message.id : data.id;
      queuedMessages = queuedMessages.filter((item) => item.id !== unqueuedId);
      updateQueueDisplay();
    }

    const formattedHtml = formatLogEntry(data);
    const logDiv = document.createElement("div");
    logDiv.innerHTML = formattedHtml;
    messagesDiv.appendChild(logDiv);
    messagesDiv.scrollTop = messagesDiv.scrollHeight;
  });

  eventSource.onerror = (error) => {
    statusDiv.textContent = "Status: Error/Disconnected";
    statusDiv.style.color = "red";
    addMessage("✗ Connection error");
  };
}

sendBtn.addEventListener("click", async () => {
  const message = messageInput.value.trim();
  if (!message) {
    addMessage("⚠ Please enter a message");
    return;
  }

  try {
    const response = await fetch("/v1/message", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          role: "user",
          content: message,
        },
      }),
    });

    if (response.ok) {
      addMessage(`✓ Sent: ${message}`);
      messageInput.value = "";
    } else {
      addMessage(`✗ Failed to send message: ${response.statusText}`);
    }
  } catch (error) {
    addMessage(`✗ Error: ${error.message}`);
  }
});

messageInput.addEventListener("keypress", (e) => {
  if (e.key === "Enter") {
    sendBtn.click();
  }
});

cancelBtn.addEventListener("click", async () => {
  if (!isTaskRunning) {
    return;
  }

  try {
    const response = await fetch("/v1/cancel", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
    });

    if (response.ok) {
      addMessage("✓ Task cancellation requested");
      updateTaskStatus(false);
    } else {
      const data = await response.json();
      const errorMsg = data.error?.message || response.statusText;
      addMessage(`✗ Failed to cancel task: ${errorMsg}`);
    }
  } catch (error) {
    addMessage(`✗ Error cancelling task: ${error.message}`);
  }
});

// Auto-connect when DOM is fully loaded
document.addEventListener("DOMContentLoaded", () => {
  // Initialize queue panel elements
  queuePanel = document.getElementById("queuePanel");
  queueHeader = document.getElementById("queueHeader");
  queueList = document.getElementById("queueList");
  queueCount = document.getElementById("queueCount");
  queueToggle = document.getElementById("queueToggle");

  // Setup queue panel event listener
  if (queueHeader) {
    queueHeader.addEventListener("click", toggleQueuePanel);
  }

  connect();
  loadModules();
  loadTools();
  loadSystemPrompt();
});
