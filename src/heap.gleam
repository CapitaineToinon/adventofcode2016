import gleam/order.{type Order, Lt}

pub type Tree(a) {
  Empty
  Tree(elem: a, subheaps: List(Tree(a)))
}

pub type Heap(a) {
  Heap(root: Tree(a), cmp: fn(a, a) -> Order)
}

pub fn new(cmp: fn(a, a) -> Order) -> Heap(a) {
  Heap(Empty, cmp)
}

fn meld(heap1: Tree(a), heap2: Tree(a), cmp: fn(a, a) -> Order) -> Tree(a) {
  case heap1, heap2 {
    Empty, y -> y
    x, Empty -> x
    Tree(xe, _), Tree(ye, _) ->
      case cmp(xe, ye) {
        Lt -> Tree(xe, [heap2, ..heap1.subheaps])
        _ -> Tree(ye, [heap1, ..heap2.subheaps])
      }
  }
}

pub fn insert(heap: Heap(a), elem: a) -> Heap(a) {
  Heap(meld(heap.root, Tree(elem, []), heap.cmp), heap.cmp)
}

pub fn find_min(heap: Heap(a)) -> Result(a, Nil) {
  case heap.root {
    Empty -> Error(Nil)
    Tree(elem, _) -> Ok(elem)
  }
}

pub fn pop_min(heap: Heap(a)) -> Result(#(Heap(a), a), Nil) {
  case heap.root {
    Empty -> Error(Nil)
    Tree(elem, sub) -> Ok(#(Heap(merge_pairs(sub, heap.cmp), heap.cmp), elem))
  }
}

pub fn is_empty(heap: Heap(a)) -> Bool {
  heap.root == Empty
}

fn merge_pairs(list: List(Tree(a)), cmp: fn(a, a) -> Order) -> Tree(a) {
  case list {
    [] -> Empty
    [el] -> el
    [first, second, ..rest] -> {
      meld(meld(first, second, cmp), merge_pairs(rest, cmp), cmp)
    }
  }
}
