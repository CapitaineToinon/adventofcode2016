import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/result

fn steal(elf: Int, elfs: Dict(Int, Int), n) -> #(Int, Int) {
  case elfs |> dict.get(elf) |> result.unwrap(1) {
    0 -> steal({ elf + 1 } % n, elfs, n)
    count -> #(elf, count)
  }
}

fn part_1(elf: Int, elfs: Dict(Int, Int), n: Int) -> Int {
  let current = elfs |> dict.get(elf) |> result.unwrap(1)

  use <- bool.guard(current == n, elf)

  use <- bool.lazy_guard(current == 0, fn() { part_1({ elf + 1 } % n, elfs, n) })

  let #(from, count) = steal({ elf + 1 } % n, elfs, n)

  let elfs =
    elfs
    |> dict.insert(from, 0)
    |> dict.insert(elf, current + count)

  part_1({ elf + 1 } % n, elfs, n)
}

pub fn main(_input: String) -> Result(Nil, String) {
  part_1(1, dict.new(), 3_018_458) |> echo

  Ok(Nil)
}
