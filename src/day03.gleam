import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string

fn parse_triangle(input: String) -> Result(List(Int), String) {
  input
  |> string.trim
  |> string.split(" ")
  |> list.map(string.trim)
  |> list.filter(fn(s) { !string.is_empty(s) })
  |> list.map(int.parse)
  |> result.all
  |> result.replace_error("failed to parse triangle")
}

fn parse_triangles(input: String) -> Result(List(List(Int)), String) {
  input
  |> string.trim
  |> string.split("\n")
  |> list.map(parse_triangle)
  |> result.all
}

fn is_valid(t: List(Int)) -> Bool {
  case t {
    [a, b, c] -> a + b > c && b + c > a && c + a > b
    _ -> False
  }
}

fn are_valid(triangles: List(List(Int))) -> Int {
  triangles |> list.filter(is_valid) |> list.length
}

pub fn main(input: String) -> Result(Nil, String) {
  use triangles <- result.try(parse_triangles(input))

  let transpoed =
    triangles
    |> list.transpose
    |> list.flatten
    |> list.sized_chunk(3)

  let p1 = triangles |> are_valid
  let p2 = transpoed |> are_valid

  io.println(int.to_string(p1))
  io.println(int.to_string(p2))

  Ok(Nil)
}
