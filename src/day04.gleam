import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/order
import gleam/result
import gleam/string

type Room {
  Room(name: String, sector: Int, checksum: String)
}

fn parse_rooms(input: String) -> Result(List(Room), String) {
  use rooms <- result.try(
    input
    |> string.trim
    |> string.split("\n")
    |> list.map(fn(s) {
      s |> string.trim |> string.reverse |> string.split_once("-")
    })
    |> result.all
    |> result.replace_error("failed to parse rooms"),
  )

  rooms
  |> list.map(fn(line) {
    let #(left, right) = line
    #(string.reverse(left), string.reverse(right))
  })
  |> list.map(fn(line) {
    let #(left, name) = line
    use #(left, right) <- result.try(left |> string.split_once("["))

    use sector <- result.try(left |> int.parse)
    let checksum = right |> string.remove_suffix("]")

    Ok(Room(name, sector, checksum))
  })
  |> result.all
  |> result.replace_error("failed to parse rooms")
}

fn is_valid(room: Room) -> Bool {
  let checksum =
    room.name
    |> string.trim
    |> string.split("")
    |> list.filter(fn(s) { s != "-" })
    |> list.fold(dict.new(), fn(d, c) {
      dict.upsert(d, c, fn(count) {
        case count {
          Some(value) -> value + 1
          None -> 1
        }
      })
    })
    |> dict.to_list
    |> list.sort(fn(a, b) {
      case a, b {
        #(_, v1), #(_, v2) if v1 < v2 -> order.Gt
        #(_, v1), #(_, v2) if v1 > v2 -> order.Lt
        _, _ -> order.Eq
      }
    })
    |> list.map(fn(entry) {
      let #(key, _) = entry
      key
    })
    |> list.take(5)
    |> string.join("")

  checksum == room.checksum
}

fn decrypt_room(room: Room) -> Result(Room, String) {
  use codepoints <- result.try(
    room.name
    |> string.split("")
    |> list.flat_map(string.to_utf_codepoints)
    |> list.map(string.utf_codepoint_to_int)
    |> list.map(fn(i) {
      let index = i - 97
      let rotated = index + room.sector
      let bounded = rotated % 26
      bounded + 97
    })
    |> list.map(string.utf_codepoint)
    |> result.all
    |> result.replace_error("failed to rotate name"),
  )

  let name = codepoints |> string.from_utf_codepoints

  Ok(Room(name, room.sector, room.checksum))
}

pub fn main(input: String) -> Result(Nil, String) {
  use rooms <- result.try(parse_rooms(input))

  let valid_rooms =
    rooms
    |> list.filter(is_valid)

  let p1 =
    valid_rooms
    |> list.map(fn(room) { room.sector })
    |> int.sum

  use decrypted <- result.try(
    rooms
    |> list.map(decrypt_room)
    |> result.all,
  )

  use room <- result.try(
    decrypted
    |> list.find(fn(room) { string.contains(room.name, "northpole") })
    |> result.replace_error("failed to find the north pole room"),
  )

  io.println(int.to_string(p1))
  io.println(int.to_string(room.sector))

  Ok(Nil)
}
