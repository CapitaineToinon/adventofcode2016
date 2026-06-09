import argv
import day01
import day02
import day03
import day04
import day05
import day06
import day07
import day08
import day09
import day10
import day11
import day12
import day13
import day14
import day15
import day16
import day17
import day18
import day19
import gleam/bool
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

fn time(cb: fn() -> b) -> b {
  let now = timestamp.system_time()
  let result = cb()
  let then = timestamp.system_time()
  let diff = timestamp.difference(now, then)
  let ms = duration.to_milliseconds(diff)

  io.println("Executed in " <> int.to_string(ms) <> " ms")
  result
}

fn execute_day() -> Result(Nil, String) {
  let days =
    dict.from_list([
      #(1, day01.main),
      #(2, day02.main),
      #(3, day03.main),
      #(4, day04.main),
      #(5, day05.main),
      #(6, day06.main),
      #(7, day07.main),
      #(8, day08.main),
      #(9, day09.main),
      #(10, day10.main),
      #(11, day11.main),
      #(12, day12.main),
      #(13, day13.main),
      #(14, day14.main),
      #(15, day15.main),
      #(16, day16.main),
      #(17, day17.main),
      #(18, day18.main),
      #(19, day19.main),
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

  use <- time
  day(file)
}

pub fn main() -> Nil {
  case execute_day() {
    Ok(_) -> Nil
    Error(message) -> io.println_error(message)
  }
}
