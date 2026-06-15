import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string

/// How many repeating 0,1 bits we want to see
/// before we accept the input as infinite
const target = 10

type State {
  State(p: Int, c: Dict(Int, String), r: Dict(String, Int))
}

fn get(state: State, source: String) -> Int {
  case source |> int.parse {
    Ok(value) -> value
    Error(_) ->
      case state.r |> dict.get(source) {
        Ok(value) -> value
        Error(_) -> 0
      }
  }
}

fn set(state: State, key: String, value: Int) -> State {
  State(
    ..state,
    r: state.r
      |> dict.insert(key, value),
  )
}

fn next(state: State) -> State {
  State(..state, p: state.p + 1)
}

fn execute(state: State) -> #(Int, State) {
  case state.c |> dict.get(state.p) {
    Ok(line) -> {
      case line |> string.split(" ") {
        ["cpy", a, b] -> {
          state
          |> get(a)
          |> set(state, b, _)
          |> next
          |> execute
        }
        ["inc", a] -> {
          state
          |> get(a)
          |> int.add(1)
          |> set(state, a, _)
          |> next
          |> execute
        }
        ["dec", a] -> {
          state
          |> get(a)
          |> int.subtract(1)
          |> set(state, a, _)
          |> next
          |> execute
        }
        ["jnz", a, by] -> {
          let by = state |> get(by)

          let state = case state |> get(a) {
            0 -> state |> next
            _ -> State(..state, p: state.p + by)
          }

          state
          |> execute
        }
        ["out", a] -> {
          // Stop executing, return the out and the state
          // such that the program can keep going later
          #(state |> get(a), state |> next)
        }
        _ -> {
          let out = "unknown line " <> line
          panic as out
        }
      }
    }
    Error(_) -> panic as "this program should run forever"
  }
}

fn is_depth(state: State, last: Option(Int), depth: Int, target: Int) -> Bool {
  use <- bool.guard(depth == target, True)

  let #(out, state) = state |> execute

  case last {
    None -> is_depth(state, Some(out), depth + 1, target)
    Some(last) ->
      case last, out {
        0, 1 | 1, 0 -> is_depth(state, Some(out), depth + 1, target)
        _, _ -> False
      }
  }
}

fn solve(code: Dict(Int, String), a: Int, target: Int) -> Int {
  let state = State(p: 0, c: code, r: dict.from_list([#("a", a)]))

  case is_depth(state, None, 0, target) {
    True -> a
    False -> solve(code, a + 1, target)
  }
}

pub fn main(input: String) -> Result(Nil, String) {
  let code =
    input
    |> string.trim
    |> string.split("\n")
    |> list.index_map(fn(line, i) { #(i, line) })
    |> dict.from_list

  code
  |> solve(0, target)
  |> int.to_string
  |> io.println

  Ok(Nil)
}
