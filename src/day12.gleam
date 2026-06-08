import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/result.{try}
import gleam/string

type Source {
  Register(String)
  Value(Int)
}

type Instruction {
  Cpy(Source, String)
  Inc(String)
  Dec(String)
  Jnz(Source, Int)
}

type State {
  State(pointer: Int, registers: Dict(String, Int))
}

fn parse_source(source: String) -> Source {
  case int.parse(source) {
    Ok(value) -> Value(value)
    Error(_) -> Register(source)
  }
}

fn parse_cpy(cpy: String) -> Result(Instruction, String) {
  case cpy |> string.split(" ") {
    [source, dest] -> {
      let source = parse_source(source)
      Ok(Cpy(source, dest))
    }
    _ -> Error("invalid cpy instruction " <> cpy)
  }
}

fn parse_jnz(jnz: String) -> Result(Instruction, String) {
  case jnz |> string.split(" ") {
    [source, value] -> {
      let source = parse_source(source)

      use value <- try(
        value
        |> int.parse
        |> result.replace_error("failed to parse value " <> value),
      )

      Ok(Jnz(source, value))
    }
    _ -> Error("invalid jnz instruction " <> jnz)
  }
}

fn parse_line(line: String) -> Result(Instruction, String) {
  case line {
    "cpy " <> cpy -> parse_cpy(cpy)
    "jnz " <> jnz -> parse_jnz(jnz)
    "inc " <> dest -> Ok(Inc(dest))
    "dec " <> dest -> Ok(Dec(dest))
    unknown -> Error("unknown instruction " <> unknown)
  }
}

fn parse(input: List(String)) -> Result(Dict(Int, Instruction), String) {
  input
  |> list.index_fold(Ok(dict.new()), fn(acc, line, i) {
    use acc <- try(acc)
    use instruction <- try(parse_line(line))
    Ok(dict.insert(acc, i, instruction))
  })
}

fn get(state: State, register: Source) -> Int {
  case register {
    Value(value) -> value
    Register(name) ->
      case dict.get(state.registers, name) {
        Ok(value) -> value
        Error(_) -> 0
      }
  }
}

fn set(state: State, register: String, value: Int) -> State {
  let registers = state.registers |> dict.insert(register, value)
  State(..state, registers: registers)
}

fn next(state: State) -> State {
  State(..state, pointer: state.pointer + 1)
}

fn execute(program: Dict(Int, Instruction), state: State) -> State {
  case program |> dict.get(state.pointer) {
    Error(_) -> state
    Ok(instruction) -> {
      let state = case instruction {
        Cpy(from, to) ->
          state
          |> get(from)
          |> set(state, to, _)
          |> next
        Inc(name) ->
          state
          |> get(Register(name))
          |> int.add(1)
          |> set(state, name, _)
          |> next
        Dec(name) ->
          state
          |> get(Register(name))
          |> int.subtract(1)
          |> set(state, name, _)
          |> next
        Jnz(from, by) -> {
          case
            state
            |> get(from)
          {
            0 -> state |> next
            _ -> State(..state, pointer: state.pointer + by)
          }
        }
      }

      execute(program, state)
    }
  }
}

pub fn main(input: String) -> Result(Nil, String) {
  use instructions <- try(
    input
    |> string.trim
    |> string.split("\n")
    |> list.map(string.trim)
    |> parse,
  )

  instructions
  |> execute(State(0, dict.new()))
  |> get(Register("a"))
  |> int.to_string
  |> io.println

  instructions
  |> execute(State(0, dict.from_list([#("c", 1)])))
  |> get(Register("a"))
  |> int.to_string
  |> io.println

  Ok(Nil)
}
