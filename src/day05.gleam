import gleam/bit_array
import gleam/crypto

pub fn main(input: String) -> Result(Nil, String) {
  let digest = crypto.hash(crypto.Md5, <<"abc3231929":utf8>>)

  echo digest |> bit_array.base64_encode

  Ok(Nil)
}
