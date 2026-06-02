import gleam/dict.{type Dict}
import gleam/io
import gleam/list
import gleam/result
import gleam/string

type Direction {
  Up
  Right
  Down
  Left
}

type Position {
  Position(x: Int, y: Int)
}

type Keypad =
  Dict(Position, String)

fn get_k1() -> Keypad {
  dict.from_list([
    #(Position(0, 0), "1"),
    #(Position(1, 0), "2"),
    #(Position(2, 0), "3"),
    #(Position(0, 1), "4"),
    #(Position(1, 1), "5"),
    #(Position(2, 1), "6"),
    #(Position(0, 2), "7"),
    #(Position(1, 2), "8"),
    #(Position(2, 2), "9"),
  ])
}

fn get_k2() -> Keypad {
  dict.from_list([
    #(Position(2, 0), "1"),
    #(Position(1, 1), "2"),
    #(Position(2, 1), "3"),
    #(Position(3, 1), "4"),
    #(Position(0, 2), "5"),
    #(Position(1, 2), "6"),
    #(Position(2, 2), "7"),
    #(Position(3, 2), "8"),
    #(Position(4, 2), "9"),
    #(Position(1, 3), "A"),
    #(Position(2, 3), "B"),
    #(Position(3, 3), "C"),
    #(Position(2, 4), "D"),
  ])
}

fn get_key(value: String, keypad: Keypad) -> Result(Position, String) {
  use #(position, _) <- result.try(
    keypad
    |> dict.to_list
    |> list.find(fn(el) {
      let #(_, v) = el
      v == value
    })
    |> result.replace_error("failed to find value in keypad: " <> value),
  )

  Ok(position)
}

fn get_value(key: Position, keypad: Keypad) -> Result(String, String) {
  dict.get(keypad, key)
  |> result.replace_error("failed to find key in keypad")
}

fn parse_direction(direction: String) -> Result(Direction, String) {
  case direction {
    "U" -> Ok(Up)
    "R" -> Ok(Right)
    "D" -> Ok(Down)
    "L" -> Ok(Left)
    _ -> Error("unknown direction: " <> direction)
  }
}

fn parse_directions(
  directions: String,
) -> Result(List(List(Direction)), String) {
  directions
  |> string.trim
  |> string.split("\n")
  |> list.map(fn(line) {
    string.split(line, "") |> list.map(parse_direction) |> result.all
  })
  |> result.all
}

fn move(p: Position, d: Direction, keypad: Keypad) -> Position {
  let next = case d {
    Up -> Position(p.x, p.y - 1)
    Down -> Position(p.x, p.y + 1)
    Left -> Position(p.x - 1, p.y)
    Right -> Position(p.x + 1, p.y)
  }

  case dict.get(keypad, next) {
    Ok(_) -> next
    _ -> p
  }
}

fn apply_moves(
  start: Position,
  moves: List(Direction),
  keypad: Keypad,
) -> Position {
  moves |> list.fold(start, fn(acc, dir) { move(acc, dir, keypad) })
}

fn solve(
  directions: List(List(Direction)),
  keypad: Keypad,
) -> Result(String, String) {
  use start <- result.try(get_key("5", keypad))

  let #(_, output) =
    directions
    |> list.fold(#(start, []), fn(state, line) {
      let #(cur, output) = state
      let next = apply_moves(cur, line, keypad)
      #(next, [get_value(next, keypad), ..output])
    })

  use digits <- result.try(output |> result.all)

  Ok(digits |> string.concat |> string.reverse)
}

pub fn main(input: String) -> Result(Nil, String) {
  use directions <- result.try(parse_directions(input))

  use p1 <- result.try(solve(directions, get_k1()))
  use p2 <- result.try(solve(directions, get_k2()))

  io.println(p1)
  io.println(p2)

  Ok(Nil)
}
