structure FovTests =
struct
  fun run () =
    let
      val openGrid = Fov.gridMake 5 5 (fn _ => false)
      val visFromCenter = Fov.compute openGrid (2, 2) 3
    in
      Harness.section "FOV open field";
      Harness.check "origin visible" (List.exists (fn p => p = (2, 2)) visFromCenter);
      let
        val wallGrid = Fov.gridMake 5 5 (fn (x, y) => x = 2 andalso y = 3)
        val visWithWall = Fov.compute wallGrid (2, 2) 5
      in
        Harness.check "wall cell itself visible"
          (List.exists (fn p => p = (2, 3)) visWithWall);
        Harness.check "cell behind wall not visible"
          (not (List.exists (fn p => p = (2, 4)) visWithWall))
      end;
      Harness.section "LOS";
      let
        val gOpen = Fov.gridMake 10 10 (fn _ => false)
        val gWall = Fov.gridMake 10 10 (fn (x, y) => x = 5 andalso y = 5)
      in
        Harness.check "los open" (Fov.los gOpen (0, 0) (9, 9));
        Harness.check "los to self" (Fov.los gOpen (3, 3) (3, 3));
        Harness.check "los blocked by wall"
          (not (Fov.los gWall (0, 0) (9, 9)))
      end;
      Harness.section "gridSetOpaque";
      let
        val g0 = Fov.gridMake 3 3 (fn _ => false)
        val g1 = Fov.gridSetOpaque g0 (1, 1) true
        val visOpen   = Fov.compute g0 (0, 0) 4
        val visWalled = Fov.compute g1 (0, 0) 4
      in
        Harness.check "center transparent before set"
          (List.exists (fn p => p = (1, 1)) visOpen);
        Harness.check "center opaque after set"
          (List.exists (fn p => p = (1, 1)) visWalled);
        (* (2,2) is behind (1,1) diagonal - should be blocked *)
        Harness.check "corner behind wall blocked"
          (not (List.exists (fn p => p = (2, 2)) visWalled))
      end;

      Harness.section "shadowcasting basics";
      let
        val g = Fov.gridMake 7 7 (fn _ => false)
        val vis = Fov.computeShadow g (3, 3) 3
        fun seesS p = List.exists (fn q => q = p) vis
      in
        Harness.check "origin visible" (seesS (3, 3));
        Harness.check "adjacent visible" (seesS (3, 4));
        Harness.check "edge of radius visible" (seesS (3, 6));
        Harness.check "no duplicates"
          (List.length vis = List.length (
             List.foldl (fn (p, acc) =>
               if List.exists (fn q => q = p) acc then acc else p :: acc) [] vis));
        Harness.check "isVisible agrees with list" (Fov.isVisible g (3, 3) 3 (3, 6));
        Harness.check "isVisible false out of radius"
          (not (Fov.isVisible g (3, 3) 1 (3, 6)))
      end;

      Harness.section "shadowcasting symmetry";
      let
        (* open field: symmetric visibility. A sees B <=> B sees A. *)
        val g = Fov.gridMake 11 11 (fn _ => false)
        val r = 4
        val a = (5, 5)
        val visA = Fov.computeShadow g a r
        fun symOk () =
          List.all (fn b => Fov.isVisible g b r a) visA
      in
        Harness.check "open-field FOV is symmetric" (symOk ())
      end;

      Harness.section "shadowcasting blocks shadow";
      let
        (* a single pillar should cast a shadow directly behind it *)
        val g = Fov.gridMake 11 11 (fn (x, y) => x = 6 andalso y = 5)
        val vis = Fov.computeShadow g (5, 5) 5
        fun seesS p = List.exists (fn q => q = p) vis
      in
        Harness.check "pillar itself visible" (seesS (6, 5));
        Harness.check "cell just behind pillar hidden" (not (seesS (8, 5)));
        Harness.check "cell off the shadow axis visible" (seesS (8, 8))
      end;

      Harness.section "radius metrics";
      let
        val g = Fov.gridMake 11 11 (fn _ => false)
        val orig = (5, 5)
        fun sees metric p =
          List.exists (fn q => q = p) (Fov.computeWith metric g orig 3)
      in
        (* Manhattan disk excludes the far diagonal corner (|2|+|2|=4 > 3) *)
        Harness.check "manhattan excludes diagonal corner"
          (not (sees Fov.Manhattan (7, 7)));
        (* Chebyshev includes it (max(2,2)=2 <= 3) *)
        Harness.check "chebyshev includes diagonal corner"
          (sees Fov.Chebyshev (7, 7));
        (* Euclidean: dx=2,dy=2 -> 8 <= 9, included *)
        Harness.check "euclidean includes near diagonal"
          (sees Fov.Euclidean (7, 7));
        (* Chebyshev includes a straight cell at distance 3 *)
        Harness.check "chebyshev includes straight edge"
          (sees Fov.Chebyshev (8, 5))
      end;

      Harness.section "explored/seen memory";
      let
        val g = Fov.gridMake 11 11 (fn _ => false)
        val frame1 = Fov.computeShadow g (2, 2) 2
        val frame2 = Fov.computeShadow g (8, 8) 2
        val s0 = Fov.markAllSeen Fov.seenEmpty frame1
        val s1 = Fov.markAllSeen s0 frame2
      in
        Harness.check "seen remembers frame1 cell" (Fov.isSeen s1 (2, 2));
        Harness.check "seen remembers frame2 cell" (Fov.isSeen s1 (8, 8));
        Harness.check "unseen cell not remembered" (not (Fov.isSeen s1 (5, 0)));
        Harness.check "markSeen idempotent"
          (List.length (Fov.seenList (Fov.markSeen s1 (2, 2)))
             = List.length (Fov.seenList s1));
        Harness.check "seenList sorted/deduped"
          (let val l = Fov.seenList s1
           in List.length l =
              List.length (List.foldl (fn (p, acc) =>
                if List.exists (fn q => q = p) acc then acc else p :: acc) [] l)
           end)
      end;
      ()
    end
end
