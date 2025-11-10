let eventSource = null;
const messagesDiv = document.getElementById("messages");
const statusDiv = document.getElementById("status");
const messageInput = document.getElementById("messageInput");
const sendBtn = document.getElementById("sendBtn");

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

  eventSource.onmessage = (event) => {
    addMessage("📨 " + event.data);
  };

  eventSource.addEventListener("maria", (event) => {
    const data = JSON.parse(event.data);
    const text = JSON.stringify(data);
    addMessage(`🎯 Maria event: ${text}`);
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

// Auto-connect when DOM is fully loaded
document.addEventListener("DOMContentLoaded", () => {
  connect();
});
