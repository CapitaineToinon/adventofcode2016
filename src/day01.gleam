import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string

type CardinalDirection {
  North
  East
  South
  West
}

type RelativeDirection {
  Right
  Left
}

type Position {
  Position(x: Int, y: Int)
}

type State {
  State(dir: CardinalDirection, pos: Position)
}

type Move {
  Move(dir: RelativeDirection, by: Int)
}

fn turn(s: State, t: Move) -> State {
  let dir = case s.dir, t.dir {
    North, Right | South, Left -> East
    East, Right | West, Left -> South
    North, Left | South, Right -> West
    West, Right | East, Left -> North
  }

  State(dir, s.pos)
}

fn step_by(s: State, m: Move) -> State {
  let #(x, y) = case s.dir {
    North -> #(s.pos.x, s.pos.y + m.by)
    East -> #(s.pos.x + m.by, s.pos.y)
    South -> #(s.pos.x, s.pos.y - m.by)
    West -> #(s.pos.x - m.by, s.pos.y)
  }

  State(s.dir, Position(x, y))
}

fn parse_move(input: String) -> Result(Move, String) {
  use #(dir, by) <- result.try(case input {
    "R" <> by -> Ok(#(Right, by))
    "L" <> by -> Ok(#(Left, by))
    _ -> Error("invalid move in the path: " <> input)
  })

  use i <- result.try(
    int.parse(by) |> result.replace_error("failed to parse move"),
  )

  Ok(Move(dir, i))
}

fn get_state_distance(state: State) -> Int {
  get_distance(state.pos)
}

fn get_distance(position: Position) -> Int {
  int.absolute_value(position.x) + int.absolute_value(position.y)
}

fn next(s: State, m: Move) -> State {
  s |> turn(m) |> step_by(m)
}

fn get_positions_between(
  from: Position,
  to: Position,
) -> Result(List(Position), String) {
  case from, to {
    Position(x1, y1), Position(x2, y2) if x1 == x2 ->
      int.range(y1, y2, [], fn(acc, i) { [Position(x1, i), ..acc] })
      |> Ok
    Position(x1, y1), Position(x2, y2) if y1 == y2 ->
      int.range(x1, x2, [], fn(acc, i) { [Position(i, y1), ..acc] })
      |> Ok
    _, _ -> Error("positions need to be aligned vertically or horizontally")
  }
}

fn find_first_repeat(
  positions: List(Position),
  cache: dict.Dict(Position, Bool),
) -> Result(Position, String) {
  case positions {
    [head, ..tail] ->
      case dict.get(cache, head) {
        Ok(True) -> Ok(head)
        _ -> find_first_repeat(tail, dict.insert(cache, head, True))
      }
    _ -> Error("failed to find a position visisted twice")
  }
}

fn compute_states(moves: List(Move)) -> List(State) {
  moves
  |> list.fold([State(North, Position(0, 0))], fn(states, move) {
    case states {
      [head, ..tail] -> [next(head, move), head, ..tail]
      _ -> []
    }
  })
  |> list.reverse
}

fn part_1(states: List(State)) -> Result(Int, String) {
  use final <- result.try(
    states
    |> list.last
    |> result.replace_error("list of states cannot be empty"),
  )

  Ok(get_state_distance(final))
}

fn part_2(states: List(State)) -> Result(Int, String) {
  use positions <- result.try(result.all(
    states
    |> list.window_by_2
    |> list.map(fn(window) {
      let #(from, to) = window
      get_positions_between(from.pos, to.pos)
    }),
  ))

  use position <- result.try(
    positions
    |> list.map(list.reverse)
    |> list.flatten
    |> find_first_repeat(dict.new()),
  )

  Ok(get_distance(position))
}

pub fn main(input: String) -> Result(Nil, String) {
  use moves <- result.try(result.all(
    string.split(input, ",")
    |> list.map(string.trim)
    |> list.map(parse_move),
  ))

  let states = moves |> compute_states

  use p1 <- result.try(part_1(states))
  use p2 <- result.try(part_2(states))

  io.println(int.to_string(p1))
  io.println(int.to_string(p2))

  Ok(Nil)
}
