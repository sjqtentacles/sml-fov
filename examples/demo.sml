(* demo.sml - recursive shadowcasting field-of-view and Bresenham
   line-of-sight on a small tile grid. Deterministic: no RNG, no clock;
   identical output on every run and on both MLton and Poly/ML. *)

fun pInt i = Int.toString i
fun yn b = if b then "yes" else "no"

(* 10x10 grid, fully transparent except a wall column at x=5 (rows 0..6). *)
val base = Fov.gridMake 10 10 (fn _ => false)
val grid =
  List.foldl (fn (y, g) => Fov.gridSetOpaque g (5, y) true) base [0,1,2,3,4,5,6]

val origin = (2, 2)
val radius = 6
val vis = Fov.compute grid origin radius
fun seen p = List.exists (fn q => q = p) vis

val () = print "Field of view (10x10, wall column x=5 rows 0..6):\n"
val () = print ("  origin        = (" ^ pInt (#1 origin) ^ ", " ^ pInt (#2 origin) ^ ")\n")
val () = print ("  radius        = " ^ pInt radius ^ "\n")
val () = print ("  visible cells = " ^ pInt (List.length vis) ^ "\n")
val () = print ("  sees origin (2,2)?       " ^ yn (seen (2,2)) ^ "\n")
val () = print ("  sees near wall (4,2)?    " ^ yn (seen (4,2)) ^ "\n")
val () = print ("  sees behind wall (7,2)?  " ^ yn (seen (7,2)) ^ "\n")

val () = print "\nLine of sight:\n"
val () = print ("  (2,2) -> (4,2) clear?    " ^ yn (Fov.los grid (2,2) (4,2)) ^ "\n")
val () = print ("  (2,2) -> (8,2) clear?    " ^ yn (Fov.los grid (2,2) (8,2)) ^ "\n")
val () = print ("  (2,8) -> (8,8) clear?    " ^ yn (Fov.los grid (2,8) (8,8)) ^ "\n")
