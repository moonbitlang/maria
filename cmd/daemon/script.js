// Global state
let eventSource = null;
let currentTaskId = null;
let tasks = [];
let models = [];

// Tools state
let availableTools = {};

// Message queue state
let queuedMessages = [];
let queuePanel, queueHeader, queueList, queueCount, queueToggle;

// DOM elements
const taskListDiv = document.getElementById("taskList");
const messagesDiv = document.getElementById("messages");
const statusDiv = document.getElementById("status");
const messageInput = document.getElementById("messageInput");
const sendBtn = document.getElementById("sendBtn");
const createTaskBtn = document.getElementById("createTaskBtn");
const createTaskModal = document.getElementById("createTaskModal");
const confirmCreateBtn = document.getElementById("confirmCreateBtn");
const cancelCreateBtn = document.getElementById("cancelCreateBtn");
const taskView = document.getElementById("taskView");
const noTaskSelected = document.getElementById("noTaskSelected");
const cancelBtn = document.getElementById("cancelBtn");
const modulesBtn = document.getElementById("modulesBtn");
const modulesModal = document.getElementById("modulesModal");
const closeModulesBtn = document.getElementById("closeModulesBtn");
const modulesList = document.getElementById("modulesList");

// Section collapse/expand functions
function toggleSection(sectionName) {
  const content = document.getElementById(`${sectionName}Content`);
  const toggle = document.getElementById(`${sectionName}Toggle`);
  
  if (content && toggle) {
    content.classList.toggle("expanded");
    toggle.textContent = content.classList.contains("expanded") ? "▲" : "▼";
  }
}

// Message queue functions
function toggleQueuePanel() {
  queuePanel.classList.toggle("expanded");
  queueToggle.textContent = queuePanel.classList.contains("expanded")
    ? "▲"
    : "▼";
}

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

// Pretty-print utilities based on cmd/jsonl2md formatting logic
function escapeHtml(text) {
  const div = document.createElement("div");
  div.textContent = text;
  return div.innerHTML;
}

