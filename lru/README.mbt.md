# `moonbitlang/maria/lru`

LRU (Least Recently Used) cache implementation.

## Overview

This package provides a simple and efficient LRU cache that automatically evicts the least recently used items when the cache reaches its maximum size.

## Usage

### Creating a Cache

```moonbit
///|
test "create cache" {
  // Create cache with default size (100)
  let cache : @lru.Cache[String, Int] = @lru.cache()
  
  // Create cache with custom size
  let small_cache : @lru.Cache[String, String] = @lru.cache(max_size=10)
  let _ = (cache, small_cache)
}
```

### Basic Operations

```moonbit
///|
test "cache operations" {
  let cache : @lru.Cache[String, Int] = @lru.cache(max_size=3)
  
  // Set values
  cache.set("a", 1)
  cache.set("b", 2)
  cache["c"] = 3  // Using op_set alias
  
  // Get values
  @json.inspect(cache.get("a"), content=Some(1))
  @json.inspect(cache["b"], content=2)  // Using op_get (unwraps)
  
  // Non-existent key
  @json.inspect(cache.get("d"), content=None)
}
```

### LRU Eviction

```moonbit
///|
test "lru eviction" {
  let cache : @lru.Cache[String, Int] = @lru.cache(max_size=2)
  
  cache.set("a", 1)
  cache.set("b", 2)
  
  // Access "a" to mark it as recently used
  let _ = cache.get("a")
  
  // Adding "c" will evict "b" (least recently used)
  cache.set("c", 3)
  
  @json.inspect(cache.get("a"), content=Some(1))  // Still present
  @json.inspect(cache.get("b"), content=None)     // Evicted
  @json.inspect(cache.get("c"), content=Some(3))  // Just added
}
```

### Converting to JSON

```moonbit
///|
test "cache to json" {
  let cache : @lru.Cache[String, Int] = @lru.cache(max_size=3)
  cache.set("x", 10)
  cache.set("y", 20)
  
  let json = cache.to_json()
  // Returns JSON object with cache contents
  let _ = json
}
```

## API Reference

### Functions

#### `cache[K: Eq + Hash, V](max_size?: Int = 100) -> Cache[K, V]`

Creates a new LRU cache.

- **Parameters:**
  - `max_size`: Maximum number of items in the cache (default: 100)
- **Returns:** A new `Cache` instance

### Types

#### `Cache[K, V]`

An LRU cache mapping keys of type `K` to values of type `V`.

**Methods:**
- `get(key: K) -> V?`: Retrieves a value, updating its access time. Returns `None` if not found.
- `op_get[key]`: Alias for `get(key).unwrap()` - retrieves value or panics
- `set(key: K, value: V)`: Inserts or updates a value, evicting LRU item if necessary
- `op_set[key] = value`: Alias for `set(key, value)`

**Traits:**
- `ToJson`: Converts cache to JSON (requires `K: Show, V: ToJson`)

## How It Works

- Each cache entry tracks when it was last accessed
- On each `get` or `set`, a timestamp is incremented
- When the cache is full, the entry with the oldest access timestamp is evicted
- Both reads (`get`) and writes (`set`) update the access time

## Notes

- The cache is not thread-safe
- Keys must implement `Eq` and `Hash` traits
- Using `op_get` (`cache[key]`) will panic if the key doesn't exist
- Use `get()` method for safe access that returns `Option[V]`
