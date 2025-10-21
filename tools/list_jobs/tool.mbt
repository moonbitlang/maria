///|
pub let list_jobs : @tool.Tool[@job.Manager] = @tool.tool(
  name="list_jobs",
  description="List all background jobs",
  parameters={ "type": "object", "properties": {}, "required": [] },
  (_, manager) => {
    let jobs = manager.list() catch {
      error => return @tool.error("Failed to list background jobs: \{error}")
    }
    let output = StringBuilder::new()
    for job in jobs {
      output.write_string("- [\{job.id}] \{job.name}\n")
      output.write_string("  Command: \{job.command}\n")
      if job.description is Some(desc) {
        output.write_string("  Description: \{desc}\n")
      }
      output.write_string("  CWD: \{job.cwd}\n")
      output.write_string("  Stdout: \{job.stdout}\n")
      output.write_string("  Stderr: \{job.stderr}\n")
      let status = job.status()
      let status_str = match status {
        None => "Running"
        Some(code) => "Completed (exit code: \{code})"
      }
      output.write_string("  Status: \{status_str}\n")
    }
    @tool.ok(output.to_string())
  },
)
