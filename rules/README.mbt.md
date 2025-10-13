# `moonbitlang/maria/rules`

Rule-based system for defining and applying transformation rules.

## Overview

This package provides a framework for defining and applying rules to data structures, useful for validation, transformation, and policy enforcement.

## Usage

### Defining Rules

```moonbit
// Rules define conditions and actions
// Example: validation rules, transformation rules, etc.
let _ = 0
```

## API Reference

### Types

#### `Rule[T]`

A rule that can be applied to data of type `T`.

**Methods:**
- `apply(data: T) -> Result`: Applies the rule to data
- `matches(data: T) -> Bool`: Checks if rule applies to data

### Functions

#### `rule(condition: (T) -> Bool, action: (T) -> T) -> Rule[T]`

Creates a new rule from a condition and action.

## Use Cases

- Data validation
- Business rules enforcement
- Configuration transformations
- Policy applications
- Conditional processing

## Notes

- Rules can be composed and chained
- Supports pattern matching and conditions
- Designed for extensibility
- Can be used for declarative programming patterns
