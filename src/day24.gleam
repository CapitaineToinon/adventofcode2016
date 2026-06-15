import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result.{replace_error, try}
import gleam/set
import gleam/string
import heap

type Tile {
  Empty
  Target(value: Int)
}

type State {
  State(steps: Int, position: #(Int, Int))
}

fn parse(input: String) -> Dict(#(Int, Int), Tile) {
  input
  |> string.trim
  |> string.split("\n")
  |> list.index_fold(dict.new(), fn(acc, row, y) {
    row
    |> string.split("")
    |> list.index_fold(acc, fn(acc, tile, x) {
      case tile |> int.parse {
        Ok(value) ->
          acc
          |> dict.insert(#(x, y), Target(value))
        Error(_) ->
          case tile {
            "." -> acc |> dict.insert(#(x, y), Empty)
            _ -> acc
          }
      }
    })
  })
}

fn find_value(
  grid: Dict(#(Int, Int), Tile),
  v: Int,
) -> Result(#(Int, Int), String) {
  grid
  |> dict.to_list()
  |> list.find_map(fn(entry) {
    let #(pos, tile) = entry
    case tile {
      Target(value) if value == v -> Ok(pos)
      _ -> Error("skip tile")
    }
  })
  |> replace_error("failed to find start")
}

fn new_heap() {
  heap.new(fn(a: State, b: State) { int.compare(a.steps, b.steps) })
}

fn get(from: Int, to: Int, cache: Dict(#(Int, Int), Int)) -> Option(Int) {
  case cache |> dict.get(#(from, to)) {
    Ok(value) -> Some(value)
    Error(_) ->
      case cache |> dict.get(#(to, from)) {
        Ok(value) -> Some(value)
        Error(_) -> None
      }
  }
}

fn set(
  from: Int,
  to: Int,
  value: Int,
  cache: Dict(#(Int, Int), Int),
) -> Dict(#(Int, Int), Int) {
  cache
  |> dict.insert(#(from, to), value)
  |> dict.insert(#(to, from), value)
}

/// Generate all paths starting from 0
fn part_1_permutations(from: Int, to: Int) -> List(List(Int)) {
  int.range(from, to, [], list.prepend)
  |> list.permutations
  |> list.map(fn(order) { order |> list.prepend(0) })
}

/// Generate all paths starting from 0 and going back to 0
fn part_2_permutations(from: Int, to: Int) -> List(List(Int)) {
  part_1_permutations(from, to)
  |> list.map(fn(order) { order |> list.append([0]) })
}

fn solve_permutation(
  order: List(Int),
  grid: Dict(#(Int, Int), Tile),
  cache: Dict(#(Int, Int), Int),
) -> Result(#(Int, Dict(#(Int, Int), Int)), String) {
  order
  |> list.window_by_2
  |> list.fold(Ok(#(0, cache)), fn(acc, window) {
    use #(acc, cache) <- try(acc)
    let #(from, to) = window

    case get(from, to, cache) {
      Some(value) -> Ok(#(acc |> int.add(value), cache))
      None -> {
        use start <- try(find_value(grid, from))

        use steps <- try(
          new_heap()
          |> heap.insert(State(steps: 0, position: start))
          |> shortest_path(to, grid, set.new()),
        )

        Ok(#(acc |> int.add(steps), set(from, to, steps, cache)))
      }
    }
  })
}

/// Given a list of possibles paths, solve them all and
/// return the shorted path, given a cache of already
/// processed a->b paths
fn solve_permutations(
  permutations: List(List(Int)),
  grid: Dict(#(Int, Int), Tile),
  cache: Dict(#(Int, Int), Int),
) -> Result(#(Int, Dict(#(Int, Int), Int)), String) {
  use #(best, cache) <- try(
    permutations
    |> list.fold(Ok(#(None, cache)), fn(acc, order) {
      use #(best, cache) <- try(acc)
      use #(steps, cache) <- try(solve_permutation(order, grid, cache))

      let best = case best {
        Some(b) if b < steps -> Some(b)
        _ -> Some(steps)
      }

      Ok(#(best, cache))
    })
    |> replace_error("failed to solve"),
  )

  use best <- try(case best {
    Some(value) -> Ok(value)
    None -> Error("failed to find a solutiuon")
  })

  Ok(#(best, cache))
}

fn next_positions(pos: #(Int, Int)) -> List(#(Int, Int)) {
  let #(x, y) = pos

  [
    #(x, y + 1),
    #(x, y - 1),
    #(x + 1, y),
    #(x - 1, y),
  ]
}

/// Find the sortest path from the first input to the heap
/// to the tile Target(to), using simple BFS
fn shortest_path(
  heap: heap.Heap(State),
  to: Int,
  grid: Dict(#(Int, Int), Tile),
  cache: set.Set(#(Int, Int)),
) -> Result(Int, String) {
  use #(heap, state) <- heap.pop_guard(heap, Error("failed to find a solution"))

  use tile <- try(
    grid
    |> dict.get(state.position)
    |> replace_error("failed to find tile"),
  )

  use <- bool.guard(tile == Target(to), Ok(state.steps))

  use <- bool.lazy_guard(cache |> set.contains(state.position), fn() {
    shortest_path(heap, to, grid, cache)
  })

  state.position
  |> next_positions
  |> list.filter_map(fn(pos) {
    case dict.has_key(grid, pos) {
      True -> Ok(State(steps: state.steps + 1, position: pos))
      False -> Error("skip impossible position")
    }
  })
  |> list.fold(heap, fn(acc, state) { acc |> heap.insert(state) })
  |> shortest_path(to, grid, cache |> set.insert(state.position))
}

pub fn main(input: String) -> Result(Nil, String) {
  let cache = dict.new()

  use #(p1, cache) <- try(
    input
    |> parse
    |> solve_permutations(part_1_permutations(1, 8), _, cache),
  )

  use #(p2, _) <- try(
    input
    |> parse
    |> solve_permutations(part_2_permutations(1, 8), _, cache),
  )

  p1
  |> int.to_string
  |> io.println

  p2
  |> int.to_string
  |> io.println

  Ok(Nil)
}
