import gleam/int
import gleam/io
import gleam/list
import gleam/order
import gleam/result
import gleam/string

fn solve(
  input: String,
  by: fn(Int, Int) -> order.Order,
) -> Result(String, String) {
  use characters <- result.try(
    input
    |> string.trim
    |> string.split("\n")
    |> list.map(string.trim)
    |> list.map(fn(e) { e |> string.split("") })
    |> list.transpose
    |> list.map(fn(col) {
      col
      |> list.unique
      |> list.fold([], fn(acc, char) {
        acc |> list.prepend(#(char, col |> list.count(fn(s) { s == char })))
      })
      |> list.max(fn(a, b) { by(a.1, b.1) })
    })
    |> result.all
    |> result.replace_error("failed to decode message"),
  )

  let message =
    characters
    |> list.map(fn(el) { el.0 })
    |> string.join("")

  Ok(message)
}

pub fn main(input: String) -> Result(Nil, String) {
  use p1 <- result.try(solve(input, int.compare))
  use p2 <- result.try(solve(input, fn(a, b) { int.compare(b, a) }))

  io.println(p1)
  io.println(p2)

  Ok(Nil)
}
