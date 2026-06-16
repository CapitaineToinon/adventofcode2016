import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/order
import gleam/result.{replace_error, try}
import gleam/set.{type Set}
import gleam/string
import heap

type Node {
  Node(pos: Position, attr: Attributes)
}

type Position {
  Position(x: Int, y: Int)
}

type Attributes {
  Attributes(id: Int, size: Int, used: Int, avai: Int, perc: Int)
}

type State {
  State(steps: Int, position: Position, target: Position)
}

type Move {
  Move(steps: Int, empty: Position, target: Position)
}

fn parse_int(int: String) -> Result(Int, String) {
  int
  |> int.parse
  |> replace_error("failed to parse int " <> int)
}

fn parse_int_suffix(int: String, suffix: String) {
  int
  |> string.remove_suffix(suffix)
  |> parse_int
}

fn parse_name(name: String) -> Result(#(Int, Int), String) {
  case name |> string.split("-") {
    [_, x, y] -> {
      use x <- try(
        x
        |> string.remove_prefix("x")
        |> parse_int,
      )

      use y <- try(
        y
        |> string.remove_prefix("y")
        |> parse_int,
      )

      Ok(#(x, y))
    }
    _ -> Error("invalid name " <> name)
  }
}

fn remove_double_spaces(line: String) {
  case line |> string.contains("  ") {
    True ->
      line
      |> string.replace("  ", " ")
      |> remove_double_spaces
    False -> line
  }
}

fn parse_node(line: String, id: Int) {
  case line |> string.split(" ") {
    [name, size, used, avai, perc] -> {
      use #(x, y) <- try(name |> parse_name)
      use size <- try(size |> parse_int_suffix("T"))
      use used <- try(used |> parse_int_suffix("T"))
      use avai <- try(avai |> parse_int_suffix("T"))
      use perc <- try(perc |> parse_int_suffix("%"))

      Node(Position(x, y), Attributes(id, size:, used:, avai:, perc:)) |> Ok
    }
    _ -> Error("failed to parse line " <> line)
  }
}

fn is_node(line: String) {
  line
  |> string.starts_with("/dev/grid/node-")
}

fn parse(input: String) {
  input
  |> string.trim
  |> string.split("\n")
  |> list.filter(is_node)
  |> list.map(remove_double_spaces)
  |> list.index_map(parse_node)
  |> result.all
}

fn is_viable(a: Node, b: Node) {
  a.attr.used != 0 && a.attr.used <= b.attr.avai
}

fn find_viable_pairs(nodes: List(Node)) {
  nodes
  |> list.combinations(2)
  |> list.filter_map(fn(win) {
    case win {
      [a, b] ->
        case is_viable(a, b) || is_viable(b, a) {
          True -> #(a, b) |> Ok
          _ -> Error("no viable")
        }
      _ -> Error("not a pair")
    }
  })
}

fn init_grid(
  nodes: List(Node),
) -> Result(#(Position, Position, Set(Position)), String) {
  use empty <- try(
    nodes
    |> list.find(fn(node) { node.attr.used == 0 })
    |> replace_error("failed to find empty node"),
  )

  use target <- try(
    nodes
    |> list.sort(fn(a, b) {
      case int.compare(b.pos.x, a.pos.x) {
        order.Eq -> int.compare(a.pos.y, b.pos.y)
        o -> o
      }
    })
    |> list.first()
    |> replace_error("failed to find target node"),
  )

  // Only keep the nodes in the grid which their used data
  // could fit on every other node in the grid
  let grid =
    nodes
    |> list.filter(fn(node) {
      nodes
      |> list.filter(fn(other) { node.attr.used <= other.attr.size })
      |> list.length
      |> fn(l) { l == list.length(nodes) }
    })
    |> list.map(fn(node) { node.pos })
    |> set.from_list

  #(empty.pos, target.pos, grid)
  |> Ok
}

fn next_positions(position p: Position) -> List(Position) {
  [
    Position(p.x + 1, p.y),
    Position(p.x - 1, p.y),
    Position(p.x, p.y + 1),
    Position(p.x, p.y - 1),
  ]
}

fn diff(a: Int, b: Int) -> Int {
  int.max(a, b) - int.min(a, b)
}

fn distance(a: Position, b: Position) -> Int {
  diff(a.x, b.x) + diff(a.y, b.y)
}

/// Using BFS, find all the moves that will result in the target moving,
/// regardless of if that target is getting closer to (0, 0) or not
fn get_moves(
  heap: heap.Heap(State),
  grid: Set(Position),
  cache: Set(Position),
  moves: List(Move),
) -> List(Move) {
  use #(heap, state) <- heap.pop_guard(heap, moves)

  use <- bool.lazy_guard(cache |> set.contains(state.position), fn() {
    get_moves(heap, grid, cache, moves)
  })

  let cache = cache |> set.insert(state.position)

  let #(heap, moves) =
    state.position
    |> next_positions
    |> list.filter(fn(pos) { grid |> set.contains(pos) })
    |> list.fold(#(heap, moves), fn(acc, pos) {
      let #(heap, moves) = acc

      case pos == state.target {
        // If true, we found a move that resulted in the target
        // data moving from one node to another, add that to the solutions
        True -> #(
          heap,
          moves |> list.prepend(Move(state.steps + 1, pos, state.position)),
        )
        // Otherwise keep going..
        False -> {
          let next = State(state.steps + 1, pos, state.target)
          let heap = heap |> heap.insert(next)
          #(heap, moves)
        }
      }
    })

  get_moves(heap, grid, cache, moves)
}

fn solve(
  grid: Set(Position),
  empty: Position,
  target: Position,
) -> Result(Int, String) {
  // How far currently the target is to being at the
  // correct position
  let dist = distance(target, Position(0, 0))

  // get all the possible moves that result in the target
  // get closer to the correct position that what we currently
  // have
  let moves =
    heap.new(fn(a: State, b: State) { int.compare(a.steps, b.steps) })
    |> heap.insert(State(steps: 0, position: empty, target: target))
    |> get_moves(grid, set.new(), list.new())
    |> list.filter(fn(move) { distance(move.target, Position(0, 0)) < dist })

  // If we found a winning move, just return that. Otherwise, try again
  // for all moves and only keep the best
  case moves |> list.find(fn(move) { move.target == Position(0, 0) }) {
    Ok(move) -> Ok(move.steps)
    Error(_) -> {
      moves
      |> list.map(fn(move) {
        solve(grid, move.empty, move.target)
        |> result.map(fn(steps) { steps |> int.add(move.steps) })
      })
      |> list.filter_map(fn(move) { move })
      |> list.max(fn(a, b) { int.compare(b, a) })
      |> replace_error("failed to find a solution")
    }
  }
}

pub fn main(input: String) -> Result(Nil, String) {
  use nodes <- try(
    input
    |> parse,
  )

  nodes
  |> find_viable_pairs
  |> list.length
  |> int.to_string
  |> io.println

  use #(empty, target, grid) <- try(nodes |> init_grid)
  use p2 <- try(solve(grid, empty, target))

  p2
  |> int.to_string
  |> io.println

  Ok(Nil)
}
