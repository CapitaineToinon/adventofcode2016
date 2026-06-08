import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/result.{replace_error, try}
import gleam/set.{type Set}
import gleam/string
import heap

type Radiation {
  H
  L
  T
  PL
  PR
  S
  R
  E
  D
}

type Component {
  M(Radiation)
  G(Radiation)
}

type Position {
  Position(id: Int, floor: Int, component: Component)
}

type Building {
  Building(n: Int, elevator: Int, positions: Set(Position))
}

fn is_floor_safe(components: List(Component)) -> Bool {
  components
  |> list.all(fn(c) {
    case c {
      G(_) -> True
      M(rad) -> {
        let is_powered =
          components
          |> list.contains(G(rad))

        let is_alone =
          components
          |> list.find(fn(g) {
            case g {
              G(oth) if oth != rad -> True
              _ -> False
            }
          })
          |> result.is_ok
          |> bool.negate

        bool.or(is_powered, is_alone)
      }
    }
  })
}

fn is_safe(building: Building) -> Bool {
  int.range(0, building.n, True, fn(acc, i) {
    case acc {
      False -> False
      True -> {
        building.positions
        |> set.filter(fn(pos) { pos.floor == i })
        |> set.map(fn(pos) { pos.component })
        |> set.to_list
        |> is_floor_safe
      }
    }
  })
}

fn add_component(building: Building, floor: Int, component: Component) {
  let id = building.positions |> set.size

  let positions =
    building.positions
    |> set.insert(Position(id: id, floor: floor, component: component))

  Building(..building, positions: positions)
}

fn process_line(building: Building, line: String) -> Result(Building, String) {
  let add = fn(component: Component, rest: String) {
    building
    |> add_component(building.n, component)
    |> process_line(rest)
  }

  let skip = fn(rest: String) {
    building
    |> process_line(rest)
  }

  case line {
    "a hydrogen-compatible microchip" <> r -> add(M(H), r)
    "a lithium-compatible microchip" <> r -> add(M(L), r)
    "a thulium-compatible microchip" <> r -> add(M(T), r)
    "a plutonium-compatible microchip" <> r -> add(M(PL), r)
    "a strontium-compatible microchip" <> r -> add(M(S), r)
    "a promethium-compatible microchip" <> r -> add(M(PR), r)
    "a ruthenium-compatible microchip" <> r -> add(M(R), r)
    "a hydrogen generator" <> r -> add(G(H), r)
    "a lithium generator" <> r -> add(G(L), r)
    "a thulium generator" <> r -> add(G(T), r)
    "a plutonium generator" <> r -> add(G(PL), r)
    "a strontium generator" <> r -> add(G(S), r)
    "a promethium generator" <> r -> add(G(PR), r)
    "a ruthenium generator" <> r -> add(G(R), r)
    "nothing relevant" <> r -> skip(r)
    ", and " <> r -> skip(r)
    " and " <> r -> skip(r)
    ", " <> r -> skip(r)
    "." -> Ok(building)
    unknown -> Error("unknown line: " <> unknown)
  }
}

fn add_floor(building: Building, line: String) -> Result(Building, String) {
  use rest <- try(case line |> string.split(" ") {
    ["The", _, "floor", "contains", ..rest] -> Ok(rest |> string.join(" "))
    _ -> Error("unknown floor")
  })

  building |> process_line(rest)
}

fn get_floors(lines: List(String)) -> Result(Building, String) {
  let building = Building(n: 0, elevator: 0, positions: set.new())

  use building <- try(
    lines
    |> list.fold(Ok(building), fn(acc, line) {
      use building <- try(acc)
      use building <- try(building |> add_floor(line))
      Ok(Building(..building, n: building.n + 1))
    }),
  )

  Ok(building)
}

fn h(building: Building) -> Int {
  let top = building.n - 1

  building.positions
  |> set.map(fn(pos) { pos.floor })
  |> set.fold(0, fn(acc, floor) { int.add(acc, floor - top) })
}

fn is_done(building: Building) -> Bool {
  let total =
    building.positions
    |> set.filter(fn(pos) { pos.floor == building.n - 1 })
    |> set.size

  set.size(building.positions) == total
}

fn compinations_to(elements: List(a), i: Int) -> List(List(a)) {
  int.range(1, i + 1, [], fn(acc, i) {
    acc
    |> list.append(
      elements
      |> list.combinations(i),
    )
  })
}

fn solve(
  heap: heap.Heap(#(Int, Int, Building)),
  cache: Dict(Building, Int),
) -> Result(#(Int, Building), String) {
  use #(heap, head) <- try(
    heap.pop_min(heap)
    |> replace_error("failed to find a solution"),
  )

  let skip = fn() { solve(heap, cache) }

  let #(_, steps, building) = head

  use <- bool.lazy_guard(is_safe(building) |> bool.negate, skip)
  use <- bool.guard(is_done(building), Ok(#(steps, building)))
  use <- bool.lazy_guard(dict.has_key(cache, building), skip)

  let cache = dict.insert(cache, building, steps)

  // building |> print_building

  let floor =
    building.positions
    |> set.filter(fn(pos) { pos.floor == building.elevator })
    |> set.to_list

  let heap =
    [building.elevator + 1, building.elevator - 1]
    |> list.filter(fn(next) { 0 <= next && next < building.n })
    |> list.flat_map(fn(next) {
      floor
      |> compinations_to(2)
      |> list.map(fn(ids) {
        let positions =
          building.positions
          |> set.difference(set.from_list(ids))
          |> set.union(
            ids
            |> list.map(fn(pos) { Position(..pos, floor: next) })
            |> set.from_list,
          )

        Building(..building, positions: positions, elevator: next)
      })
    })
    |> list.fold(heap, fn(acc, building) {
      let score = h(building)
      acc |> heap.insert(#(steps + 1 + score, steps + 1, building))
    })

  solve(heap, cache)
}

fn solve_building(building: Building) -> Result(Int, String) {
  heap.new(fn(a: #(Int, Int, Building), b: #(Int, Int, Building)) {
    int.compare(a.0, b.0)
  })
  |> heap.insert(#(0, 0, building))
  |> solve(dict.new())
  |> result.map(fn(output) { output.0 })
}

pub fn main(input: String) -> Result(Nil, String) {
  use building <- try(
    input
    |> string.trim
    |> string.split("\n")
    |> get_floors,
  )

  use p1 <- try(solve_building(building))

  p1
  |> int.to_string
  |> io.println

  use p2 <- try(
    building
    |> add_component(0, G(E))
    |> add_component(0, M(E))
    |> add_component(0, G(D))
    |> add_component(0, M(D))
    |> solve_building,
  )

  p2
  |> int.to_string
  |> io.println

  Ok(Nil)
}
