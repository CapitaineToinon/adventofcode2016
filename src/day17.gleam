import gleam/bit_array
import gleam/bool
import gleam/crypto
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order
import gleam/result
import gleam/string
import heap

type Direction {
  Up
  Down
  Left
  Right
}

type Solution {
  Solution(shortest: String, longest: Int)
}

fn md5(input: String) -> String {
  crypto.hash(crypto.Md5, <<input:utf8>>)
  |> bit_array.base16_encode
  |> string.lowercase
}

fn move(x: Int, y: Int, dir: Direction) -> #(Int, Int) {
  case dir {
    Up -> #(x, y - 1)
    Down -> #(x, y + 1)
    Left -> #(x - 1, y)
    Right -> #(x + 1, y)
  }
}

fn add_path(path: String, dir: Direction) -> String {
  let char = case dir {
    Up -> "U"
    Down -> "D"
    Left -> "L"
    Right -> "R"
  }

  path <> char
}

fn get_directions(input: String) -> List(Direction) {
  input
  |> md5
  |> string.split("")
  |> list.zip([Up, Down, Left, Right])
  |> list.filter_map(fn(a) {
    case "bcdef" |> string.contains(a.0) {
      True -> Ok(a.1)
      False -> Error("skip direction")
    }
  })
}

fn is_bounded(pos: #(Int, Int), end: #(Int, Int)) -> Bool {
  0 <= pos.0 && pos.0 <= end.0 && 0 <= pos.1 && pos.1 <= end.1
}

fn update_solution(
  solution: Option(Solution),
  path: String,
  steps: Int,
) -> Solution {
  case solution {
    None -> Solution(path, steps)
    Some(Solution(path, longest)) -> Solution(path, int.max(steps, longest))
  }
}

fn solve(
  input: String,
  end: #(Int, Int),
  solution: Option(Solution),
  heap: heap.Heap(#(Int, Int, Int, String)),
) -> Option(Solution) {
  case heap |> heap.pop_min {
    Ok(#(heap, #(steps, x, y, path))) -> {
      use <- bool.lazy_guard(#(x, y) == end, fn() {
        Some(update_solution(solution, path, steps))
        |> solve(input, end, _, heap)
      })

      get_directions(input <> path)
      |> list.filter_map(fn(dir) {
        let #(x, y) = move(x, y, dir)

        case is_bounded(#(x, y), end) {
          True -> Ok(#(x, y, dir))
          False -> Error("out of bounds")
        }
      })
      |> list.fold(heap, fn(acc, pos) {
        let #(x, y, dir) = pos
        acc |> heap.insert(#(steps + 1, x, y, add_path(path, dir)))
      })
      |> solve(input, end, solution, _)
    }
    Error(_) -> solution
  }
}

fn cmp(a: #(Int, Int, Int, String), b: #(Int, Int, Int, String)) {
  int.compare(a.0, b.0)
}

fn new_heap() {
  heap.new(order.reverse(cmp))
  |> heap.insert(#(0, 0, 0, ""))
}

pub fn main(input: String) -> Result(Nil, String) {
  use solution <- result.try(
    input
    |> string.trim
    |> solve(#(3, 3), None, new_heap())
    |> option.to_result("failed to find solution"),
  )

  solution.shortest |> io.println
  solution.longest |> int.to_string |> io.println

  Ok(Nil)
}
