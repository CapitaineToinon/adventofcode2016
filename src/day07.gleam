import gleam/int
import gleam/io
import gleam/list
import gleam/string

fn next_depth(depth: Int, char: String) -> Int {
  case char {
    "[" -> depth + 1
    "]" -> depth - 1
    _ -> depth
  }
}

fn is_aba(a: String, b: String, c: String) -> Bool {
  a == c && a != b
}

fn is_aba_bab(
  a: String,
  b: String,
  c: String,
  d: String,
  e: String,
  f: String,
  abc_depth: Int,
  def_depth: Int,
) -> Bool {
  abc_depth + 1 == def_depth
  && is_aba(a, b, c)
  && is_aba(d, e, f)
  && a == c
  && a == e
  && b == d
  && b == f
}

fn is_abba(a: String, b: String, c: String, d: String) -> Bool {
  a == d && b == c && a != b && c != d
}

fn find_abba_at_depth(ip: List(String), depth: Int, target: Int) -> Bool {
  case ip {
    [a, b, c, d, ..rest] -> {
      case depth == target && is_abba(a, b, c, d) {
        True -> True
        False -> {
          find_abba_at_depth([b, c, d, ..rest], depth |> next_depth(a), target)
        }
      }
    }
    _ -> False
  }
}

fn find_aba_bab(ip: List(String), sequence: List(String), depth: Int) -> Bool {
  case sequence {
    [a, b, c, ..rest] -> {
      case is_aba(a, b, c) && find_bab(ip, 0, a, b, c, depth) {
        True -> True
        False -> {
          find_aba_bab(ip, [b, c, ..rest], depth |> next_depth(a))
        }
      }
    }
    _ -> False
  }
}

fn find_bab(
  ip: List(String),
  depth: Int,
  a: String,
  b: String,
  c: String,
  abc_depth: Int,
) -> Bool {
  case ip {
    [d, e, f, ..rest] -> {
      case is_aba_bab(a, b, c, d, e, f, abc_depth, depth) {
        True -> True
        False -> {
          find_bab([e, f, ..rest], depth |> next_depth(d), a, b, c, abc_depth)
        }
      }
    }
    _ -> False
  }
}

fn is_tls(ip: List(String)) -> Bool {
  !find_abba_at_depth(ip, 0, 1) && find_abba_at_depth(ip, 0, 0)
}

fn is_ssl(ip: List(String)) -> Bool {
  find_aba_bab(ip, ip, 0)
}

pub fn main(input: String) -> Result(Nil, String) {
  let ips =
    input
    |> string.trim
    |> string.split("\n")
    |> list.map(fn(s) { s |> string.split("") })

  ips
  |> list.filter(is_tls)
  |> list.length
  |> int.to_string
  |> io.println

  ips
  |> list.filter(is_ssl)
  |> list.length
  |> int.to_string
  |> io.println

  Ok(Nil)
}
