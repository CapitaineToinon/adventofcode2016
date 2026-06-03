import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/result
import gleam/string

fn parse_int(input: String) -> Result(Int, String) {
  input
  |> int.parse
  |> result.replace_error("failed to parse int")
}

/// Given a string which we already know contains a repeat, find where it ends
/// by finding the closing parenthesis
fn find_repeat(input: String, start: Int, len: Int) -> Result(String, String) {
  let input_len = input |> string.length

  case start + len < input_len {
    True -> {
      let current = input |> string.slice(start + len, 1)

      case current {
        ")" -> Ok(input |> string.slice(start, len))
        _ -> find_repeat(input, start, len + 1)
      }
    }
    False ->
      Error(
        "failed to find closing parenthesis :"
        <> input |> string.slice(start, len),
      )
  }
}

/// parse a pattern string 3x5 to a tuple of int #(3, 5)
fn parse_repeat(pattern: String) -> Result(#(Int, Int), String) {
  use #(left, right) <- result.try(
    pattern
    |> string.split_once("x")
    |> result.replace_error("failed to parse repeat"),
  )

  use n <- result.try(left |> parse_int)
  use by <- result.try(right |> parse_int)

  Ok(#(n, by))
}

/// Given a string we already know starts with a pattern, find
/// the end, for example extract 3x5 from 3x5)ABC... and parse it
fn get_pattern(
  input: String,
  starting_position: Int,
) -> Result(#(Int, Int, Int), String) {
  use pattern <- result.try(find_repeat(input, starting_position, 1))

  // add 2 to consider parentheses
  let pattern_len = string.length(pattern) + 2

  use #(n, by) <- result.try(pattern |> parse_repeat)
  Ok(#(n, by, pattern_len))
}

fn decompress(
  input: String,
  position: Int,
  single_pass: Bool,
  cache: Dict(String, Int),
) -> Result(#(Int, Dict(String, Int)), String) {
  let input_len = input |> string.length

  case position < input_len {
    False -> {
      // When the string is empty, meaning we reached the end
      // of the input
      Ok(#(0, cache))
    }
    True -> {
      let head = input |> string.slice(position, 1)

      case head {
        "(" -> {
          use #(n_characters, n_repeats, pattern_string_len) <- result.try(
            get_pattern(input, position + 1),
          )

          let string_to_repeat =
            input
            |> string.slice(position + pattern_string_len, n_characters)

          use #(segment_len, cache) <- result.try(
            case dict.get(cache, string_to_repeat) {
              Ok(len) -> {
                // cache hit means this specific pattern
                // has already recurisvely be processed
                Ok(#(len, cache))
              }
              Error(_) -> {
                // If we wish to recurisvely decompress, call
                // decompress again with the pattern that replaces
                use #(len, cache) <- result.try(case single_pass {
                  False -> decompress(string_to_repeat, 0, False, cache)
                  _ -> Ok(#(n_characters, cache))
                })

                let cache = dict.insert(cache, string_to_repeat, len)
                Ok(#(len, cache))
              }
            },
          )

          let to_replace_len = pattern_string_len + n_characters

          // jump past the middle pattern we just computed and keep going
          // with the rest of the input
          use #(rest_len, cache) <- result.try(decompress(
            input,
            position + to_replace_len,
            single_pass,
            cache,
          ))

          // final length
          let length = n_repeats * segment_len + rest_len
          Ok(#(length, cache))
        }
        _ -> {
          // We're currently not processing a pattern that needs
          // to be repeated, therefore just advance by once character
          // and keep going
          use #(rest_len, cache) <- result.try(decompress(
            input,
            position + 1,
            single_pass,
            cache,
          ))

          Ok(#(1 + rest_len, cache))
        }
      }
    }
  }
}

fn v1(input: String) -> Result(Int, String) {
  use #(size, _) <- result.try(input |> decompress(0, True, dict.new()))
  Ok(size)
}

fn v2(input: String) -> Result(Int, String) {
  use #(size, _) <- result.try(input |> decompress(0, False, dict.new()))
  Ok(size)
}

fn print(data: Int) -> Nil {
  data
  |> int.to_string
  |> io.println
}

pub fn main(input: String) -> Result(Nil, String) {
  let input =
    input
    |> string.trim

  use p1 <- result.try(v1(input))
  use p2 <- result.try(v2(input))

  p1 |> print
  p2 |> print

  Ok(Nil)
}
