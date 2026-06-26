signature FOV =
sig
  type grid

  (* gridMake width height isOpaquePred *)
  val gridMake      : int -> int -> (int*int -> bool) -> grid
  val gridSetOpaque : grid -> int*int -> bool -> grid

  (* Distance metric used to shape the field-of-view radius. *)
  datatype metric = Euclidean | Chebyshev | Manhattan

  (* compute grid origin radius -> visible cells list.
     Brute-force Bresenham over a Euclidean disk; kept for back-compat. *)
  val compute : grid -> int*int -> int -> (int*int) list

  (* Recursive shadowcasting field-of-view (8 octants): symmetric and free of
     the artifacts of per-cell ray casting. Euclidean radius. *)
  val computeShadow : grid -> int*int -> int -> (int*int) list

  (* Shadowcasting with a selectable radius metric. *)
  val computeWith : metric -> grid -> int*int -> int -> (int*int) list

  (* True iff `target` is visible from `origin` within `radius` under
     shadowcasting. *)
  val isVisible : grid -> int*int -> int -> int*int -> bool

  (* line-of-sight: true if no opaque cell blocks the line *)
  val los : grid -> int*int -> int*int -> bool

  (* --- explored / "seen" memory layer ---
     Roguelikes remember tiles once seen even when no longer visible. `seen`
     is a persistent set of cells; fold a frame's visible cells into it. *)
  type seen
  val seenEmpty   : seen
  val markSeen    : seen -> int*int -> seen
  val markAllSeen : seen -> (int*int) list -> seen
  val isSeen      : seen -> int*int -> bool
  val seenList    : seen -> (int*int) list   (* sorted, de-duplicated *)
end
