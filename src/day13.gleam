import gleam/bit_array
import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/result.{try}
import gleam/string
import heap

type Position =
  #(Int, Int)

type Node {
  Node(position: Position, score: Int, steps: Int)
}

fn distance(a: Position, b: Position) -> Int {
  let #(x1, y1) = a
  let #(x2, y2) = b

  let diff = fn(a, b) {
    int.subtract(a, b)
    |> int.absolute_value
  }

  0
  |> int.add(diff(x1, x2))
  |> int.add(diff(y1, y2))
}

fn count_bits(value: Int) -> Int {
  int.range(0, 64, 0, fn(acc, i) {
    case
      value
      |> int.bitwise_shift_right(i)
      |> int.bitwise_and(1)
    {
      1 -> acc + 1
      _ -> acc
    }
  })
}

fn is_inside(pos: Position) -> Bool {
  let #(x, y) = pos
  x >= 0 && y >= 0
}

fn is_space(pos: Position, favorite: Int) -> Bool {
  let #(x, y) = pos

  0
  |> int.add(x * x)
  |> int.add(3 * x)
  |> int.add(2 * x * y)
  |> int.add(y)
  |> int.add(y * y)
  |> int.add(favorite)
  |> count_bits
  |> int.is_even
}

fn next_positions(position: Position) -> List(Position) {
  let #(x, y) = position
  [#(x, y + 1), #(x + 1, y), #(x, y - 1), #(x - 1, y)]
}

fn add_cache(cache: Dict(Position, Int), node: Node) -> Dict(Position, Int) {
  case cache |> dict.get(node.position) {
    Ok(steps) if steps > node.steps ->
      cache |> dict.insert(node.position, node.steps)
    Error(_) -> cache |> dict.insert(node.position, node.steps)
    _ -> cache
  }
}

fn should_visit(cache: Dict(Position, Int), node: Node) -> Bool {
  case cache |> dict.get(node.position) {
    Ok(steps) -> steps > node.steps
    Error(_) -> True
  }
}

fn solve(
  queue: heap.Heap(Node),
  favorite: Int,
  target: Position,
  cache: Dict(Position, Int),
) -> Result(Dict(Position, Int), String) {
  use <- bool.guard(heap.is_empty(queue), Ok(cache))

  use #(queue, cur) <- try(
    heap.pop_min(queue)
    |> result.replace_error("the queue is empty"),
  )

  let cache = cache |> add_cache(cur)

  cur.position
  |> next_positions
  |> list.map(fn(pos) {
    let steps = cur.steps + 1
    let score = steps + distance(pos, target)
    Node(pos, score, steps)
  })
  |> list.filter(fn(node) { is_inside(node.position) })
  |> list.filter(fn(node) { is_space(node.position, favorite) })
  |> list.filter(fn(node) { should_visit(cache, node) })
  |> list.fold(queue, fn(queue, node) { heap.insert(queue, node) })
  |> solve(favorite, target, cache)
}

fn part_1(cache: Dict(Position, Int), target: Position) -> Result(Int, String) {
  cache
  |> dict.get(target)
  |> result.replace_error("failed to find a solution")
}

fn part_2(cache: Dict(Position, Int), steps: Int) -> Int {
  cache
  |> dict.to_list
  |> list.filter(fn(element) {
    let #(_, s) = element
    s <= steps
  })
  |> list.length
}

fn cmp(a: Node, b: Node) {
  int.compare(a.score, b.score)
}

pub fn main(input: String) -> Result(Nil, String) {
  let target = #(31, 39)

  use favorite <- try(
    input
    |> string.trim
    |> int.parse
    |> result.replace_error("failed to parse input"),
  )

  use positions <- try(
    heap.new(cmp)
    |> heap.insert(Node(#(1, 1), 0, 0))
    |> solve(favorite, target, dict.new()),
  )

  use p1 <- try(positions |> part_1(target))
  let p2 = positions |> part_2(50)

  p1
  |> int.to_string
  |> io.println

  p2
  |> int.to_string
  |> io.println

  Ok(Nil)
}
