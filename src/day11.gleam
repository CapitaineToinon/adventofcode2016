import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order
import gleam/result.{replace_error, try}
import gleam/set.{type Set}
import gleam/string
import heap

type State {
  State(elevator: Int, pairs: List(#(Int, Int)))
}

type Item {
  Generator(i: Int)
  Chip(i: Int)
}

/// We first get generators and chips before validating the state
/// as we expect each generator to have a coresponding chip.
type UnvalidatedState {
  UnvalidatedState(n: Int, data: Dict(String, #(Option(Int), Option(Int))))
}

/// Because we use pairs as key for the cache, we need
/// to sort the pairs to ensure we don't count similar states
/// multiple times
fn sort_pairs(pairs: List(#(Int, Int))) -> List(#(Int, Int)) {
  list.sort(pairs, fn(a, b) {
    case int.compare(a.0, b.0) {
      order.Eq -> int.compare(a.1, b.1)
      o -> o
    }
  })
}

fn is_floor_safe(f: Int, pairs: List(#(Int, Int))) -> Bool {
  let has_gen =
    pairs
    |> list.find(fn(p) { p.0 == f })
    |> result.is_ok

  let has_unpaired_chip =
    pairs
    |> list.find(fn(p) { p.1 == f && p.0 != f })
    |> result.is_ok

  bool.or(bool.negate(has_gen), bool.negate(has_unpaired_chip))
}

fn is_safe(state: State, n: Int) -> Bool {
  int.range(0, n, True, fn(acc, f) { acc && is_floor_safe(f, state.pairs) })
}

/// Done when all chips and all generators are on the nth - 1 floor
fn is_done(state: State, n: Int) -> Bool {
  let top = n - 1
  state.pairs |> list.all(fn(p) { p.0 == top && p.1 == top })
}

/// Get all the items for a given floor f
fn floor_items(pairs: List(#(Int, Int)), f: Int) -> List(Item) {
  pairs
  |> list.index_map(fn(p, i) {
    case p.0 == f, p.1 == f {
      True, True -> [Generator(i), Chip(i)]
      True, False -> [Generator(i)]
      False, True -> [Chip(i)]
      _, _ -> []
    }
  })
  |> list.flatten
}

/// Update the given items to move to the next
/// floor for a given item
fn apply_item(
  pairs: List(#(Int, Int)),
  item: Item,
  next: Int,
) -> List(#(Int, Int)) {
  list.index_map(pairs, fn(p, i) {
    case item {
      Generator(j) if j == i -> #(next, p.1)
      Chip(j) if j == i -> #(p.0, next)
      _ -> p
    }
  })
}

/// calls list.conbinations from 1 to i + 1 and flatten
/// the output
fn compinations_to(elements: List(a), i: Int) -> List(List(a)) {
  int.range(1, i + 1, [], fn(acc, i) {
    acc
    |> list.append(elements |> list.combinations(i))
  })
}

/// adds an unvalidated generator that may or may not have a coresponding
/// chip yet
fn add_generator(state: UnvalidatedState, name: String) -> UnvalidatedState {
  let pair =
    state.data
    |> dict.get(name)
    |> result.unwrap(#(None, None))

  UnvalidatedState(
    ..state,
    data: dict.insert(state.data, name, #(Some(state.n), pair.1)),
  )
}

/// adds an unvalidated chip that may or may not have a coresponding
/// generator yet
fn add_chip(state: UnvalidatedState, name: String) -> UnvalidatedState {
  let pair =
    state.data
    |> dict.get(name)
    |> result.unwrap(#(None, None))

  UnvalidatedState(
    ..state,
    data: dict.insert(state.data, name, #(pair.0, Some(state.n))),
  )
}

fn process_line(
  state: UnvalidatedState,
  line: String,
) -> Result(UnvalidatedState, String) {
  let gen = fn(name, rest) { process_line(add_generator(state, name), rest) }
  let chip = fn(name, rest) { process_line(add_chip(state, name), rest) }
  let skip = fn(rest) { process_line(state, rest) }

  case line {
    "a hydrogen-compatible microchip" <> r -> chip("hydrogen", r)
    "a lithium-compatible microchip" <> r -> chip("lithium", r)
    "a thulium-compatible microchip" <> r -> chip("thulium", r)
    "a plutonium-compatible microchip" <> r -> chip("plutonium", r)
    "a strontium-compatible microchip" <> r -> chip("strontium", r)
    "a promethium-compatible microchip" <> r -> chip("promethium", r)
    "a ruthenium-compatible microchip" <> r -> chip("ruthenium", r)
    "a hydrogen generator" <> r -> gen("hydrogen", r)
    "a lithium generator" <> r -> gen("lithium", r)
    "a thulium generator" <> r -> gen("thulium", r)
    "a plutonium generator" <> r -> gen("plutonium", r)
    "a strontium generator" <> r -> gen("strontium", r)
    "a promethium generator" <> r -> gen("promethium", r)
    "a ruthenium generator" <> r -> gen("ruthenium", r)
    "nothing relevant" <> r -> skip(r)
    ", and " <> r -> skip(r)
    " and " <> r -> skip(r)
    ", " <> r -> skip(r)
    "." -> Ok(state)
    unknown -> Error("unknown line: " <> unknown)
  }
}

/// Add a floor, ignoring the text at the start of the line
/// This assumes floors are in order in the input
fn add_floor(
  state: UnvalidatedState,
  line: String,
) -> Result(UnvalidatedState, String) {
  use rest <- try(case line |> string.split(" ") {
    ["The", _, "floor", "contains", ..rest] -> Ok(rest |> string.join(" "))
    _ -> Error("unknown floor")
  })

  process_line(state, rest)
}

/// Parse the input into an unvalidated state. This solution assumes each
/// generator has its coresponding chip and therefore needs to be validated
/// stilll
fn get_floors(lines: List(String)) -> Result(UnvalidatedState, String) {
  use state <- try(
    lines
    |> list.fold(Ok(UnvalidatedState(n: 0, data: dict.new())), fn(acc, line) {
      use state <- try(acc)
      use state <- try(add_floor(state, line))
      Ok(UnvalidatedState(..state, n: state.n + 1))
    }),
  )

  Ok(state)
}

/// Convert the chips and generators to pairs and validate that
/// each generator has a coresponding chip. This problem assumes
/// that they always comes in pair and will fail otherwise
fn state_to_state(state: UnvalidatedState) -> Result(State, String) {
  use pairs <- try(
    state.data
    |> dict.to_list
    |> list.map(fn(entry) {
      let #(name, pair) = entry
      case pair {
        #(Some(g), Some(c)) -> Ok(#(g, c))
        #(None, _) -> Error("missing generator for " <> name)
        #(_, None) -> Error("missing chip for " <> name)
      }
    })
    |> result.all,
  )

  Ok(State(elevator: 0, pairs: sort_pairs(pairs)))
}

/// A pair is a tuple with the floor of the generator and the floor
/// of its coresponding chip
fn add_pair(state: State, gen_floor: Int, chip_floor: Int) -> State {
  State(..state, pairs: [#(gen_floor, chip_floor), ..state.pairs] |> sort_pairs)
}

fn add_pairs(state: State, pairs: List(#(Int, Int))) -> State {
  case pairs {
    [] -> state
    [a, ..rest] -> {
      let #(gen_floor, chip_floor) = a

      state
      |> add_pair(gen_floor, chip_floor)
      |> add_pairs(rest)
    }
  }
}

fn solve(
  n: Int,
  heap: heap.Heap(#(Int, State)),
  cache: Set(State),
) -> Result(Int, String) {
  use #(heap, head) <- try(
    heap.pop(heap)
    |> replace_error("failed to find a solution"),
  )

  let skip = fn() { solve(n, heap, cache) }
  let #(steps, state) = head

  use <- bool.guard(is_done(state, n), Ok(steps))
  use <- bool.lazy_guard(set.contains(cache, state), skip)
  let cache = set.insert(cache, state)

  let items = floor_items(state.pairs, state.elevator)

  let heap =
    [state.elevator + 1, state.elevator - 1]
    |> list.filter(fn(next) { 0 <= next && next < n })
    |> list.flat_map(fn(next) {
      items
      |> compinations_to(2)
      |> list.map(fn(selected) {
        selected
        |> list.fold(state.pairs, fn(pairs, item) {
          apply_item(pairs, item, next)
        })
        |> sort_pairs
        |> State(next, _)
      })
    })
    |> list.filter(fn(s) { is_safe(s, n) })
    |> list.fold(heap, fn(acc, s) { acc |> heap.insert(#(steps + 1, s)) })

  solve(n, heap, cache)
}

fn solve_state(n: Int, state: State) -> Result(Int, String) {
  heap.new(fn(a: #(Int, State), b: #(Int, State)) { int.compare(a.0, b.0) })
  |> heap.insert(#(0, state))
  |> solve(n, _, set.new())
}

pub fn main(input: String) -> Result(Nil, String) {
  use state <- try(
    input
    |> string.trim
    |> string.split("\n")
    |> get_floors,
  )

  let n = state.n
  use state <- try(state_to_state(state))

  use p1 <- try(solve_state(n, state))
  p1 |> int.to_string |> io.println

  let state = state |> add_pairs([#(0, 0), #(0, 0)])
  use p2 <- try(solve_state(n, state))
  p2 |> int.to_string |> io.println

  Ok(Nil)
}
