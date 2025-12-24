///|
async test "Broadcast::spawn_in" {
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
}

///|
async test "Broadcast::add_listener" {
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
  let results2 = []
  broadcast.add_listener(
    (value : Int) => results2.push(value),
    include_history=true,
  )
  let result3 = []
  broadcast.add_listener(
    (value : Int) => result3.push(value),
    include_history=false,
  )
  broadcast.put(30)
  broadcast.flush()
  @json.inspect(results0, content=[0, 10, 20, 30])
  @json.inspect(results1, content=[0, 10, 20, 30])
  @json.inspect(results2, content=[0, 10, 20, 30])
  @json.inspect(result3, content=[30])
}

///|
async test "Broadcast::stop" {
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
}

///|
async test "Broadcast::flush" (t : @test.Test) {
  @mock.run(t, _ => {
    let broadcast : Broadcast[Int] = Broadcast::new()
    let results0 = []
    broadcast.add_listener((value : Int) => results0.push(value))
    broadcast.put(1)
    broadcast.put(2)
    broadcast.put(3)
    broadcast.flush()
    @json.inspect(results0, content=[1, 2, 3])
    let results1 = []
    broadcast.add_listener((value : Int) => results1.push(value))
    broadcast.put(4)
    broadcast.put(5)
    broadcast.flush()
    @json.inspect(results0, content=[1, 2, 3, 4, 5])
    @json.inspect(results1, content=[1, 2, 3, 4, 5])
  })
}

///|
async test "Broadcast::listen_forever" {
  let broadcast : Broadcast[Int] = Broadcast::new()
  let results0 = []
  let results1 = []
  let results2 = []
  @async.with_task_group(group => {
    group.spawn_bg(
      () => broadcast.listen_forever(value => results0.push(value)),
      no_wait=true,
    )
    broadcast.put(1)
    @async.pause()
    broadcast.put(2)
    @async.pause()
    broadcast.put(3)
    @async.pause()
    group.spawn_bg(
      () => broadcast.listen_forever(value => results1.push(value)),
      no_wait=true,
    )
    group.spawn_bg(
      () => broadcast.listen_forever(
        value => results2.push(value),
        include_history=false,
      ),
      no_wait=true,
    )
    broadcast.put(4)
    @async.pause()
    broadcast.put(5)
    @async.pause()
    broadcast.put(6)
    @async.pause()
  })
  @json.inspect(results0, content=[1, 2, 3, 4, 5, 6])
  @json.inspect(results1, content=[1, 2, 3, 4, 5, 6])
  assert_true(results2 is [.., 5, 6])
}
