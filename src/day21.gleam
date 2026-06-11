import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/result.{replace_error, try}
import gleam/string

type Rule {
  SwapPositions(a: Int, b: Int)
  SwapLetters(a: String, b: String)
  RotateLeft(steps: Int)
  RotateRight(steps: Int)
  RotateRightBasedOn(a: String)
  ReversePositions(a: Int, b: Int)
  MovePosition(a: Int, b: Int)
}

type Letter =
  #(String, Int)

type Letters =
  List(Letter)

fn parse_int(int: String) -> Result(Int, String) {
  int
  |> int.parse
  |> replace_error("failed to parse int " <> int)
}

fn split_once(
  string: String,
  with: String,
) -> Result(#(String, String), String) {
  string
  |> string.split_once(with)
  |> replace_error("failed to split string " <> string)
}

fn parse_line(line: String) -> Result(Rule, String) {
  case line {
    "swap position " <> rest -> {
      use #(a, b) <- try(rest |> split_once(" with position "))
      use a <- try(parse_int(a))
      use b <- try(parse_int(b))
      Ok(SwapPositions(a, b))
    }
    "swap letter " <> rest -> {
      use #(a, b) <- try(rest |> split_once(" with letter "))
      Ok(SwapLetters(a, b))
    }
    "rotate left " <> rest -> {
      use #(a, _) <- try(rest |> split_once(" "))
      use a <- try(parse_int(a))
      Ok(RotateLeft(a))
    }
    "rotate right " <> rest -> {
      use #(a, _) <- try(rest |> split_once(" "))
      use a <- try(parse_int(a))
      Ok(RotateRight(a))
    }
    "rotate based on position of letter " <> rest -> {
      Ok(RotateRightBasedOn(rest))
    }
    "reverse positions " <> rest -> {
      use #(a, b) <- try(rest |> split_once(" through "))
      use a <- try(parse_int(a))
      use b <- try(parse_int(b))
      Ok(ReversePositions(a, b))
    }
    "move position " <> rest -> {
      use #(a, b) <- try(rest |> split_once(" to position "))
      use a <- try(parse_int(a))
      use b <- try(parse_int(b))
      Ok(MovePosition(a, b))
    }
    _ -> Error("invalid rule " <> line)
  }
}

fn parse_lines(input: List(String)) -> Result(List(Rule), String) {
  input
  |> list.map(parse_line)
  |> result.all
}

