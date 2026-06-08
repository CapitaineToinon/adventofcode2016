import gleam/list
import gleam/string

fn next(a: String) -> String {
  a
  |> string.append("0")
  |> string.append(
    a
    |> string.reverse
    |> string.replace("1", "a")
    |> string.replace("0", "1")
    |> string.replace("a", "0"),
  )
}

fn fill_disk(seed: String, size: Int) -> String {
  let input = seed |> next

  case input |> string.length {
    i if i >= size -> input |> string.slice(0, size)
    _ -> fill_disk(input, size)
  }
}

fn find_pairs(
  input: List(String),
  rest: List(String),
  pairs: List(String),
) -> String {
  case rest {
    [] -> {
      let input = pairs |> list.reverse
      find_pairs(input, input, list.new())
    }
    [_] -> {
      input |> string.join("")
    }
    [a, b, ..rest] -> {
      let add = case a == b {
        True -> "1"
        False -> "0"
      }

      find_pairs(input, rest, pairs |> list.prepend(add))
    }
  }
}

fn checksum(input: String) -> String {
  let input = input |> string.split("")
  find_pairs(input, input, list.new())
}

fn solve(input: String) -> String {
  input
  |> fill_disk(35_651_584)
  |> checksum
}

pub fn main(input: String) -> Result(Nil, String) {
  input
  |> string.trim
  |> solve
  |> echo

  Ok(Nil)
}
