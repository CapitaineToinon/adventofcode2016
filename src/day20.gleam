import gleam/int
import gleam/io
import gleam/list
import gleam/order.{Eq}
import gleam/result.{try}
import gleam/string

type Range {
  Range(from: Int, to: Int)
}

type Ranges =
  List(Range)

fn parse_int(int: String) -> Result(Int, String) {
  int
  |> int.parse
  |> result.replace_error("failed to parse int " <> int)
}

fn parse_line(input: String) -> Result(Range, String) {
  use #(left, right) <- try(
    input
    |> string.trim
    |> string.split_once("-")
    |> result.replace_error("failed to split line " <> input),
  )

  use from <- try(left |> parse_int)
  use to <- try(right |> parse_int)

  Ok(Range(from, to))
}

fn parse_lines(input: String) -> Result(Ranges, String) {
  input
  |> string.trim
  |> string.split("\n")
  |> list.map(parse_line)
  |> result.all
  |> result.map(fn(ranges) {
    ranges
    |> sort_ranges
    |> fold_ranges(list.new())
  })
}

fn sort_ranges(ranges: Ranges) -> Ranges {
  ranges
  |> list.sort(fn(a, b) {
    case int.compare(a.from, b.from) {
      Eq -> int.compare(a.to, b.to)
      o -> o
    }
  })
}

fn fold_ranges(ranges: Ranges, output: Ranges) -> Ranges {
  case ranges {
    [a, b, ..rest] if b.from - 1 <= a.to -> {
      rest
      |> list.prepend(Range(a.from, int.max(a.to, b.to)))
      |> fold_ranges(output)
    }
    [a, ..rest] ->
      output
      |> list.prepend(a)
      |> fold_ranges(rest, _)
    [] ->
      output
      |> list.reverse
  }
}

fn find_lowest(ranges: Ranges) -> Result(Int, String) {
  case ranges {
    [lowest, ..] -> Ok(lowest.to + 1)
    _ -> Error("ranges cannot be empty")
  }
}

/// This code assumes the min and max values are
/// in the ranges, which is the case for the input
/// but not for the example input. For example, the
/// example inputs only has ranges 0-2, 4-8 but asks
/// how many are valid between 0-10. However, this
/// code would only count valid items between 0-8.
fn count_allowed(ranges: Ranges) -> Int {
  ranges
  |> list.window(2)
  |> list.fold(0, fn(acc, win) {
    acc
    + case win {
      [a, b] -> b.from - a.to - 1
      _ -> 0
    }
  })
}

pub fn main(input: String) -> Result(Nil, String) {
  use ranges <- try(input |> parse_lines)

  use p1 <- try(
    ranges
    |> find_lowest,
  )

  p1
  |> int.to_string
  |> io.println

  ranges
  |> count_allowed
  |> int.to_string
  |> io.println

  Ok(Nil)
}
