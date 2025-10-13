# `moonbitlang/maria/moon`

MoonBit project management and build system integration.

## Overview

This package provides programmatic access to MoonBit projects, including checking, testing, building, and analyzing MoonBit modules and packages.

## Usage

### Loading a Module

```moonbit
///|
test "load module" {
  let moon = @moon.Module::load("/path/to/project")
  // Module represents a MoonBit project with moon.mod.json
  let _ = moon
}
```

### Checking Code

```moonbit
///|
test "check code" {
  let moon = @moon.Module::load(".")
  moon.check()
  
  let diagnostics = moon.diagnostics().collect()
  // diagnostics contains errors and warnings
  let _ = diagnostics
}
```

### Running Tests

```moonbit
///|
test "run tests" {
  let moon = @moon.Module::load(".")
  let results = moon.test_()
  // results contains test outcomes
  let _ = results
}
```

### Getting Package Interface

```moonbit
///|
test "get interface" {
  let moon = @moon.Module::load(".")
  let pkg = moon.package_("my_package")
  match pkg {
    Some(pkg) => {
      let interface = pkg.interface()
      // interface is the .mbti file content
      let _ = interface
    }
    None => ()
  }
}
```

### Coverage Analysis

```moonbit
///|
test "coverage" {
  let moon = @moon.Module::load(".")
  moon.test_(enable_coverage=true)
  
  let report = moon.coverage.report(format=Summary)
  // report shows covered/uncovered lines
  let _ = report
}
```

## API Reference

### Types

#### `Module`

Represents a MoonBit module (project).

**Methods:**
- `load(path: String) -> Module raise`: Loads a module
- `check()`: Type-checks all packages
- `test_(enable_coverage?: Bool) -> Array[TestResult]`: Runs tests
- `build()`: Builds the module
- `package_(name: String) -> Package?`: Gets a package by name
- `packages() -> Iter[Package]`: Iterates all packages
- `files() -> Iter[File]`: Iterates all files
- `diagnostics() -> Iter[Diagnostic]`: Gets errors and warnings

#### `Package`

Represents a MoonBit package.

**Methods:**
- `name() -> String`: Package name
- `path() -> String`: Package path
- `interface() -> String?`: Gets the package interface (.mbti)
- `check()`: Type-checks this package
- `files() -> Iter[File]`: Files in this package

#### `File`

Represents a source file.

**Methods:**
- `path() -> String`: File path
- `content() -> String`: File content
- `segments() -> Array[Segment]`: Code segments
- `diagnostics() -> Array[Diagnostic]`: File diagnostics

#### `Diagnostic`

An error, warning, or info message.

**Fields:**
- `message: String`: Diagnostic message
- `loc: Location`: Source location
- `severity: Severity`: Error, Warning, or Info

#### `Coverage`

Code coverage analysis.

**Methods:**
- `report(format: CoverageFormat) -> String`: Generates coverage report
- `analyze() -> String`: Analyzes uncovered lines

## Notes

- Integrates with the `moon` build system
- Async operations for I/O
- Supports incremental checking
- Coverage requires moon test with --enable-coverage
- Diagnostics include file, line, column information
