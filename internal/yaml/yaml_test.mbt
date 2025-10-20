///|
test {
  @json.inspect(
    @yaml.parse(
      (
        #|[1, 2, 3]
      ),
    ),
    content=[1, 2, 3],
  )
  @json.inspect(
    @yaml.parse(
      (
        #|"hello"
      ),
    ),
    content="hello",
  )
  @json.inspect(
    @yaml.parse(
      (
        #|  true
      ),
    ),
    content=true,
  )
  @json.inspect(
    @yaml.parse(
      (
        #|  false
      ),
    ),
    content=false,
  )
  @json.inspect(
    @yaml.parse(
      (
        #|  123.45
      ),
    ),
    content=123.45,
  )
}
