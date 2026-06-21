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

  (* compute: return every cell in [radius] of origin that has line-of-sight.
     Iterates all cells in the bounding box, filters by Chebyshev-circle, then
     tests LOS via Bresenham. Simple and correct. *)
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
end
