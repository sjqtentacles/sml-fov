structure Fov :> FOV =
struct
  type grid = {w: int, h: int, opaque: bool Array.array}

  fun gridMake w h isOp =
    { w = w
    , h = h
    , opaque = Array.tabulate (w * h, fn idx =>
        let val gx = idx mod w
            val gy = idx div w
        in isOp (gx, gy) end)
    }

  fun gridSetOpaque (g : grid) (x, y) b =
    let val gw = #w g
        val gh = #h g
        val src = #opaque g
        val newArr = Array.tabulate (gw * gh, fn i => Array.sub (src, i))
    in
      Array.update (newArr, y * gw + x, b);
      {w = gw, h = gh, opaque = newArr}
    end

  datatype metric = Euclidean | Chebyshev | Manhattan

  fun inBounds (g : grid) (x, y) =
    x >= 0 andalso y >= 0 andalso x < #w g andalso y < #h g

  fun cellOpaque (g : grid) (x, y) =
    inBounds g (x, y) andalso Array.sub (#opaque g, y * #w g + x)

  (* Bresenham line-of-sight.
     Source cell is never treated as a blocker.
     Returns true if the destination is reachable without hitting an opaque cell
     (the destination itself IS allowed to be opaque - the wall is visible). *)
  fun los (g : grid) (x0, y0) (x1, y1) =
    if x0 = x1 andalso y0 = y1 then true
    else
      let
        val dx = abs (x1 - x0)
        val dy = abs (y1 - y0)
        val sx = if x0 < x1 then 1 else ~1
        val sy = if y0 < y1 then 1 else ~1
        (* Walk from (x0,y0) toward (x1,y1).
           Block on any opaque cell that is NOT the source and NOT the destination. *)
        fun step x y err =
          if x = x1 andalso y = y1 then true
          else if cellOpaque g (x, y) andalso not (x = x0 andalso y = y0) then false
          else
            let val e2 = 2 * err
                val (nx, ne1) =
                  if e2 > ~dy then (x + sx, err - dy) else (x, err)
                val (ny, ne2) =
                  if e2 < dx  then (y + sy, ne1 + dx) else (y, ne1)
            in step nx ny ne2 end
      in
        step x0 y0 (dx - dy)
      end

  (* Is (dx,dy) within `radius` under the chosen metric? *)
  fun withinRadius Euclidean (dx, dy) r = dx * dx + dy * dy <= r * r
    | withinRadius Chebyshev (dx, dy) r = Int.max (abs dx, abs dy) <= r
    | withinRadius Manhattan (dx, dy) r = abs dx + abs dy <= r

  (* compute: return every cell in [radius] of origin that has line-of-sight.
     Iterates all cells in the bounding box, filters by a Euclidean disk, then
     tests LOS via Bresenham. Simple and correct; kept for back-compat. *)
  fun compute (g : grid) (ox, oy) radius =
    let
      fun inRadius (x, y) = (x - ox) * (x - ox) + (y - oy) * (y - oy) <= radius * radius

      fun tryCell (x, y) =
        if inBounds g (x, y) andalso inRadius (x, y) andalso los g (ox, oy) (x, y)
        then [(x, y)]
        else []

      fun range lo hi = if lo > hi then [] else lo :: range (lo + 1) hi
    in
      List.concat (List.concat (
        List.map (fn ddx =>
          List.map (fn ddy => tryCell (ox + ddx, oy + ddy))
            (range (~radius) radius))
          (range (~radius) radius)))
    end

  (* --- recursive shadowcasting ---

     The grid around the origin is divided into 8 octants. Each octant is swept
     row by row (distance from origin), tracking a [start, end] slope window.
     Opaque cells carve "shadows" by splitting the window; transparent cells
     within the current window are marked visible. This is the standard,
     symmetric Bjorn Bergstrom algorithm. *)

  (* Transform octant-local (row, col) into a world delta. The 8 multipliers are
     the standard (xx, xy, yx, yy) sign/swap matrices for each octant. *)
  val octants =
    [ ( 1,  0,  0,  1), ( 0,  1,  1,  0),
      ( 0, ~1,  1,  0), (~1,  0,  0,  1),
      (~1,  0,  0, ~1), ( 0, ~1, ~1,  0),
      ( 0,  1, ~1,  0), ( 1,  0,  0, ~1) ]

  fun computeWith metric (g : grid) (ox, oy) radius =
    let
      val visible = ref [(ox, oy)]   (* origin is always visible *)

      fun mark (x, y) =
        if inBounds g (x, y) then visible := (x, y) :: !visible else ()

      (* Standard recursive shadowcasting for one octant (RogueBasin form).
         Rows j run outward from the origin; within a row, dx runs from -(j) up
         to 0. `start`/`endS` bound the visible slope window. *)
      fun castLight (xx, xy, yx, yy) row start endS =
        if start < endS then ()
        else
          let
            fun doRow j curStart =
              if j > radius then ()
              else
                let
                  val dy = ~j
                  val blocked = ref false
                  val newStart = ref curStart
                  (* returns true if the rest of the octant is blocked *)
                  fun doCol dx =
                    if dx > 0 then ()
                    else
                      let
                        val lSlope = (real dx - 0.5) / (real dy + 0.5)
                        val rSlope = (real dx + 0.5) / (real dy - 0.5)
                      in
                        if !newStart < rSlope then doCol (dx + 1)
                        else if endS > lSlope then ()  (* beyond window; stop row *)
                        else
                          let
                            val wx = ox + dx * xx + dy * xy
                            val wy = oy + dx * yx + dy * yy
                            val () =
                              if withinRadius metric (dx, dy) radius
                              then mark (wx, wy) else ()
                            val isOp = cellOpaque g (wx, wy)
                          in
                            if !blocked then
                              if isOp then (newStart := rSlope; doCol (dx + 1))
                              else (blocked := false; doCol (dx + 1))
                            else
                              if isOp andalso j < radius then
                                (blocked := true;
                                 castLight (xx, xy, yx, yy) (j + 1) (!newStart) lSlope;
                                 newStart := rSlope;
                                 doCol (dx + 1))
                              else doCol (dx + 1)
                          end
                      end
                in
                  doCol (~j);
                  if !blocked then () else doRow (j + 1) (!newStart)
                end
          in
            doRow row start
          end
    in
      if radius < 0 then []
      else
        ( mark (ox, oy)
        ; List.app (fn oct => castLight oct 1 1.0 0.0) octants
        ; (* de-duplicate via sorted insertion *)
          let
            fun ins (p, []) = [p]
              | ins (p as (px, py), (q as (qx, qy)) :: rest) =
                  if p = q then q :: rest
                  else if px < qx orelse (px = qx andalso py < qy)
                  then p :: q :: rest
                  else q :: ins (p, rest)
          in List.foldl ins [] (!visible) end )
    end

  fun computeShadow g origin radius = computeWith Euclidean g origin radius

  fun isVisible g origin radius target =
    List.exists (fn p => p = target) (computeShadow g origin radius)

  (* --- explored / "seen" memory layer --- *)
  type seen = (int * int) list   (* kept sorted, de-duplicated *)

  val seenEmpty = []

  fun markSeen s (x, y) =
    let
      fun ins [] = [(x, y)]
        | ins ((p as (px, py)) :: rest) =
            if (px, py) = (x, y) then p :: rest
            else if px < x orelse (px = x andalso py < y) then p :: ins rest
            else (x, y) :: p :: rest
    in ins s end

  fun markAllSeen s ps = List.foldl (fn (p, acc) => markSeen acc p) s ps

  fun isSeen s p = List.exists (fn q => q = p) s

  fun seenList s = s
end
