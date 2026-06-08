import gleam/bit_array
import gleam/bool
import gleam/crypto
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list.{Continue, Stop}
import gleam/option.{type Option, None, Some}
import gleam/result.{try}
import gleam/string

type Cache =
  Dict(#(String, Int, Int), Option(String))

fn md5(data: String) -> String {
  crypto.Md5
  |> crypto.hash(<<data:utf8>>)
  |> bit_array.base16_encode
  |> string.lowercase
}

fn hash(input: String, i: Int) -> String {
  md5(input <> int.to_string(i))
}

fn hash_2016(input: String, i: Int) -> String {
  let base = hash(input, i)
  int.range(0, 2016, base, fn(acc, _) { md5(acc) })
}

fn get_char_repeat(
  input: String,
  i: Int,
  n: Int,
  cache: Cache,
  hash: fn(String, Int) -> String,
) -> #(Cache, Option(String)) {
  case cache |> dict.get(#(input, i, n)) {
    Ok(a) -> #(cache, a)
    Error(_) -> {
      let hashed = hash(input, i)

      let option = case
        hashed
        |> string.split("")
        |> list.window(n)
        |> list.find_map(fn(window) {
          case window |> list.unique {
            [a] -> Ok(a)
            _ -> Error("not all the same in window")
          }
        })
      {
        Ok(a) -> Some(a)
        Error(_) -> None
      }

      let cache = cache |> dict.insert(#(input, i, n), option)
      #(cache, option)
    }
  }
}

fn get_next_char_repeat(
  input: String,
  i: Int,
  n: Int,
  cache: Cache,
  hash: fn(String, Int) -> String,
) -> #(Cache, String, Int) {
  case get_char_repeat(input, i, n, cache, hash) {
    #(cache, Some(a)) -> #(cache, a, i)
    #(cache, _) -> get_next_char_repeat(input, i + 1, n, cache, hash)
  }
}

fn get_next_char_repeat_max(
  input: String,
  i: Int,
  i_max: Int,
  n: Int,
  char: String,
  cache: Cache,
  hash: fn(String, Int) -> String,
) -> #(Cache, Option(#(String, Int))) {
  use <- bool.guard(i == i_max, #(cache, None))

  case get_char_repeat(input, i, n, cache, hash) {
    #(cache, Some(a)) if a == char -> #(cache, Some(#(a, i)))
    #(cache, _) ->
      get_next_char_repeat_max(input, i + 1, i_max, n, char, cache, hash)
  }
}

fn solve(
  input: String,
  i: Int,
  nth: Int,
  cache: Cache,
  hash: fn(String, Int) -> String,
) -> Int {
  let #(cache, a, j) = get_next_char_repeat(input, i, 3, cache, hash)

  case get_next_char_repeat_max(input, j + 1, j + 1000 + 1, 5, a, cache, hash) {
    #(cache, Some(#(_, _))) ->
      case nth {
        i if i > 1 -> solve(input, j + 1, nth - 1, cache, hash)
        _ -> j
      }
    #(cache, _) -> solve(input, j + 1, nth, cache, hash)
  }
}

pub fn main(input: String) -> Result(Nil, String) {
  solve(input |> string.trim, 1, 64, dict.new(), hash) |> echo
  solve(input |> string.trim, 1, 64, dict.new(), hash_2016) |> echo
  Ok(Nil)
}
