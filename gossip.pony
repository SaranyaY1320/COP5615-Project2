use "collections"
use "random"
use "time"
use "promises"

actor Main
  let env: Env
  let nodes: Array[Node tag]
  var topology: String
  var algorithm: String
  var convergence_count: USize = 0
  let rng: Random
  var start_time: I64 = 0
  let promise: Promise[None] = Promise[None]
  let timers: Timers = Timers
  var total_nodes: USize

  new create(env': Env) =>
    env = env'
    nodes = Array[Node tag]
    topology = ""
    algorithm = ""
    rng = Rand(Time.nanos())
    total_nodes = 0

    try
      let args = env.args
      if args.size() != 4 then
        env.out.print("Usage: project2 numNodes topology algorithm")
        return
      end

      total_nodes = args(1)?.usize()?
      topology = args(2)?
      algorithm = args(3)?

      env.out.print("Starting simulation: " + total_nodes.string() + " nodes, topology: " + topology + ", algorithm: " + algorithm)

      for i in Range(0, total_nodes) do
        nodes.push(Node(this, i, algorithm, env))
      end

      match topology
      | "full" => create_full_network()
      | "3D" => create_3d_grid(total_nodes)
      | "line" => create_line_network()
      | "imp3D" => create_imperfect_3d_grid(total_nodes)
      else
        env.out.print("Invalid topology")
        return
      end

      start_simulation()
    else
      env.out.print("Error encountered while processing input arguments")
    end

  fun ref start_simulation() =>
    start_time = Time.millis().i64()
    try
      let initial_node = nodes(rng.int[USize](nodes.size()))?
      match algorithm
      | "gossip" => initial_node.initiate_gossip()
      | "push-sum" => initial_node.initiate_push_sum()
      else
        env.out.print("Invalid algorithm")
        return
      end
    end
    
    let timer = Timer(
      object iso is TimerNotify
        let main: Main = this
        fun ref apply(timer: Timer, count: U64): Bool =>
          main.check_progress()
          true
      end,
      100_000_000,
      100_000_000
    )
    timers(consume timer)

    promise.next[None]({(n: None) => 
      let end_time = Time.millis().i64()
      let convergence_time = end_time - start_time
    env.out.print("Convergence time: " + convergence_time.string() + " ms")
    })

  be report_convergence() =>
    convergence_count = convergence_count + 1
    env.out.print("Node converged. Total converged: " + convergence_count.string() + " / " + total_nodes.string())
    if convergence_count == total_nodes then
      promise(None)
      timers.dispose()
    end

  be check_progress() =>
    if convergence_count < total_nodes then
      try
        let node = nodes(rng.int[USize](nodes.size()))?
        match algorithm
        | "gossip" => node.initiate_gossip()
        | "push-sum" => node.initiate_push_sum()
        end
      end
    end

  fun ref create_full_network() =>
    env.out.print("Creating full network")
    for (i, node) in nodes.pairs() do
      let neighbors = recover iso Array[Node tag] end
      for (j, neighbor) in nodes.pairs() do
        if i != j then
          neighbors.push(neighbor)
        end
      end
      node.update_neighbors(consume neighbors)
    end

  fun ref create_3d_grid(num_nodes: USize) =>
    env.out.print("Creating 3D grid")
    let size = (num_nodes.f64().pow(1.0/3.0).ceil()).usize()
    for (i, node) in nodes.pairs() do
      let x = i % size
      let y = (i / size) % size
      let z = i / (size * size)
      let neighbors = recover iso Array[Node tag] end
      if x > 0 then try neighbors.push(nodes(i - 1)?) end end
      if x < (size - 1) then try neighbors.push(nodes(i + 1)?) end end
      if y > 0 then try neighbors.push(nodes(i - size)?) end end
      if y < (size - 1) then try neighbors.push(nodes(i + size)?) end end
      if z > 0 then try neighbors.push(nodes(i - (size * size))?) end end
      if z < (size - 1) then try neighbors.push(nodes(i + (size * size))?) end end
      node.update_neighbors(consume neighbors)
    end

  fun ref create_line_network() =>
    env.out.print("Creating line network")
    for (i, node) in nodes.pairs() do
      let neighbors = recover iso Array[Node tag] end
      if i > 0 then try neighbors.push(nodes(i - 1)?) end end
      if i < (nodes.size() - 1) then try neighbors.push(nodes(i + 1)?) end end
      node.update_neighbors(consume neighbors)
    end

  fun ref create_imperfect_3d_grid(num_nodes: USize) =>
    env.out.print("Creating imperfect 3D grid")
    create_3d_grid(num_nodes)
    for node in nodes.values() do
      try
        let random_neighbor = nodes(rng.int[USize](nodes.size()))?
        node.update_neighbors(random_neighbor)
      end
    end

actor Node
  let main: Main tag
  let id: USize
  let algorithm: String
  let env: Env
  var neighbors: Array[Node tag] = Array[Node tag]
  var gossip_count: USize = 0
  var sum: F64
  var weight: F64 = 1.0
  var prev_ratio: F64 = 0.0
  var stability_count: USize = 0
  let rng: Random
  var has_converged: Bool = false

  new create(main': Main tag, id': USize, algorithm': String, env': Env) =>
    main = main'
    id = id'
    algorithm = algorithm'
    env = env'
    sum = id'.f64()
    rng = Rand(Time.nanos())

  be update_neighbors(new_neighbors: (Array[Node tag] iso | Node tag)) =>
    match new_neighbors
    | let arr: Array[Node tag] iso =>
      neighbors = consume arr
      env.out.print("Node " + id.string() + " set " + neighbors.size().string() + " neighbors")
    | let node: Node tag =>
      neighbors.push(node)
      env.out.print("Node " + id.string() + " added a neighbor")
    end

  be process_gossip() =>
    if not has_converged then
      gossip_count = gossip_count + 1
      env.out.print("Node " + id.string() + " received gossip. Count: " + gossip_count.string())
      if gossip_count < 10 then
        initiate_gossip()
      else
        has_converged = true
        env.out.print("Node " + id.string() + " converged")
        main.report_convergence()
      end
    end

  be process_push_sum(s': F64, w': F64) =>
    if not has_converged then
      sum = sum + s'
      weight = weight + w'
      let new_ratio = sum / weight
      
      if (prev_ratio - new_ratio).abs() < 1e-10 then
        stability_count = stability_count + 1
      else
        stability_count = 0
      end

      prev_ratio = new_ratio

      env.out.print("Node " + id.string() + " received push-sum. New ratio: " + new_ratio.string())

      if stability_count < 3 then
        initiate_push_sum()
      else
        has_converged = true
        env.out.print("Node " + id.string() + " converged")
        main.report_convergence()
      end
    end

  be initiate_gossip() =>
    if neighbors.size() > 0 then
      try
        let target = neighbors(rng.int[USize](neighbors.size()))?
        env.out.print("Node " + id.string() + " spreading gossip")
        target.process_gossip()
      end
    else
      env.out.print("Node " + id.string() + " has no neighbors to spread gossip")
    end

  be initiate_push_sum() =>
    if neighbors.size() > 0 then
      try
        let target = neighbors(rng.int[USize](neighbors.size()))?
        let send_s = sum / 2
        let send_w = weight / 2
        sum = sum - send_s
        weight = weight - send_w
        env.out.print("Node " + id.string() + " sending push-sum")
        target.process_push_sum(send_s, send_w)
      end
    else
      env.out.print("Node " + id.string() + " has no neighbors to send push-sum")
    end