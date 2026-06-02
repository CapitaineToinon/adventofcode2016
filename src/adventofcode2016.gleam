import argv
import day01
import day02
import day03
import day04
import day05
import gleam/dict
import gleam/int
import gleam/io
import gleam/result
import gleam/time/duration
import gleam/time/timestamp
import simplifile

fn get_argument() -> Result(String, String) {
  case argv.load().arguments {
    [string] -> Ok(string)
    _ -> Error("argument not found")
  }
}

fn execute_day() -> Result(Nil, String) {
  let days =
    dict.from_list([
      #(1, day01.main),
      #(2, day02.main),
      #(3, day03.main),
      #(4, day04.main),
      #(5, day05.main),
    ])

  use arg <- result.try(get_argument())

  use i <- result.try(
    int.parse(arg)
    |> result.replace_error("argument " <> arg <> " is not a valid number"),
  )

  use day <- result.try(
    dict.get(days, i)
    |> result.replace_error(
      "day " <> arg <> " not found or not implemented yet",
    ),
  )

  use file <- result.try(
    simplifile.read("./input/day" <> arg)
    |> result.replace_error("failed to open input file for day " <> arg),
  )

  let now = timestamp.system_time()
  let result = day(file)
  let then = timestamp.system_time()
  let diff = timestamp.difference(now, then)
  let ms = duration.to_milliseconds(diff)

  io.println("Executed in " <> int.to_string(ms) <> " ms")

  result
}

pub fn main() -> Nil {
  case execute_day() {
    Ok(_) -> Nil
    Error(message) -> io.println_error(message)
  }
}
