import crypto from "crypto";
import express from "express";
import fs from "fs";
import path from "path";
import readline from "readline";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Simple logger utility
const logger = {
  log: (level, message, ...args) => {
    const timestamp = new Date().toISOString();
    const prefix = `[${timestamp}] [${level.toUpperCase()}]`;
    console.log(prefix, message, ...args);
  },
  info: (message, ...args) => logger.log("info", message, ...args),
  warn: (message, ...args) => logger.log("warn", message, ...args),
  error: (message, ...args) => logger.log("error", message, ...args),
  debug: (message, ...args) => logger.log("debug", message, ...args),
};

const app = express();
const PORT = process.env.PORT || 8090;

// Request logging middleware
app.use((req, res, next) => {
  const start = Date.now();

  // Log when response finishes
  res.on("finish", () => {
    const duration = Date.now() - start;
    logger.info(`${req.method} ${req.url} ${res.statusCode} - ${duration}ms`);
  });

  next();
});

// Enable CORS for development
app.use((req, res, next) => {
  res.header("Access-Control-Allow-Origin", "*");
  res.header("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  res.header("Access-Control-Allow-Headers", "Content-Type");
  next();
});

const task = {
  name: "Test Task",
  id: "test",
  status: "generating",
  cwd: "/home/user/test",
};

const longTask = {
  name: "A very long task name, to test UI handling of long names in various components",
  id: "long-task",
  status: "generating",
  cwd: "/home/user/long-task",
};

const tasks = [task, longTask];

app.get("/v1/tasks", (req, res) => {
  res.writeHead(200, "OK");
  res.write(
    JSON.stringify({
      tasks: tasks,
    }),
  );
  res.end();
});

app.get("/v1/events", (req, res) => {
  // Set headers for SSE
  res.setHeader("Content-Type", "text/event-stream");
  res.setHeader("Cache-Control", "no-cache");
  res.setHeader("Connection", "keep-alive");
  res.setHeader("X-Accel-Buffering", "no"); // Disable buffering in nginx

  res.write(`event: daemon.tasks.synchronized
data: ${JSON.stringify({ tasks })}

`);

  // Keep the connection open
  const changedInterval = setInterval(() => {
    res.write(`event: daemon.tasks.changed
data: ${JSON.stringify({ task: { ...longTask, status: "idle" } })}

`);
  }, 500);

  req.on("close", () => {
    clearInterval(changedInterval);
    res.end();
  });
});

for (const t of tasks) {
  app.get(`/v1/task/${t.id}`, (req, res) => {
    res.writeHead(200, "OK");
    res.write(
      JSON.stringify({
        task: t,
      }),
    );
    res.end();
  });

  app.post(`/v1/task/${t.id}/message`, (req, res) => {
    res.writeHead(200, "OK");
    res.end();
  });

  app.post(`/v1/task/${t.id}/cancel`, (req, res) => {
    logger.info(`Task ${t.id} cancelled`);
    res.writeHead(200, "OK");
    res.end();
  });

  // Server-Sent Events endpoint
  app.get(`/v1/task/${t.id}/events`, async (req, res) => {
    // Set headers for SSE
    res.setHeader("Content-Type", "text/event-stream");
    res.setHeader("Cache-Control", "no-cache");
    res.setHeader("Connection", "keep-alive");
    res.setHeader("X-Accel-Buffering", "no"); // Disable buffering in nginx

    // Send initial connection message
    res.write(
      'event: maria\ndata: {"type":"connected","timestamp":' +
        Date.now() +
        "}\n\n",
    );

    const logFilePath = path.join(__dirname, "log.jsonl");

    try {
      // Check if file exists
      if (!fs.existsSync(logFilePath)) {
        res.write(
          'event: maria\ndata: {"type":"error","message":"Log file not found"}\n\n',
        );
        return;
      }

      // Create readline interface to read line by line
      const fileStream = fs.createReadStream(logFilePath);
      const rl = readline.createInterface({
        input: fileStream,
        crlfDelay: Infinity,
      });

      let lineCount = 0;

      // Read and send each line
      for await (const line of rl) {
        if (line.trim()) {
          try {
            // Validate JSON
            const json = JSON.parse(line);
            json.id = crypto.randomUUID(); // Add an ID for tracking

            // Send the event
            res.write(`event: maria\ndata: ${JSON.stringify(json)}\n\n`);
            lineCount++;

            // Small delay to simulate streaming (optional, can be removed for faster streaming)
            await new Promise((resolve) => setTimeout(resolve, 500));
          } catch (parseError) {
            logger.error("Invalid JSON line:", parseError.message);
          }
        }
      }

      logger.info(`Sent ${lineCount} events`);

      // Send completion event
      res.write(
        'event: maria\ndata: {"type":"completed","count":' +
          lineCount +
          "}\n\n",
      );
    } catch (error) {
      logger.error("Error reading log file:", error);
      res.write(
        'event: maria\ndata: {"type":"error","message":"' +
          error.message +
          '"}\n\n',
      );
    }

    // Handle client disconnect
    req.on("close", () => {
      logger.info("Client disconnected");
    });
  });
}

// Health check endpoint
app.get("/health", (req, res) => {
  res.json({ status: "ok", timestamp: Date.now() });
});

// Start server
app.listen(PORT, () => {
  logger.info(`Dev API server running on http://localhost:${PORT}`);
});
