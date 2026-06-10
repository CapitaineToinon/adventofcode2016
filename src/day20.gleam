import gleam/int
import gleam/list
import gleam/order.{Eq}
import gleam/result.{try}
import gleam/string

type Range {
  Range(from: Int, to: Int)
}

type Ranges(state) {
  Ranges(items: List(Range))
}

type Unsorted

type Sorted

type SortedFolded

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

fn parse_lines(input: String) -> Result(Ranges(Unsorted), String) {
  input
  |> string.trim
  |> string.split("\n")
  |> list.map(parse_line)
  |> result.all
  |> result.map(Ranges)
}

fn sort_ranges(ranges: Ranges(Unsorted)) -> Ranges(Sorted) {
  ranges.items
  |> list.sort(fn(a, b) {
    case int.compare(a.from, b.from) {
      Eq -> int.compare(a.to, b.to)
      o -> o
    }
  })
  |> Ranges
}

fn fold_ranges(ranges: Ranges(Sorted)) -> Ranges(SortedFolded) {
  let folded = case ranges.items {
    // if ranges are empty, then it's already folded
    [] -> ranges.items
    [a, ..rest] -> {
      rest
      |> list.fold([a], fn(acc, current) {
        case acc {
          [last, ..rest] -> {
            // ranges overlap so merges them into 
            // a single range
            case current.from <= last.to + 1 {
              True -> {
                let next = Range(last.from, int.max(last.to, current.to))
                rest |> list.prepend(next)
              }
              False -> acc |> list.prepend(current)
            }
          }
          // ranges don't overlap, just append
          // to keep the order as is
          _ -> acc |> list.prepend(current)
        }
      })
      |> list.reverse
    }
  }

  Ranges(folded)
}

fn find_lowest(ranges: Ranges(SortedFolded)) -> Result(Int, String) {
  case ranges.items {
    [lowest, ..] -> Ok(lowest.to + 1)
    _ -> Error("ranges cannot be empty")
  }
}

/// This code assumes the min and max values are
/// in the ranges, which is the case for the input
/// but not for the example input
fn count_allowed(ranges: Ranges(SortedFolded)) -> Int {
  ranges.items
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

  let ranges =
    ranges
    |> sort_ranges
    |> fold_ranges

  ranges
  |> find_lowest
  |> echo

  ranges
  |> count_allowed
  |> echo

  Ok(Nil)
}
