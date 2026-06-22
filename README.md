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

## Testing

```
make test       # MLton
make test-poly  # Poly/ML
```

## License

MIT
