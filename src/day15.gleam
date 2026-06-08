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

fn solve(discs: List(Disc), time: Int) -> Result(Int, String) {
  use rotated <- try(
    discs
    |> list.index_map(fn(disc, i) { rotate(disc, time + i + 1) })
    |> result.all,
  )

  case
    rotated
    |> list.all(fn(disc) { disc.position == 0 })
  {
    True -> Ok(time)
    False -> solve(discs, time + 1)
  }
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

  use p1 <- try(discs |> solve(0))

  p1
  |> int.to_string
  |> io.println

  use p2 <- try(discs |> append(Disc(11, 0)) |> solve(0))

  p2
  |> int.to_string
  |> io.println

  Ok(Nil)
}