function getStatusBadge(status) {
  if (status === "generating") {
    return '<span style="display: inline-block; width: 8px; height: 8px; border-radius: 50%; background: #f39c12; margin-left: 8px;" title="Busy"></span>';
  } else if (status === "idle") {
    return '<span style="display: inline-block; width: 8px; height: 8px; border-radius: 50%; background: #27ae60; margin-left: 8px;" title="Idle"></span>';
  }
  return "";
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

    case "RequestCompleted": {
      const message = desc.message;
      const content = (message.content || "").trim();
      const firstLine = content.split("\n").find((line) => line.trim());
      const title = firstLine ? `Assistant: ${firstLine}` : "Assistant";

      let toolCallsHtml = "";
      if (message.tool_calls && message.tool_calls.length > 0) {
        toolCallsHtml = message.tool_calls
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

// Task management functions
async function loadModels() {
  try {
    const response = await fetch("/v1/models");
    if (!response.ok) {
      throw new Error(`Failed to load models: ${response.statusText}`);
    }
    const data = await response.json();
    models = data.models || [];
    populateModelSelect();
  } catch (error) {
    console.error("Error loading models:", error);
    // If models can't be loaded, allow manual input as fallback
    models = [];
  }
}

function populateModelSelect() {
  const modelSelect = document.getElementById("taskModel");
  if (!modelSelect) return;

  // Clear existing options
  modelSelect.innerHTML = "";

  // Always add the "Default" option first
  const defaultOption = document.createElement("option");
  defaultOption.value = "";
  defaultOption.textContent = "Default";
  modelSelect.appendChild(defaultOption);

  if (models.length === 0) {
    // Add a fallback option if no models available
    const option = document.createElement("option");
    option.value = "anthropic/claude-sonnet-4.5";
    option.textContent = "anthropic/claude-sonnet-4.5";
    modelSelect.appendChild(option);
    return;
  }

  // Add all available models
  models.forEach((model) => {
    const option = document.createElement("option");
    option.value = model.name;
    option.textContent = model.name;
    modelSelect.appendChild(option);
  });
}

async function loadTasks() {
  try {
    const response = await fetch("/v1/tasks");
    if (!response.ok) {
      throw new Error(`Failed to load tasks: ${response.statusText}`);
    }
    const data = await response.json();
    tasks = data.tasks || [];
    renderTaskList();

    // Auto-select first task if none selected
    if (tasks.length > 0 && !currentTaskId) {
      selectTask(tasks[0].id);
    }
  } catch (error) {
    console.error("Error loading tasks:", error);
    showError("Failed to load tasks: " + error.message);
  }
}

function renderTaskList() {
  taskListDiv.innerHTML = "";

  if (tasks.length === 0) {
    const emptyMsg = document.createElement("div");
    emptyMsg.style.padding = "20px";
    emptyMsg.style.color = "#95a5a6";
    emptyMsg.style.textAlign = "center";
    emptyMsg.textContent = "No tasks yet";
    taskListDiv.appendChild(emptyMsg);
    return;
  }

  tasks.forEach((task) => {
    const taskItem = document.createElement("div");
    taskItem.className = "task-item";
    taskItem.dataset.taskId = task.id;
    if (task.id === currentTaskId) {
      taskItem.classList.add("active");
    }

    const statusBadge = getStatusBadge(task.status);
    taskItem.innerHTML = `
      <div class="task-name">${escapeHtml(task.name)} ${statusBadge}</div>
      <div class="task-cwd">${escapeHtml(task.cwd)}</div>
    `;

    taskItem.addEventListener("click", () => selectTask(task.id));
    taskListDiv.appendChild(taskItem);
  });
}

function selectTask(taskId) {
  if (currentTaskId === taskId) return;

  // Disconnect from previous task's event stream
  if (eventSource) {
    eventSource.close();
    eventSource = null;
  }

  currentTaskId = taskId;
  messagesDiv.innerHTML = "";

  // Clear queue when switching tasks
  queuedMessages = [];
  updateQueueDisplay();

  // Update UI
  renderTaskList();
  noTaskSelected.style.display = "none";
  taskView.classList.add("active");

  // Load tools and system prompt for the new task
  loadTools();
  loadSystemPrompt();

  // Connect to new task's event stream
  connectToTask(taskId);
}

function connectToTask(taskId) {
  const task = tasks.find((t) => t.id === taskId);
  if (!task) return;

  eventSource = new EventSource(`/v1/task/${taskId}/events`);

  eventSource.onopen = () => {
    statusDiv.textContent = `Status: Connected to ${task.name}`;
    statusDiv.style.color = "#1abc9c";
    addMessage(`✓ Connected to task: ${task.name}`);
  };

  eventSource.addEventListener("maria.history", (event) => {
    const historyData = JSON.parse(event.data);
    if (!Array.isArray(historyData)) {
      console.error(
        "Expected array for maria.history event, got:",
        historyData
      );
      return;
    }
    // Clear existing messages and render all historical events
    messagesDiv.innerHTML = "";
    historyData.forEach((data) => {
      const desc = data.desc || data;
      if (desc.msg === "TokenCounted") {
        return;
      }
      const formattedHtml = formatLogEntry(data);
      const logDiv = document.createElement("div");
      logDiv.innerHTML = formattedHtml;
      messagesDiv.appendChild(logDiv);
    });
    messagesDiv.scrollTop = messagesDiv.scrollHeight;
  });

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
    
    if (desc.msg === "TokenCounted") {
      // There are too many of these events; ignore them to reduce noise
      return;
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
    statusDiv.textContent = `Status: Error/Disconnected from ${task.name}`;
    statusDiv.style.color = "#e74c3c";
    addMessage("✗ Connection error");
  };
}

async function createTask(name, model, cwd, message) {
  try {
    const body = {};

    // Only include fields if they have values
    if (name) body.name = name;
    if (model) body.model = model;
    if (cwd) body.cwd = cwd;
    if (message) {
      body.message = {
        role: "user",
        content: message,
      };
    }

    const response = await fetch("/v1/task", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
    });

    if (!response.ok && response.status !== 409) {
      throw new Error(`Failed to create task: ${response.statusText}`);
    }

    const data = await response.json();
    const task = data.task;

    if (response.status === 409) {
      // Task already exists, just select it
      await loadTasks();
      selectTask(task.id);
      return {
        success: true,
        message: `Connected to existing task: ${task.name}`,
      };
    } else {
      // New task created
      await loadTasks();
      selectTask(task.id);
      return { success: true, message: `Task created: ${task.name}` };
    }
  } catch (error) {
    console.error("Error creating task:", error);
    return { success: false, message: error.message };
  }
}

function showError(message) {
  const errorDiv = document.createElement("div");
  errorDiv.className = "error-message";
  errorDiv.textContent = message;
  messagesDiv.appendChild(errorDiv);
  messagesDiv.scrollTop = messagesDiv.scrollHeight;

  setTimeout(() => {
    errorDiv.remove();
  }, 5000);
}

// Modal functions
function showCreateTaskModal() {
  createTaskModal.classList.add("show");
  document.getElementById("taskName").value = "";
  document.getElementById("taskModel").value = "";
  document.getElementById("taskCwd").value = "";
  document.getElementById("taskPrompt").value = "";

  // Load models if not already loaded
  if (models.length === 0) {
    loadModels();
  }

  document.getElementById("taskName").focus();
}

function hideCreateTaskModal() {
  createTaskModal.classList.remove("show");
}

// Module management functions
async function loadModules() {
  if (!currentTaskId) {
    showError("Please select a task first");
    return;
  }

  try {
    const response = await fetch(`/v1/task/${currentTaskId}/moonbit/modules`);
    if (!response.ok) {
      throw new Error(`Failed to load modules: ${response.statusText}`);
    }
    const data = await response.json();
    const modules = data.modules || [];
    displayModules(modules);
    showModulesModal();
  } catch (error) {
    console.error("Error loading modules:", error);
    showError("Failed to load modules: " + error.message);
  }
}

function displayModules(modules) {
  modulesList.innerHTML = "";

  if (modules.length === 0) {
    const emptyMsg = document.createElement("div");
    emptyMsg.style.padding = "20px";
    emptyMsg.style.color = "#95a5a6";
    emptyMsg.style.textAlign = "center";
    emptyMsg.textContent = "No MoonBit modules found";
    modulesList.appendChild(emptyMsg);
    return;
  }

  modules.forEach((module) => {
    const moduleItem = document.createElement("div");
    moduleItem.className = "module-item";
    moduleItem.id = `module-${escapeHtml(module.path)}`;

    const header = document.createElement("div");
    header.className = "module-header";

    const nameVersion = document.createElement("div");
    nameVersion.innerHTML = `
      <span class="module-name">${escapeHtml(module.name || "Unknown")}</span>
      ${
        module.version
          ? `<span class="module-version">v${escapeHtml(module.version)}</span>`
          : ""
      }
    `;

    const publishBtn = document.createElement("button");
    publishBtn.className = "publish-btn";
    publishBtn.textContent = "Publish";
    publishBtn.onclick = () => publishModule(module.path, moduleItem);

    header.appendChild(nameVersion);
    header.appendChild(publishBtn);

    const path = document.createElement("div");
    path.className = "module-path";
    path.textContent = module.path;

    moduleItem.appendChild(header);
    moduleItem.appendChild(path);

    if (module.description) {
      const description = document.createElement("div");
      description.className = "module-description";
      description.textContent = module.description;
      moduleItem.appendChild(description);
    }

    modulesList.appendChild(moduleItem);
  });
}

async function publishModule(modulePath, moduleItem) {
  const publishBtn = moduleItem.querySelector(".publish-btn");
  const existingStatus = moduleItem.querySelector(".publish-status");
  if (existingStatus) {
    existingStatus.remove();
  }

  const statusDiv = document.createElement("div");
  statusDiv.className = "publish-status loading";
  statusDiv.textContent = "Publishing...";
  moduleItem.appendChild(statusDiv);

  publishBtn.disabled = true;

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
      statusDiv.className = "publish-status success";
      statusDiv.textContent = "✓ Published successfully";
      if (data.process && data.process.stdout) {
        const output = document.createElement("pre");
        output.style.fontSize = "0.8em";
        output.style.marginTop = "5px";
        output.style.whiteSpace = "pre-wrap";
        output.textContent = data.process.stdout;
        statusDiv.appendChild(output);
      }
    } else {
      statusDiv.className = "publish-status error";
      statusDiv.textContent = "✗ Publish failed";
      if (data.error && data.error.metadata && data.error.metadata.process) {
        const stderr = data.error.metadata.process.stderr;
        if (stderr) {
          const errorOutput = document.createElement("pre");
          errorOutput.style.fontSize = "0.8em";
          errorOutput.style.marginTop = "5px";
          errorOutput.style.whiteSpace = "pre-wrap";
          errorOutput.textContent = stderr;
          statusDiv.appendChild(errorOutput);
        }
      }
    }
  } catch (error) {
    statusDiv.className = "publish-status error";
    statusDiv.textContent = "✗ Error: " + error.message;
  } finally {
    publishBtn.disabled = false;
  }
}

