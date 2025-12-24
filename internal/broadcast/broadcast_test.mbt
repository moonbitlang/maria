///|
async test "Broadcast::spawn_in" (t : @test.Test) {
  @mock.run(t, _ => {
    let broadcast : Broadcast[Int] = Broadcast::new()
    broadcast.put(10)
    let results0 = []
    broadcast.add_listener((value : Int) => results0.push(value))
    broadcast.put(20)
    let results1 = []
    @async.with_task_group(group => {
      let session = broadcast.spawn_in(group)
      defer session.stop()
      broadcast.put(30)
      @async.pause()
      broadcast.put(40)
      broadcast.add_listener((value : Int) => results1.push(value))
      broadcast.put(50)
    })
    @json.inspect(results0, content=[10, 20, 30, 40, 50])
    @json.inspect(results1, content=[10, 20, 30, 40, 50])
    @json.inspect(broadcast.values(), content=[10, 20, 30, 40, 50])
    let results2 = []
    broadcast.add_listener((value : Int) => results2.push(value))
    @async.with_task_group(group => {
      let session = broadcast.spawn_in(group)
      defer session.stop()
      broadcast.put(60)
      @async.pause()
      broadcast.put(70)
    })
    @json.inspect(results0, content=[10, 20, 30, 40, 50, 60, 70])
    @json.inspect(results1, content=[10, 20, 30, 40, 50, 60, 70])
    @json.inspect(results2, content=[10, 20, 30, 40, 50, 60, 70])
  })
}

///|
async test "Broadcast::add_listener" (t : @test.Test) {
  @mock.run(t, _ => {
    let broadcast : Broadcast[Int] = Broadcast::new()
    broadcast.put(0)
    let results0 = []
    broadcast.add_listener((value : Int) => results0.push(value))
    broadcast.put(10)
    let results1 = []
    broadcast.add_listener((value : Int) => results1.push(value))
    broadcast.put(20)
    broadcast.flush()
    @json.inspect(results0, content=[0, 10, 20])
    @json.inspect(results1, content=[0, 10, 20])
    @json.inspect(broadcast.values(), content=[0, 10, 20])
  })
}

///|
async test "Broadcast::stop" (t : @test.Test) {
  @mock.run(t, _ => {
    let broadcast : Broadcast[Int] = Broadcast::new()
    let results0 = []
    broadcast.add_listener((value : Int) => results0.push(value))
    let results1 = []
    broadcast.add_listener((value : Int) => results1.push(value))
    @async.with_task_group(group => {
      let session = broadcast.spawn_in(group)
      defer session.stop()
      broadcast.put(1)
      @async.pause()
      broadcast.put(2)
    })
    @json.inspect(results0, content=[1, 2])
    @json.inspect(results1, content=[1, 2])
  })
}
