import gleam/int
import gleam/result
import gleam/string

fn is_bit_set(n: Int, bit: Int) {
  case n |> int.bitwise_shift_right(bit) |> int.bitwise_and(1) {
    1 -> True
    _ -> False
  }
}

fn get_higest_bit(n: Int, size: Int) -> Int {
  case is_bit_set(n, size - 1) {
    True -> size - 1
    False -> get_higest_bit(n, size - 1)
  }
}

/// implementation of https://en.wikipedia.org/wiki/Josephus_problem
fn josephus(n: Int) -> Int {
  let l = n - { 1 |> int.bitwise_shift_left(get_higest_bit(n, 32)) }
  { 2 * l } + 1
}

fn largest_power_of_3(n: Int) -> Int {
  case n / 3 {
    0 -> 1
    m -> 3 * largest_power_of_3(m)
  }
}

fn part_2(n: Int) -> Int {
  let p = largest_power_of_3(n)
  case n == p {
    True -> n
    False ->
      case n <= 2 * p {
        True -> n - p
        False -> 2 * n - 3 * p
      }
  }
}

pub fn main(input: String) -> Result(Nil, String) {
  use input <- result.try(
    input
    |> string.trim
    |> int.parse
    |> result.replace_error("failed to parse input"),
  )

  echo josephus(input)
  echo part_2(input)

  Ok(Nil)
}