function showModulesModal() {
  modulesModal.classList.add("show");
}

function hideModulesModal() {
  modulesModal.classList.remove("show");
}

// Tools Management
async function loadTools() {
  if (!currentTaskId) {
    const toolsListDiv = document.getElementById("toolsList");
    toolsListDiv.innerHTML =
      '<div class="loading">Select a task to load tools...</div>';
    return;
  }

  try {
    const toolsListDiv = document.getElementById("toolsList");
    toolsListDiv.innerHTML = '<div class="loading">Loading tools...</div>';
    const response = await fetch(`/v1/task/${currentTaskId}/tools`);

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
    toolsListDiv.innerHTML =
      '<div class="no-modules">No tools available.</div>';
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
  if (!currentTaskId) {
    showError("Please select a task first");
    return;
  }

  const checkboxes = document.querySelectorAll(
    '.tool-item input[type="checkbox"]'
  );
  const enabledTools = Array.from(checkboxes)
    .filter((cb) => cb.checked)
    .map((cb) => cb.getAttribute("data-tool-name"));

  try {
    const response = await fetch(`/v1/task/${currentTaskId}/enabled-tools`, {
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

// System Prompt Management
async function loadSystemPrompt() {
  if (!currentTaskId) {
    const systemPromptInput = document.getElementById("systemPromptInput");
    if (systemPromptInput) {
      systemPromptInput.value = "";
      systemPromptInput.placeholder =
        "Select a task to load system prompt...";
    }
    return;
  }

  try {
    const response = await fetch(`/v1/task/${currentTaskId}/system-prompt`);

    if (!response.ok) {
      throw new Error(`Failed to load system prompt: ${response.statusText}`);
    }

    const systemPrompt = await response.json();
    const systemPromptInput = document.getElementById("systemPromptInput");
    if (systemPromptInput) {
      systemPromptInput.value = systemPrompt || "";
      systemPromptInput.placeholder =
        "Enter system prompt (leave empty for default)...";
    }
  } catch (error) {
    addMessage(`✗ Failed to load system prompt: ${error.message}`);
  }
}

async function saveSystemPrompt() {
  if (!currentTaskId) {
    showError("Please select a task first");
    return;
  }

  const systemPromptInput = document.getElementById("systemPromptInput");
  const systemPrompt = systemPromptInput.value.trim();

  try {
    const response = await fetch(`/v1/task/${currentTaskId}/system-prompt`, {
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
  if (!currentTaskId) {
    showError("Please select a task first");
    return;
  }

  try {
    const response = await fetch(`/v1/task/${currentTaskId}/system-prompt`, {
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

// Event listeners
createTaskBtn.addEventListener("click", showCreateTaskModal);

cancelCreateBtn.addEventListener("click", hideCreateTaskModal);

cancelBtn.addEventListener("click", async () => {
  if (!currentTaskId) {
    showError("Please select a task first");
    return;
  }

  try {
    const response = await fetch(`/v1/task/${currentTaskId}/cancel`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
    });

    if (response.ok) {
      addMessage("✓ Task cancelled");
    } else if (response.status === 404) {
      const data = await response.json();
      showError(data.error?.message || "No ongoing task to cancel");
    } else {
      showError(`Failed to cancel task: ${response.statusText}`);
    }
  } catch (error) {
    showError(`Error: ${error.message}`);
  }
});

modulesBtn.addEventListener("click", loadModules);

closeModulesBtn.addEventListener("click", hideModulesModal);

confirmCreateBtn.addEventListener("click", async () => {
  const name = document.getElementById("taskName").value.trim();
  const model = document.getElementById("taskModel").value.trim();
  const cwd = document.getElementById("taskCwd").value.trim();
  const prompt = document.getElementById("taskPrompt").value.trim();

  hideCreateTaskModal();

  const result = await createTask(name, model, cwd, prompt);
  if (result.success) {
    addMessage(`✓ ${result.message}`);
  } else {
    showError(result.message);
  }
});

// Close modal on background click
createTaskModal.addEventListener("click", (e) => {
  if (e.target === createTaskModal) {
    hideCreateTaskModal();
  }
});

modulesModal.addEventListener("click", (e) => {
  if (e.target === modulesModal) {
    hideModulesModal();
  }
});

let daemonEventSource = null;

function connectToDaemon() {
  daemonEventSource = new EventSource("/v1/events");

  daemonEventSource.onopen = () => {
    console.log("✓ Connected to daemon event stream");
  };

  daemonEventSource.addEventListener("daemon.tasks.synchronized", (event) => {
    const data = JSON.parse(event.data);
    if (data.tasks && Array.isArray(data.tasks)) {
      tasks = data.tasks;
      renderTaskList();
      console.log(`✓ Synchronized ${tasks.length} tasks from daemon`);

      // Auto-select first task if none selected
      if (tasks.length > 0 && !currentTaskId) {
        selectTask(tasks[0].id);
      }
    }
  });

  daemonEventSource.addEventListener("daemon.task.changed", (event) => {
    const data = JSON.parse(event.data);
    if (data.task) {
      const updatedTask = data.task;
      const taskIndex = tasks.findIndex((t) => t.id === updatedTask.id);

      if (taskIndex !== -1) {
        // Update existing task
        tasks[taskIndex] = updatedTask;
      } else {
        // Add new task
        tasks.push(updatedTask);
      }

      // Update the task list UI
      updateTaskInList(updatedTask);

      console.log(
        `✓ Task ${updatedTask.id} status changed to ${updatedTask.status}`
      );
    }
  });

  daemonEventSource.onerror = (error) => {
    console.error("✗ Daemon connection error");
  };
}

function updateTaskInList(task) {
  const taskItem = taskListDiv.querySelector(`[data-task-id="${task.id}"]`);
  if (taskItem) {
    // Update the task item's content
    const statusBadge = getStatusBadge(task.status);
    taskItem.innerHTML = `
      <div class="task-name">${escapeHtml(task.name)} ${statusBadge}</div>
      <div class="task-cwd">${escapeHtml(task.cwd)}</div>
    `;
    taskItem.addEventListener("click", () => selectTask(task.id));
  } else {
    // Task not in list, re-render entire list
    renderTaskList();
  }
}

sendBtn.addEventListener("click", async () => {
  if (!currentTaskId) {
    showError("Please select a task first");
    return;
  }

  const message = messageInput.value.trim();
  if (!message) {
    showError("Please enter a message");
    return;
  }

  try {
    const response = await fetch(`/v1/task/${currentTaskId}/message`, {
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
      showError(`Failed to send message: ${response.statusText}`);
    }
  } catch (error) {
    showError(`Error: ${error.message}`);
  }
});

messageInput.addEventListener("keypress", (e) => {
  if (e.key === "Enter" && !e.shiftKey) {
    e.preventDefault();
    sendBtn.click();
  }
});

// System prompt event listeners
const saveSystemPromptBtn = document.getElementById("saveSystemPromptBtn");
if (saveSystemPromptBtn) {
  saveSystemPromptBtn.addEventListener("click", saveSystemPrompt);
}

const clearSystemPromptBtn = document.getElementById("clearSystemPromptBtn");
if (clearSystemPromptBtn) {
  clearSystemPromptBtn.addEventListener("click", clearSystemPrompt);
}

// Tools event listener
const updateToolsBtn = document.getElementById("updateToolsBtn");
if (updateToolsBtn) {
  updateToolsBtn.addEventListener("click", updateEnabledTools);
}

// Auto-load tasks when DOM is ready
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

  loadModels();
  connectToDaemon();
});
