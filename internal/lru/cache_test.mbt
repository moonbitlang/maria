///|
test "Cache::op_set" {
  let cache = @lru.cache(max_size=2)
  cache["a"] = 1
  cache["b"] = 2
  json_inspect(cache["a"], content=1)
  json_inspect(cache.get("b"), content=[2])
  json_inspect(cache.get("c"), content=null)
  json_inspect(cache, content={ "a": 1, "b": 2 })
  cache["c"] = 3
  json_inspect(cache, content={ "b": 2, "c": 3 })
}
