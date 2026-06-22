# sml-fov

[![CI](https://github.com/sjqtentacles/sml-fov/actions/workflows/ci.yml/badge.svg)](https://github.com/sjqtentacles/sml-fov/actions/workflows/ci.yml)

Recursive shadowcasting field-of-view and Bresenham line-of-sight for tile games in pure Standard ML

## Installation

```
smlpkg add github.com/sjqtentacles/sml-fov
smlpkg sync
```

## Usage

```sml
(* Create a grid: (x, y) -> bool (true = opaque/wall) *)
val grid = Fov.gridMake 20 20 (fn _ => false)

(* Mark a wall tile opaque *)
val grid' = Fov.gridSetOpaque grid (5, 5) true

(* Compute visible tiles from (origin) within radius *)
val visible : (int * int) list = Fov.compute grid' (2, 2) 8
(* Returns all (x, y) positions visible from (2,2) with radius 8 *)

(* Check if a specific tile is in the result *)
val originVisible = List.exists (fn p => p = (2, 2)) visible
(* => true *)

(* Bresenham line-of-sight *)
val clear = Fov.los grid' (0, 0) (9, 9)
(* => true if no opaque tile lies on the line *)

val blocked = Fov.los grid' (0, 0) (9, 9)  (* false if wall in path *)
```

## Example

`make example` builds and runs [`examples/demo.sml`](examples/demo.sml), which
puts a wall column on a 10x10 grid, computes the visible cells from an origin,
and probes Bresenham line-of-sight across the wall:

```
$ make example
Field of view (10x10, wall column x=5 rows 0..6):
  origin        = (2, 2)
  radius        = 6
  visible cells = 49
  sees origin (2,2)?       yes
  sees near wall (4,2)?    yes
  sees behind wall (7,2)?  no

Line of sight:
  (2,2) -> (4,2) clear?    yes
  (2,2) -> (8,2) clear?    no
  (2,8) -> (8,8) clear?    yes
```

## Testing

```
make test       # MLton
make test-poly  # Poly/ML
make example    # build + run the demo
```

## License

MIT
