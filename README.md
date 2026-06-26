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

(* Recursive shadowcasting field-of-view from an origin within a radius.
   Symmetric (A sees B iff B sees A on open ground) and artifact-free. *)
val visible : (int * int) list = Fov.computeShadow grid' (2, 2) 8

(* Is one specific tile visible? *)
val canSee = Fov.isVisible grid' (2, 2) 8 (5, 5)   (* => true (the wall) *)

(* Choose the radius shape with a distance metric *)
val diamond = Fov.computeWith Fov.Manhattan grid' (2, 2) 8
val square  = Fov.computeWith Fov.Chebyshev grid' (2, 2) 8
val circle  = Fov.computeWith Fov.Euclidean grid' (2, 2) 8

(* Brute-force per-cell Bresenham FOV (kept for back-compat) *)
val visible2 = Fov.compute grid' (2, 2) 8

(* Bresenham line-of-sight between two cells *)
val clear = Fov.los grid' (0, 0) (9, 9)
(* => true if no opaque tile lies on the line *)
```

### Explored / "seen" memory

Roguelikes remember tiles once seen even when they fall out of view. `seen` is
a persistent set; fold each frame's visible cells into it:

```sml
val explored0 = Fov.seenEmpty
val explored1 = Fov.markAllSeen explored0 (Fov.computeShadow grid' (2, 2) 8)
val explored2 = Fov.markAllSeen explored1 (Fov.computeShadow grid' (9, 9) 8)

val remembered = Fov.isSeen explored2 (2, 2)   (* => true *)
val allSeen    = Fov.seenList explored2         (* sorted, de-duplicated *)
```

## API

| Function | Description |
| --- | --- |
| `gridMake : int -> int -> (int*int -> bool) -> grid` | Build a grid from an opacity predicate. |
| `gridSetOpaque : grid -> int*int -> bool -> grid` | Set one cell's opacity (persistent copy). |
| `computeShadow : grid -> int*int -> int -> (int*int) list` | Symmetric shadowcasting FOV (Euclidean radius). |
| `computeWith : metric -> grid -> int*int -> int -> (int*int) list` | Shadowcasting with `Euclidean`/`Chebyshev`/`Manhattan` radius. |
| `isVisible : grid -> int*int -> int -> int*int -> bool` | Visibility of one target. |
| `compute : grid -> int*int -> int -> (int*int) list` | Brute-force Bresenham FOV (back-compat). |
| `los : grid -> int*int -> int*int -> bool` | Bresenham line-of-sight. |
| `seenEmpty / markSeen / markAllSeen / isSeen / seenList` | Persistent explored-tile memory. |

## Scope and limitations

- `computeShadow`/`computeWith` use **recursive shadowcasting** over 8 octants:
  symmetric on open ground and free of the asymmetry/artifacts of per-cell ray
  casting. `compute` remains a simpler Bresenham-per-cell FOV and may disagree
  with shadowcasting near walls; it is kept only for back-compat.
- The radius `metric` shapes which in-window cells are reported: `Euclidean`
  (disk), `Chebyshev` (square), `Manhattan` (diamond). Walls always block via
  the same slope geometry regardless of metric.
- A wall/opaque cell is itself reported visible (you can see the wall face), but
  cells in its shadow are not.
- Grids are square-tile, 2D, single light source. There is no light
  falloff/intensity, no directional/cone FOV, and no diagonal-wall corner rules.
- `gridSetOpaque` copies the whole grid array (persistent, O(w*h) per update).
- `seen` is an ordered list set; membership and insert are O(n).

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
