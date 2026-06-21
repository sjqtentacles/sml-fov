signature FOV =
sig
  type grid

  (* gridMake width height isOpaquePred *)
  val gridMake      : int -> int -> (int*int -> bool) -> grid
  val gridSetOpaque : grid -> int*int -> bool -> grid

  (* compute grid origin radius -> visible cells list *)
  val compute : grid -> int*int -> int -> (int*int) list

  (* line-of-sight: true if no opaque cell blocks the line *)
  val los : grid -> int*int -> int*int -> bool
end
