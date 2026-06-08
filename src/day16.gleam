import gleam/io
import gleam/list
import gleam/result
import gleam/string

type Bit {
  One
  Zero
}

fn slice(array: List(Bit), n: Int) -> List(Bit) {
  array
  |> list.sized_chunk(n)
  |> list.first
  |> result.unwrap(array)
}

fn invert(array: List(Bit)) -> List(Bit) {
  array
  |> list.map(fn(bit) {
    case bit {
      One -> Zero
      Zero -> One
    }
  })
}

fn to_string(bits: List(Bit)) -> String {
  bits
  |> list.map(fn(bit) {
    case bit {
      One -> "1"
      Zero -> "0"
    }
  })
  |> string.join("")
}

fn next(a: List(Bit), size: Int) -> #(List(Bit), Int) {
  let next =
    a
    |> list.append([Zero])
    |> list.append(a |> list.reverse |> invert)

  #(next, size + size + 1)
}

fn fill_disk(seed: List(Bit), size: Int, target: Int) -> List(Bit) {
  let #(bits, size) = seed |> next(size)

  case size >= target {
    True -> bits |> slice(target)
    _ -> fill_disk(bits, size, target)
  }
}

fn find_pairs(
  input: List(Bit),
  rest: List(Bit),
  pairs: List(Bit),
) -> List(Bit) {
  case rest {
    [] -> {
      let input = pairs |> list.reverse
      find_pairs(input, input, list.new())
    }
    [_] -> input
    [a, b, ..rest] -> {
      let add = case a == b {
        True -> One
        False -> Zero
      }

      find_pairs(input, rest, pairs |> list.prepend(add))
    }
  }
}

fn checksum(input: List(Bit)) -> List(Bit) {
  find_pairs(input, input, list.new())
}

fn solve(bits: List(Bit), size: Int, target: Int) -> String {
  bits
  |> fill_disk(size, target)
  |> checksum
  |> to_string
}

fn parse_input(input: String) -> Result(#(List(Bit), Int), String) {
  use bits <- result.try(
    input
    |> string.trim
    |> string.split("")
    |> list.map(fn(char) {
      case char {
        "1" -> Ok(One)
        "0" -> Ok(Zero)
        _ -> Error("invalid input " <> input)
      }
    })
    |> result.all,
  )

  Ok(#(bits, bits |> list.length))
}

pub fn main(input: String) -> Result(Nil, String) {
  use #(bits, size) <- result.try(input |> parse_input)

  solve(bits, size, 272) |> io.println
  solve(bits, size, 35_651_584) |> io.println

  Ok(Nil)
}
