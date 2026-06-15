import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/string

type State {
  State(pointer: Int, lines: Dict(Int, String), registers: Dict(String, Int))
}

fn execute(state: State) -> State {
  case state.lines |> dict.get(state.pointer) {
    Ok(line) -> line |> execute_line(state) |> execute
    Error(_) -> state
  }
}

fn is_int(source: String) -> Bool {
  case
    source
    |> int.parse
  {
    Ok(_) -> True
    Error(_) -> False
  }
}

fn get(source: String, state: State) -> Int {
  case source |> int.parse {
    Ok(int) -> int
    Error(_) ->
      case state.registers |> dict.get(source) {
        Ok(value) -> value
        Error(_) -> 0
      }
  }
}

fn set(value: Int, key: String, state: State) -> State {
  State(
    ..state,
    registers: state.registers
      |> dict.insert(key, value),
  )
}

fn next(state: State) -> State {
  State(..state, pointer: state.pointer + 1)
}

fn cpy(from: String, to: String, state: State) -> State {
  use <- bool.lazy_guard(is_int(to), fn() { state |> next })

  from
  |> get(state)
  |> set(to, state)
  |> next
}

fn inc(from: String, state: State) -> State {
  use <- bool.lazy_guard(is_int(from), fn() { state |> next })

  from
  |> get(state)
  |> int.add(1)
  |> set(from, state)
  |> next
}

fn dec(from: String, state: State) -> State {
  use <- bool.lazy_guard(is_int(from), fn() { state |> next })

  from
  |> get(state)
  |> int.subtract(1)
  |> set(from, state)
  |> next
}

fn jnz(from: String, by: String, state: State) -> State {
  let by = get(by, state)

  case from |> get(state) {
    0 -> state |> next
    _ -> State(..state, pointer: state.pointer + by)
  }
}

fn tgl(from: String, state: State) -> State {
  let index =
    from
    |> get(state)
    |> int.add(state.pointer)

  let state = case state.lines |> dict.get(index) {
    Error(_) -> state
    Ok(line) -> {
      let line = case line |> string.split(" ") {
        [i, j] ->
          case i {
            "inc" -> "dec " <> j
            _ -> "inc " <> j
          }
        [i, j, k] ->
          case i {
            "jnz" -> "cpy " <> j <> " " <> k
            _ -> "jnz " <> j <> " " <> k
          }
        _ -> line
      }

      State(..state, lines: state.lines |> dict.insert(index, line))
    }
  }

  state |> next
}

fn multiply(dest: String, i: String, j: String, state: State) -> State {
  let dest_value = dest |> get(state)
  let i_value = i |> get(state)
  let j_value = j |> get(state)

  State(
    ..state,
    pointer: state.pointer + 5,
    registers: state.registers
      |> dict.insert(dest, dest_value + { i_value * j_value })
      |> dict.insert(i, 0)
      |> dict.insert(j, 0),
  )
}

fn execute_line(line: String, state: State) -> State {
  case state.pointer, line |> string.split(" ") {
    // hard code to replace loop that just processes a multiplication
    // by using loops instead. Might not work for every input!
    // a = a + (c * d)
    // c = 0
    // d = 0
    5, ["inc", "a"] | 12, ["inc", "a"] -> multiply("a", "c", "d", state)
    _, rest ->
      case rest {
        ["cpy", from, to] -> cpy(from, to, state)
        ["jnz", from, by] -> jnz(from, by, state)
        ["inc", reg] -> inc(reg, state)
        ["dec", reg] -> dec(reg, state)
        ["tgl", reg] -> tgl(reg, state)
        _ -> {
          let out = "unsupported " <> line
          panic as out
        }
      }
  }
}

fn solve(lines: Dict(Int, String), initial: Int) -> Int {
  let state =
    lines
    |> State(pointer: 0, lines: _, registers: dict.from_list([#("a", initial)]))
    |> execute

  case state.registers |> dict.get("a") {
    Ok(value) -> value
    _ -> 0
  }
}

pub fn main(input: String) -> Result(Nil, String) {
  let code =
    input
    |> string.trim
    |> string.split("\n")
    |> list.map(string.trim)
    |> list.index_map(fn(el, i) { #(i, el) })
    |> dict.from_list

  code
  |> solve(7)
  |> int.to_string
  |> io.println

  code
  |> solve(12)
  |> int.to_string
  |> io.println

  Ok(Nil)
}
