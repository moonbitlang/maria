# `moonbitlang/maria/pino`

Structured logging library with multiple output transports.

## Overview

This package provides a structured logging system with support for different log levels and output transports (console, file, etc.).

## Usage

### Basic Logging

```moonbit
///|
test "basic logging" {
  let logger = @pino.logger(
    level=@pino.Level::Info,
    transport=@pino.console()
  )
  
  logger.info("Application started")
  logger.error("An error occurred")
}
```

### Structured Logging

```moonbit
///|
test "structured logging" {
  let logger = @pino.logger(
    level=@pino.Level::Debug,
    transport=@pino.console()
  )
  
  logger.info("User logged in", {
    "user_id": 123,
    "ip": "192.168.1.1"
  })
}
```

## API Reference

### Types

#### `Logger`

A structured logger instance.

**Methods:**
- `trace(message: String, data?: Json)`: Log at trace level
- `debug(message: String, data?: Json)`: Log at debug level
- `info(message: String, data?: Json)`: Log at info level
- `warn(message: String, data?: Json)`: Log at warning level
- `error(message: String, data?: Json)`: Log at error level
- `fatal(message: String, data?: Json)`: Log at fatal level

#### `Level`

Log level enumeration.

- `Trace`: Detailed trace information
- `Debug`: Debug information
- `Info`: Informational messages
- `Warn`: Warning messages
- `Error`: Error messages
- `Fatal`: Fatal error messages

#### `Transport`

Output destination for log messages.

### Functions

#### `logger(level: Level, transport: Transport) -> Logger`

Creates a new logger instance.

#### `console() -> Transport`

Creates a console transport that writes to stdout/stderr.

## Log Format

Logs are typically output in structured JSON format:

```json
{
  "level": "info",
  "time": "2025-01-15T10:30:00Z",
  "message": "User logged in",
  "user_id": 123,
  "ip": "192.168.1.1"
}
```

## Notes

- Inspired by the pino Node.js logger
- Supports structured logging with JSON data
- Log levels are hierarchical (trace < debug < info < warn < error < fatal)
- Logs below the configured level are filtered out
- Efficient and designed for production use
