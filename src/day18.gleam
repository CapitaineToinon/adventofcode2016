import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string

type Tile {
  Trap
  Safe
  Out
}

fn parse(input: String) -> Result(List(Tile), String) {
  input
  |> string.trim
  |> string.split("")
  |> list.map(fn(s) {
    case s {
      "." -> Ok(Safe)
      "^" -> Ok(Trap)
      _ -> Error("invalid input " <> input)
    }
  })
  |> result.all
}

fn next_tile(tiles: List(Tile)) -> Tile {
  // a new tile is a trap only in one of the following situations:
  case tiles {
    // Its left and center tiles are traps, but its right tile is not.
    [Trap, Trap, Safe] | [Trap, Trap, Out] -> Trap
    // Its center and right tiles are traps, but its left tile is not.
    [Safe, Trap, Trap] | [Out, Trap, Trap] -> Trap
    // Only its left tile is a trap.
    [Trap, Safe, Safe] | [Trap, Safe, Out] -> Trap
    // Only its right tile is a trap.
    [Safe, Safe, Trap] | [Out, Safe, Trap] -> Trap
    // Safe otherwise
    _ -> Safe
  }
}

fn next_tiles(tiles: List(Tile)) -> List(Tile) {
  tiles
  |> slide
  |> list.map(next_tile)
}

fn slide(tiles: List(Tile)) -> List(List(Tile)) {
  [Out]
  |> list.append(tiles)
  |> list.append([Out])
  |> list.window(3)
}

fn count_safe(tiles: List(Tile)) -> Int {
  tiles
  |> list.count(fn(t) { t == Safe })
}

fn count_safe_n(tiles: List(Tile), n: Int, total: Int) -> Int {
  let safe = tiles |> count_safe
  let total = total + safe

  case n {
    n if n <= 1 -> total
    _ -> {
      count_safe_n(tiles |> next_tiles, n - 1, total)
    }
  }
}

pub fn main(input: String) -> Result(Nil, String) {
  use tiles <- result.try(parse(input))

  tiles
  |> count_safe_n(40, 0)
  |> int.to_string
  |> io.println

  tiles
  |> count_safe_n(400_000, 0)
  |> int.to_string
  |> io.println

  Ok(Nil)
}
