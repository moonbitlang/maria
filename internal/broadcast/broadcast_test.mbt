///|
async test "broadcast" {
  let broadcast : Broadcast[Int] = Broadcast::new()
  @async.with_task_group(group => {
    group.spawn_bg(() => broadcast.listen((hist, chan) => {
      for e in hist {
        chan.put(e)
      }
      @json.inspect(chan.get(), content=1)
      @json.inspect(chan.get(), content=2)
      @json.inspect(chan.get(), content=3)
      group.spawn_bg(() => broadcast.listen((hist, chan) => {
        for e in hist {
          chan.put(e)
        }
        @json.inspect(chan.get(), content=1)
        @json.inspect(chan.get(), content=2)
        @json.inspect(chan.get(), content=3)
      }))
    }))
    broadcast.put(1)
    broadcast.put(2)
    @async.pause()
    broadcast.put(3)
  })
}
