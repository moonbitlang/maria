# `moonbitlang/maria/tool/get_moonbit_coverage`

Retrieves code coverage reports for MoonBit projects.

## Overview

This tool generates and returns code coverage reports after running tests with coverage enabled. Helps identify untested code and improve test coverage.

## Parameters

- `project_path` (required): Path to the MoonBit project
- `file` (optional): Specific file to get coverage for (returns project-wide if omitted)

## Behavior

- Runs tests with coverage instrumentation
- Analyzes which lines were executed
- Generates coverage report in requested format
- Can filter to specific files or show entire project

## Report Information

Coverage reports typically include:
- Lines covered vs. total lines
- Percentage coverage
- Uncovered line numbers
- File-by-file breakdown
- Summary statistics

## Use Cases

- Identifying untested code
- Improving test coverage
- Finding gaps in test suites
- Code quality metrics
- CI/CD coverage reporting
- Test effectiveness analysis

## Notes

- Part of the maria AI agent tool system
- Requires tests to be run with coverage enabled
- Uses MoonBit's built-in coverage tools
- Can generate multiple report formats
- Helps guide test writing efforts
