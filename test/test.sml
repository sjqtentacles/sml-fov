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
      ()
    end
end
