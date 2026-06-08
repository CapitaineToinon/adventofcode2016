import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option
import gleam/result.{replace_error, try}
import gleam/string

type Radiation {
  H
  L
}

type Component {
  M(Radiation)
  G(Radiation)
}

type Element {
  Element(floor: Int, component: Component)
}

type Building {
  Building(n: Int, elevator: Int, elements: List(Element))
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
        building.elements
        |> list.filter_map(fn(el) {
          case el.floor == i {
            True -> Ok(el.component)
            False -> Error("skipping")
          }
        })
        |> is_floor_safe
      }
    }
  })
}

fn process_line(building: Building, line: String) -> Building {
  let add = fn(component: Component, rest: String) -> Building {
    Building(..building, elements: [
      Element(building.n, component),
      ..building.elements
    ])
    |> process_line(rest)
  }

  let skip = fn(rest: String) -> Building { building |> process_line(rest) }

  case line {
    "a hydrogen-compatible microchip" <> r -> add(M(H), r)
    "a lithium-compatible microchip" <> r -> add(M(L), r)
    "a hydrogen generator" <> r -> add(G(H), r)
    "a lithium generator" <> r -> add(G(L), r)
    ", and " <> r -> skip(r)
    " and " <> r -> skip(r)
    _ -> building
  }
}

fn add_floor(building: Building, line: String) -> Result(Building, String) {
  use rest <- try(case line |> string.split(" ") {
    ["The", _, "floor", "contains", ..rest] -> Ok(rest |> string.join(" "))
    _ -> Error("unknown floor")
  })

  Ok(building |> process_line(rest))
}

fn get_floors(lines: List(String)) -> Result(Building, String) {
  let building = Building(n: 0, elevator: 1, elements: list.new())

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

fn is_done(building: Building) -> Bool {
  building.elements
  |> list.all(fn(el) { el.floor == building.n })
}

fn move(building: Building) -> Building {
  case is_done(building) {
    True -> building
    False -> {
      todo
    }
  }
}

pub fn main(input: String) -> Result(Nil, String) {
  use floors <- try(
    input
    |> string.trim
    |> string.split("\n")
    |> get_floors,
  )

  floors
  |> echo
  |> is_safe
  |> echo

  Ok(Nil)
}
