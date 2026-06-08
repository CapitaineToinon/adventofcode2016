import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/result.{try}
import gleam/string

type Disc {
  Disc(n: Int, position: Int)
}

fn parse_int(int: String) -> Result(Int, String) {
  int.parse(int)
  |> result.replace_error("failed to parse int")
}

fn parse_line(line: String) -> Result(Disc, String) {
  case
    line
    |> string.replace(".", "")
    |> string.split(" ")
  {
    [
      "Disc",
      _,
      "has",
      n,
      "positions;",
      "at",
      "time=0,",
      "it",
      "is",
      "at",
      "position",
      p,
    ] -> {
      use n <- try(parse_int(n))
      use p <- try(parse_int(p))
      Ok(Disc(n, p))
    }
    _ -> Error("unknown line " <> line)
  }
}

fn parse_lines(lines: List(String)) {
  lines
  |> list.map(parse_line)
  |> result.all
}

fn rotate(disc: Disc, by: Int) -> Result(Disc, String) {
  use position <- try(
    disc.position
    |> int.add(by)
    |> int.modulo(disc.n)
    |> result.replace_error("failed to rotate disc"),
  )

  Ok(Disc(..disc, position: position))
}

fn is_aligned(disc: Disc) -> Bool {
  disc.position == 0
}

fn compute_start(discs: List(Disc)) -> Result(#(Int, Int), String) {
  use #(size, position, i) <- try(
    discs
    |> list.index_map(fn(disc, i) { #(disc.n, disc.position, i) })
    |> list.max(fn(a, b) { int.compare(a.0, b.0) })
    |> result.replace_error("list is empty"),
  )

  use start <- try(
    size
    |> int.subtract(position)
    |> int.subtract(i)
    |> int.subtract(1)
    |> int.modulo(size)
    |> result.replace_error("failed to compute start"),
  )

  Ok(#(start, size))
}

fn solve(discs: List(Disc)) -> Result(Int, String) {
  use #(start, by) <- try(discs |> compute_start)
  discs |> next(start, by)
}

fn next(discs: List(Disc), start: Int, by: Int) -> Result(Int, String) {
  use rotated <- try(
    discs
    |> list.index_map(fn(disc, i) { rotate(disc, start + i + 1) })
    |> result.all,
  )

  use <- bool.guard(rotated |> list.all(is_aligned), Ok(start))
  next(discs, start + by, by)
}

fn append(list: List(a), elem: a) -> List(a) {
  list
  |> list.reverse
  |> list.prepend(elem)
  |> list.reverse
}

pub fn main(input: String) -> Result(Nil, String) {
  use discs <- try(
    input
    |> string.trim
    |> string.split("\n")
    |> parse_lines,
  )

  use p1 <- try(discs |> solve)

  p1
  |> int.to_string
  |> io.println

  use p2 <- try(discs |> append(Disc(11, 0)) |> solve)

  p2
  |> int.to_string
  |> io.println

  Ok(Nil)
}
