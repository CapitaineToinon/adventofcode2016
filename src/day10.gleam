import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string

type ComparedBy =
  Dict(#(Int, Int), String)

type Bots =
  Dict(String, List(Int))

type Outputs =
  Dict(String, Int)

type Dest {
  Bot(id: String)
  Output(id: String)
}

type Rule {
  Rule(low: Dest, high: Dest)
}

type Rules =
  Dict(String, Rule)

type State {
  State(bots: Bots, rules: Rules, outputs: Outputs)
}

fn new_state() -> State {
  State(dict.new(), dict.new(), dict.new())
}

fn update_bots(state: State, bots: Bots) -> State {
  State(..state, bots: bots)
}

fn update_rules(state: State, rules: Rules) -> State {
  State(..state, rules: rules)
}

fn update_outputs(state: State, outputs: Outputs) -> State {
  State(..state, outputs: outputs)
}

fn get_destination(name: String, id: String) -> Result(Dest, String) {
  case name {
    "bot" -> Ok(Bot(id))
    "output" -> Ok(Output(id))
    _ -> Error("invalid destination " <> name)
  }
}

fn get_output(state: State, id: String) -> Result(Int, String) {
  state.outputs
  |> dict.get(id)
  |> result.replace_error("failed to find a value for output " <> id)
}

fn remove_bot(state: State, bot: String) -> State {
  let bots = state.bots |> dict.delete(bot)
  state |> update_bots(bots)
}

fn add_rule(state: State, bot: String, rule: Rule) -> Result(State, String) {
  use rules <- result.try(case state.rules |> dict.get(bot) {
    Ok(_) -> Error("bot already has a rule defined")
    Error(_) -> Ok(dict.insert(state.rules, bot, rule))
  })

  Ok(state |> update_rules(rules))
}

fn add_value(state: State, dest: Dest, value: Int) -> Result(State, String) {
  case dest {
    Bot(id) -> state |> add_bot_value(id, value)
    Output(id) -> state |> add_output_value(id, value)
  }
}

fn add_bot_value(
  state: State,
  bot: String,
  value: Int,
) -> Result(State, String) {
  let values = case state.bots |> dict.get(bot) {
    Ok(values) -> values
    _ -> list.new()
  }

  use bots <- result.try(case values {
    [_, _] -> Error("bot already has 2 values")
    values -> Ok(state.bots |> dict.insert(bot, [value, ..values]))
  })

  Ok(state |> update_bots(bots))
}

fn add_output_value(
  state: State,
  bot: String,
  value: Int,
) -> Result(State, String) {
  use outputs <- result.try(case state.outputs |> dict.get(bot) {
    Ok(_) -> Error("output already has a value")
    Error(_) -> Ok(state.outputs |> dict.insert(bot, value))
  })

  Ok(state |> update_outputs(outputs))
}

fn process_line(line: String, state: State) -> Result(State, String) {
  case line |> string.split(" ") {
    ["value", value, "goes", "to", "bot", bot] -> {
      use value <- result.try(
        value
        |> int.parse
        |> result.replace_error("failed to parse value " <> value),
      )

      state |> add_bot_value(bot, value)
    }
    [
      "bot",
      bot,
      "gives",
      "low",
      "to",
      low,
      low_id,
      "and",
      "high",
      "to",
      high,
      high_id,
    ] -> {
      use low <- result.try(get_destination(low, low_id))
      use high <- result.try(get_destination(high, high_id))
      state |> add_rule(bot, Rule(low, high))
    }
    _ -> Error("unvalid line: " <> line)
  }
}

fn parse_state(lines: List(String), state: State) -> Result(State, String) {
  case lines {
    [line, ..rest] -> {
      use state <- result.try(process_line(line, state))
      parse_state(rest, state)
    }
    [] -> Ok(state)
  }
}

fn exhaust_bot(
  state: State,
  compared_by: ComparedBy,
  bot: String,
  values: List(Int),
) -> Result(#(State, ComparedBy), String) {
  case values {
    [v1, v2] -> {
      use rule <- result.try(
        dict.get(state.rules, bot)
        |> result.replace_error("failed to find a rule for bot " <> bot),
      )

      let min = int.min(v1, v2)
      let max = int.max(v1, v2)

      let state = state |> remove_bot(bot)
      use state <- result.try(state |> add_value(rule.low, min))
      use state <- result.try(state |> add_value(rule.high, max))

      let compared_by =
        compared_by
        |> dict.insert(#(v1, v2), bot)
        |> dict.insert(#(v2, v1), bot)

      Ok(#(state, compared_by))
    }
    // skip the bot for now as it doesn't have two
    // values yet, it will have in the future
    _ -> Ok(#(state, compared_by))
  }
}

fn exhaust_bots(
  state: State,
  compared_by: ComparedBy,
) -> Result(#(State, ComparedBy), String) {
  use <- bool.guard(dict.is_empty(state.bots), Ok(#(state, compared_by)))

  use #(state, compared_by) <- result.try(
    state.bots
    |> dict.to_list
    |> list.fold(Ok(#(state, compared_by)), fn(acc, bot) {
      let #(id, values) = bot
      use #(state, compared_by) <- result.try(acc)
      exhaust_bot(state, compared_by, id, values)
    }),
  )

  exhaust_bots(state, compared_by)
}

pub fn main(input: String) -> Result(Nil, String) {
  let lines =
    input
    |> string.trim
    |> string.split("\n")
    |> list.map(string.trim)

  use state <- result.try(
    lines
    |> parse_state(new_state()),
  )

  use #(state, compared_by) <- result.try(
    state
    |> exhaust_bots(dict.new()),
  )

  use p1 <- result.try(
    compared_by
    |> dict.get(#(61, 17))
    |> result.replace_error("failed to find bot which compared chips requested"),
  )

  use out_1 <- result.try(state |> get_output("0"))
  use out_2 <- result.try(state |> get_output("1"))
  use out_3 <- result.try(state |> get_output("2"))

  let p2 = out_1 * out_2 * out_3

  p1 |> io.println
  p2 |> int.to_string |> io.println

  Ok(Nil)
}
