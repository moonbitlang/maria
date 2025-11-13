// Global state
let eventSource = null;
let currentAgentId = null;
let agents = [];

// DOM elements
const agentListDiv = document.getElementById("agentList");
const messagesDiv = document.getElementById("messages");
const statusDiv = document.getElementById("status");
const messageInput = document.getElementById("messageInput");
const sendBtn = document.getElementById("sendBtn");
const createAgentBtn = document.getElementById("createAgentBtn");
const createAgentModal = document.getElementById("createAgentModal");
const confirmCreateBtn = document.getElementById("confirmCreateBtn");
const cancelCreateBtn = document.getElementById("cancelCreateBtn");
const agentView = document.getElementById("agentView");
const noAgentSelected = document.getElementById("noAgentSelected");

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
  const timestamp = data.time ? formatTimestamp(data.time) : "";

  // Handle different message types
  switch (data.msg) {
    case "ModelLoaded": {
      const modelName = Array.isArray(data.name) ? data.name[0] : data.name;
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

    case "MessageAdded": {
      const message = data.message;
      const role = formatMessageRole(message);
      const content = extractMessageContent(message).trim();
      const firstLine = content.split("\n").find((line) => line.trim());
      const title = firstLine ? `${role}: ${firstLine}` : role;

      // System messages are collapsed by default, others are open
      const isOpen = message.role !== "system";

      return `
        <div class="log-entry message-added">
          <div class="log-header">
            <span class="log-type">${escapeHtml(title)}</span>
            ${timestamp ? `<span class="timestamp">${timestamp}</span>` : ""}
          </div>
          ${
            content
              ? `<div class="log-content">
                  <details ${isOpen ? "open" : ""}>
                    <summary>Show content</summary>
                    <pre>${escapeHtml(content)}</pre>
                  </details>
                </div>`
              : ""
          }
        </div>
      `;
    }

    case "RequestCompleted": {
      const message = data.message;
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
      const name = data.name;
      const text = data.text || "";
      const hasError = data.error !== undefined;
      const hasResult = data.result !== undefined;

      let titlePrefix = "Tool call result";
      if (hasError) {
        titlePrefix = "❌ Tool call error";
      }

      let titleSuffix = `&lt;${name}&gt;`;
      if (hasResult && data.result) {
        const result = data.result;
        if (
          name === "execute_command" &&
          Array.isArray(result) &&
          result[0] === "Completed"
        ) {
          const cmdInfo = result[1];
          if (cmdInfo && cmdInfo.command) {
            titleSuffix = `&lt;${name} command="${escapeHtml(
              cmdInfo.command
            )}"&gt;`;
          }
          if (cmdInfo && cmdInfo.status !== 0) {
            titlePrefix = "❌ Tool call error";
          }
        } else if (result.path) {
          titleSuffix = `&lt;${name} path="${escapeHtml(result.path)}"&gt;`;
        }
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
            <span class="log-type">${escapeHtml(data.msg || "Unknown")}</span>
            ${timestamp ? `<span class="timestamp">${timestamp}</span>` : ""}
          </div>
          <div class="log-content">
            <details>
              <summary>Show details</summary>
              <pre>${escapeHtml(JSON.stringify(data, null, 2))}</pre>
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

// Agent management functions
async function loadAgents() {
  try {
    const response = await fetch("/v1/agents");
    if (!response.ok) {
      throw new Error(`Failed to load agents: ${response.statusText}`);
    }
    const data = await response.json();
    agents = data.agents || [];
    renderAgentList();

    // Auto-select first agent if none selected
    if (agents.length > 0 && !currentAgentId) {
      selectAgent(agents[0].id);
    }
  } catch (error) {
    console.error("Error loading agents:", error);
    showError("Failed to load agents: " + error.message);
  }
}

function renderAgentList() {
  agentListDiv.innerHTML = "";

  if (agents.length === 0) {
    const emptyMsg = document.createElement("div");
    emptyMsg.style.padding = "20px";
    emptyMsg.style.color = "#95a5a6";
    emptyMsg.style.textAlign = "center";
    emptyMsg.textContent = "No agents yet";
    agentListDiv.appendChild(emptyMsg);
    return;
  }

  agents.forEach((agent) => {
    const agentItem = document.createElement("div");
    agentItem.className = "agent-item";
    if (agent.id === currentAgentId) {
      agentItem.classList.add("active");
    }

    agentItem.innerHTML = `
      <div class="agent-name">${escapeHtml(agent.name)}</div>
      <div class="agent-cwd">${escapeHtml(agent.cwd)}</div>
    `;

    agentItem.addEventListener("click", () => selectAgent(agent.id));
    agentListDiv.appendChild(agentItem);
  });
}

function selectAgent(agentId) {
  if (currentAgentId === agentId) return;

  // Disconnect from previous agent's event stream
  if (eventSource) {
    eventSource.close();
    eventSource = null;
  }

  currentAgentId = agentId;
  messagesDiv.innerHTML = "";

  // Update UI
  renderAgentList();
  noAgentSelected.style.display = "none";
  agentView.classList.add("active");

  // Connect to new agent's event stream
  connectToAgent(agentId);
}

function connectToAgent(agentId) {
  const agent = agents.find((a) => a.id === agentId);
  if (!agent) return;

  eventSource = new EventSource(`/v1/agent/${agentId}/events`);

  eventSource.onopen = () => {
    statusDiv.textContent = `Status: Connected to ${agent.name}`;
    statusDiv.style.color = "#1abc9c";
    addMessage(`✓ Connected to agent: ${agent.name}`);
  };

  eventSource.onmessage = (event) => {
    addMessage("📨 " + event.data);
  };

  eventSource.addEventListener("maria", (event) => {
    const data = JSON.parse(event.data);
    if (data.msg === "TokenCounted") {
      // There are too many of these events; ignore them to reduce noise
      return;
    }
    const formattedHtml = formatLogEntry(data);
    const logDiv = document.createElement("div");
    logDiv.innerHTML = formattedHtml;
    messagesDiv.appendChild(logDiv);
    messagesDiv.scrollTop = messagesDiv.scrollHeight;
  });

  eventSource.onerror = (error) => {
    statusDiv.textContent = `Status: Error/Disconnected from ${agent.name}`;
    statusDiv.style.color = "#e74c3c";
    addMessage("✗ Connection error");
  };
}

async function createAgent(name, model, cwd) {
  try {
    const response = await fetch("/v1/agent", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        name,
        model,
        cwd,
      }),
    });

    if (!response.ok && response.status !== 409) {
      throw new Error(`Failed to create agent: ${response.statusText}`);
    }

    const data = await response.json();
    const agent = data.agent;

    if (response.status === 409) {
      // Agent already exists, just select it
      await loadAgents();
      selectAgent(agent.id);
      return {
        success: true,
        message: `Connected to existing agent: ${agent.name}`,
      };
    } else {
      // New agent created
      await loadAgents();
      selectAgent(agent.id);
      return { success: true, message: `Agent created: ${agent.name}` };
    }
  } catch (error) {
    console.error("Error creating agent:", error);
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
function showCreateAgentModal() {
  createAgentModal.classList.add("show");
  document.getElementById("agentName").value = "";
  document.getElementById("agentModel").value = "anthropic/claude-sonnet-4";
  document.getElementById("agentCwd").value = "";
  document.getElementById("agentName").focus();
}

function hideCreateAgentModal() {
  createAgentModal.classList.remove("show");
}

// Event listeners
createAgentBtn.addEventListener("click", showCreateAgentModal);

cancelCreateBtn.addEventListener("click", hideCreateAgentModal);

confirmCreateBtn.addEventListener("click", async () => {
  const name = document.getElementById("agentName").value.trim();
  const model = document.getElementById("agentModel").value.trim();
  const cwd = document.getElementById("agentCwd").value.trim();

  if (!name || !model || !cwd) {
    alert("Please fill in all fields");
    return;
  }

  hideCreateAgentModal();

  const result = await createAgent(name, model, cwd);
  if (result.success) {
    addMessage(`✓ ${result.message}`);
  } else {
    showError(result.message);
  }
});

// Close modal on background click
createAgentModal.addEventListener("click", (e) => {
  if (e.target === createAgentModal) {
    hideCreateAgentModal();
  }
});

function connect() {
  eventSource = new EventSource("/v1/events");

  eventSource.onopen = () => {
    statusDiv.textContent = "Status: Connected";
    statusDiv.style.color = "green";
    addMessage("✓ Connected to server");
  };

  eventSource.onmessage = (event) => {
    addMessage("📨 " + event.data);
  };

  eventSource.addEventListener("maria", (event) => {
    const data = JSON.parse(event.data);
    if (data.msg === "TokenCounted") {
      // There are too many of these events; ignore them to reduce noise
      return;
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
  if (!currentAgentId) {
    showError("Please select an agent first");
    return;
  }

  const message = messageInput.value.trim();
  if (!message) {
    showError("Please enter a message");
    return;
  }

  try {
    const response = await fetch(`/v1/agent/${currentAgentId}/message`, {
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

// Auto-load agents when DOM is ready
document.addEventListener("DOMContentLoaded", () => {
  loadAgents();
});
