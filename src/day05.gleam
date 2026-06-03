import gleam/bit_array
import gleam/crypto
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string

fn hash(password: String) -> String {
  crypto.Md5
  |> crypto.hash(<<password:utf8>>)
  |> bit_array.base16_encode
  |> string.lowercase
}

fn get_tail(hash: String) -> Option(String) {
  case hash {
    "00000" <> tail -> Some(tail)
    _ -> None
  }
}

fn get_67(hash: String) -> Option(#(String, String)) {
  case hash |> get_tail {
    Some(tail) ->
      Some(#(tail |> string.slice(0, 1), tail |> string.slice(1, 1)))
    _ -> None
  }
}

fn get_position_character(hash: String) -> Option(#(Int, String)) {
  case hash |> get_67 {
    Some(#(left, right)) ->
      case left |> int.parse {
        Ok(number) -> Some(#(number, right))
        _ -> None
      }
    _ -> None
  }
}

fn validate_hash_p1(hash: String) -> Option(String) {
  case hash |> get_tail {
    Some(tail) -> Some(tail |> string.slice(0, 1))
    _ -> None
  }
}

fn update_password(hash: String, password: String) -> String {
  case hash |> validate_hash_p1 {
    Some(char) -> password <> char
    _ -> password
  }
}

fn validate_hash_p2(
  hash: String,
  lenght: Int,
  characters: Dict(Int, String),
) -> Option(#(Int, String)) {
  case hash |> get_position_character {
    Some(#(position, char)) if position >= 0 && position < lenght ->
      case characters |> dict.has_key(position) {
        False -> Some(#(position, char))
        _ -> None
      }
    _ -> None
  }
}

fn update_characters(
  hash: String,
  lenght: Int,
  characters: Dict(Int, String),
) -> Dict(Int, String) {
  case hash |> validate_hash_p2(lenght, characters) {
    Some(#(position, char)) -> characters |> dict.insert(position, char)
    _ -> characters
  }
}

fn characters_to_string(characters: Dict(Int, String)) -> String {
  characters
  |> dict.to_list
  |> list.sort(fn(a, b) {
    let #(p1, _) = a
    let #(p2, _) = b
    int.compare(p1, p2)
  })
  |> list.map(fn(a) {
    let #(_, c) = a
    c
  })
  |> string.join("")
}

fn get_password_part_1(
  base: String,
  length: Int,
  password: String,
  state: Int,
) -> String {
  case password |> string.length {
    l if l == length -> password
    _ -> {
      let next =
        base
        |> string.append(int.to_string(state))
        |> hash
        |> update_password(password)

      get_password_part_1(base, length, next, state + 1)
    }
  }
}

fn get_password_part_2(
  base: String,
  length: Int,
  characters: Dict(Int, String),
  state: Int,
) -> String {
  case characters |> dict.size {
    l if l == length -> characters |> characters_to_string
    _ -> {
      let next =
        base
        |> string.append(int.to_string(state))
        |> hash
        |> update_characters(length, characters)

      get_password_part_2(base, length, next, state + 1)
    }
  }
}

pub fn main(input: String) -> Result(Nil, String) {
  let base = input |> string.trim

  let p1 = get_password_part_1(base, 8, "", 1)
  io.println(p1)

  let p2 = get_password_part_2(base, 8, dict.new(), 1)
  io.println(p2)

  Ok(Nil)
}
