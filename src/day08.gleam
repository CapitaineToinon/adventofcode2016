import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string

type Screen =
  List(List(String))

type Direction {
  Column
  Row
}

type Instruction {
  Rect(x: Int, y: Int)
  Rotate(direction: Direction, index: Int, by: Int)
}

fn parse_int(input: String) -> Result(Int, String) {
  input
  |> int.parse
  |> result.replace_error("failed to parse int")
}

fn parse_size(input: String) -> Result(Instruction, String) {
  use #(left, right) <- result.try(
    input
    |> string.split_once("x")
    |> result.replace_error("invalid size"),
  )

  use x <- result.try(left |> parse_int)
  use y <- result.try(right |> parse_int)

  Ok(Rect(x, y))
}

fn parse_rotation(
  input: String,
  direction: Direction,
) -> Result(Instruction, String) {
  use #(left, right) <- result.try(case input |> string.split(" ") {
    [index, "by", by] -> Ok(#(index, by))
    _ -> Error("invalid rotation")
  })

  use index <- result.try(left |> parse_int)
  use by <- result.try(right |> parse_int)

  Ok(Rotate(direction, index, by))
}

fn parse_instruction(input: String) -> Result(Instruction, String) {
  case input {
    "rect " <> size -> parse_size(size)
    "rotate column x=" <> instruction -> parse_rotation(instruction, Column)
    "rotate row y=" <> instruction -> parse_rotation(instruction, Row)
    _ -> Error("unknown instruction: " <> input)
  }
}

fn create_screen(width: Int, height: Int) -> Screen {
  int.range(0, height, [], fn(acc, _) {
    [int.range(0, width, [], fn(acc, _) { [".", ..acc] }), ..acc]
  })
}

fn print_screen(screen: Screen) -> Screen {
  screen
  |> list.map(fn(row) { row |> string.join("") })
  |> list.map(io.println)

  screen
}

fn run_rect(screen: Screen, x: Int, y: Int) -> Screen {
  screen
  |> list.index_map(fn(row, j) {
    case j < y {
      True -> {
        let head = list.repeat("#", x)
        let #(_, tail) = row |> list.split(x)

        head |> list.append(tail)
      }
      _ -> row
    }
  })
}

fn run_rotate_row(screen: Screen, y: Int, by: Int) -> Screen {
  screen
  |> list.index_map(fn(row, j) {
    case j == y {
      True -> rotate_list(row, by)
      False -> row
    }
  })
}

fn run_rotate_col(screen: Screen, x: Int, by: Int) -> Screen {
  screen
  |> list.transpose
  |> run_rotate_row(x, by)
  |> list.transpose
}

fn run_instruction(screen: Screen, instrction: Instruction) -> Screen {
  case instrction {
    Rect(x, y) -> screen |> run_rect(x, y)
    Rotate(Row, y, by) -> screen |> run_rotate_row(y, by)
    Rotate(Column, y, by) -> screen |> run_rotate_col(y, by)
  }
}

fn run_instructions(screen: Screen, instrctions: List(Instruction)) -> Screen {
  case instrctions {
    [next, ..rest] ->
      screen
      |> run_instruction(next)
      |> run_instructions(rest)
    _ -> screen
  }
}

/// from: https://github.com/gleam-lang/gleam/discussions/3959
fn rotate_list(list: List(a), n: Int) -> List(a) {
  let len = list.length(list)
  let idx = case n < 0 {
    False -> len - n
    True -> n
  }

  let #(h, t) = list.split(list, int.absolute_value(idx) % len)
  list.append(t, h)
}

fn count(screen: Screen) -> Int {
  screen
  |> list.map(fn(row) { row |> list.count(fn(cell) { cell == "#" }) })
  |> int.sum
}

pub fn main(input: String) -> Result(Nil, String) {
  use instructions <- result.try(
    input
    |> string.trim
    |> string.split("\n")
    |> list.map(parse_instruction)
    |> result.all,
  )

  create_screen(50, 6)
  |> run_instructions(instructions)
  |> print_screen
  |> count
  |> int.to_string
  |> io.println

  Ok(Nil)
}