fn parse_code(code: String) -> Letters {
  code
  |> string.split("")
  |> list.index_fold(list.new(), fn(list, char, index) {
    list |> list.prepend(#(char, index))
  })
  |> sort
}

fn code_tostring(code: Letters) -> String {
  code
  |> sort
  |> list.map(fn(a) { a.0 })
  |> string.join("")
}

fn find_letter(list: Letters, i: Int) -> Result(String, String) {
  list
  |> list.find_map(fn(item) {
    let #(a, j) = item
    case j == i {
      True -> Ok(a)
      False -> Error("no")
    }
  })
  |> replace_error("failed to find letter at index " <> int.to_string(i))
}

fn find_position(list: Letters, a: String) -> Result(Int, String) {
  list
  |> list.find_map(fn(item) {
    let #(b, j) = item
    case b == a {
      True -> Ok(j)
      False -> Error("no")
    }
  })
  |> replace_error("failed to find position of letter " <> a)
}

fn swap(list: Letters, a: String, i: Int, b: String, j: Int) -> Letters {
  list
  |> remove(a, i)
  |> remove(b, j)
  |> add(a, j)
  |> add(b, i)
}

fn swap_positions(list: Letters, i: Int, j: Int) -> Result(Letters, String) {
  use a <- try(list |> find_letter(i))
  use b <- try(list |> find_letter(j))

  list
  |> swap(a, i, b, j)
  |> Ok
}

fn swap_letters(
  list: Letters,
  a: String,
  b: String,
) -> Result(Letters, String) {
  use i <- try(list |> find_position(a))
  use j <- try(list |> find_position(b))

  list
  |> swap(a, i, b, j)
  |> Ok
}

fn add(input: Letters, key: String, value: Int) -> Letters {
  input
  |> list.prepend(#(key, value))
}

fn remove(input: Letters, key: String, value: Int) -> Letters {
  input
  |> list.filter(fn(e) { e != #(key, value) })
}

fn rotate_right(list: Letters, by: Int) -> Letters {
  let n = list |> list.length

  list
  |> list.map(fn(el) {
    let #(a, i) = el
    let j = i + by
    #(a, { j % n + n } % n)
  })
}

fn rotate_left(list: Letters, by: Int) -> Letters {
  rotate_right(list, by * -1)
}

fn rotate_basedon(list: Letters, a: String) -> Result(Letters, String) {
  use i <- try(list |> find_position(a))

  let by = case i {
    i if i >= 4 -> i + 2
    _ -> i + 1
  }

  list
  |> rotate_right(by)
  |> Ok
}

fn find_unrotate(list: Letters, a: String, by: Int) -> Result(Letters, String) {
  let candidate = list |> rotate_left(by)
  use attempt <- try(candidate |> rotate_basedon(a))

  case attempt == list {
    True -> Ok(candidate)
    False -> find_unrotate(list, a, by + 1)
  }
}

fn unrotate_basedon(list: Letters, a: String) -> Result(Letters, String) {
  find_unrotate(list, a, 1)
}

fn sort(list: Letters) -> Letters {
  list |> list.sort(fn(a, b) { int.compare(a.1, b.1) })
}

fn reverse_positions(list: Letters, i: Int, j: Int) -> Letters {
  let should_reverse = fn(el: Letter) { i <= el.1 && el.1 <= j }

  let to_reverse =
    list
    |> list.filter(should_reverse)
    |> sort

  let to_stay =
    list
    |> list.filter(fn(el) {
      el
      |> should_reverse
      |> bool.negate
    })

  let reversed =
    to_reverse
    |> list.zip(to_reverse |> list.reverse)
    |> list.map(fn(zipped) {
      let #(a, b) = zipped
      #(a.0, b.1)
    })

  to_stay
  |> list.append(reversed)
}

fn move_position(list: Letters, i: Int, j: Int) {
  use a <- try(list |> find_letter(i))

  list
  |> remove(a, i)
  |> list.map(fn(el) {
    case el {
      #(b, k) if i <= k -> #(b, k - 1)
      _ -> el
    }
  })
  |> list.map(fn(el) {
    case el {
      #(b, k) if j <= k -> #(b, k + 1)
      _ -> el
    }
  })
  |> add(a, j)
  |> Ok
}

fn do_rule(rule: Rule, input: Letters) -> Result(Letters, String) {
  case rule {
    SwapPositions(i, j) -> input |> swap_positions(i, j)
    SwapLetters(a, b) -> input |> swap_letters(a, b)
    RotateLeft(by) -> input |> rotate_left(by) |> Ok
    RotateRight(by) -> input |> rotate_right(by) |> Ok
    RotateRightBasedOn(a) -> input |> rotate_basedon(a)
    ReversePositions(i, j) -> input |> reverse_positions(i, j) |> Ok
    MovePosition(i, j) -> input |> move_position(i, j)
  }
}

fn undo_rule(rule: Rule, input: Letters) -> Result(Letters, String) {
  case rule {
    SwapPositions(i, j) -> input |> swap_positions(j, i)
    SwapLetters(a, b) -> input |> swap_letters(b, a)
    RotateLeft(by) -> input |> rotate_right(by) |> Ok
    RotateRight(by) -> input |> rotate_left(by) |> Ok
    RotateRightBasedOn(a) -> input |> unrotate_basedon(a)
    ReversePositions(i, j) -> input |> reverse_positions(i, j) |> Ok
    MovePosition(i, j) -> input |> move_position(j, i)
  }
}

fn scramble(
  rules: List(Rule),
  process_rule: fn(Rule, Letters) -> Result(Letters, String),
  input: Letters,
) -> Result(String, String) {
  case rules {
    [rule, ..rest] -> {
      use input <- try(process_rule(rule, input))
      scramble(rest, process_rule, input)
    }
    _ ->
      input
      |> code_tostring
      |> Ok
  }
}

pub fn main(input: String) -> Result(Nil, String) {
  use rules <- try(
    input
    |> string.trim
    |> string.split("\n")
    |> parse_lines,
  )

  use output <- try(
    rules
    |> scramble(
      do_rule,
      "abcdefgh"
        |> parse_code,
    ),
  )

  output
  |> io.println

  use output <- try(
    rules
    |> list.reverse
    |> scramble(
      undo_rule,
      "fbgdceah"
        |> parse_code,
    ),
  )

  output
  |> io.println

  Ok(Nil)
}
