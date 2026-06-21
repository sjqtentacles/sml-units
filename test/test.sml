(* Dependency-free test runner for the Units structure.
 * Prints one line per assertion and exits non-zero if any assertion fails. *)

structure U = Units
structure Dim = U.Dim
structure Un = U.Units

val passed = ref 0
val failed = ref 0

fun check (name : string) (cond : bool) : unit =
    if cond
    then (passed := !passed + 1; print ("ok   - " ^ name ^ "\n"))
    else (failed := !failed + 1; print ("FAIL - " ^ name ^ "\n"))

fun raisesDimension (thunk : unit -> 'a) : bool =
    (ignore (thunk ()); false) handle U.Dimension => true | _ => false

(* Real comparison with a small tolerance, to keep tests robust against the
 * last bit of floating-point rounding in derived units. *)
fun close (a, b) = Real.abs (a - b) < 1E~9

infix 6 ++ --
infix 7 ** //
val op ++ = U.+
val op -- = U.-
val op ** = U.*
val op // = U./

fun run () =
  let
    (* Dim algebra *)
    val () = check "dimensionless toString = 1"
                   (Dim.toString Dim.dimensionless = "1")
    val () = check "mass toString = kg" (Dim.toString Dim.mass = "kg")
    val () = check "length toString = m" (Dim.toString Dim.length = "m")
    val () = check "mul adds exponents (area)"
                   (Dim.toString (Dim.mul (Dim.length, Dim.length)) = "m^2")
    val () = check "div subtracts exponents (speed)"
                   (Dim.toString (Dim.div (Dim.length, Dim.time)) = "m s^-1")
    val () = check "inv negates exponents"
                   (Dim.toString (Dim.inv Dim.time) = "s^-1")
    val () = check "pow scales exponents"
                   (Dim.toString (Dim.pow (Dim.length, 3)) = "m^3")
    val () = check "pow 0 is dimensionless"
                   (Dim.equal (Dim.pow (Dim.mass, 0), Dim.dimensionless))
    val () = check "mul then div round-trips"
                   (Dim.equal (Dim.div (Dim.mul (Dim.length, Dim.time), Dim.time),
                               Dim.length))
    val () = check "newton dimension is kg m s^-2"
                   (Dim.toString (U.dim Un.newton) = "kg m s^-2")
    val () = check "joule dimension is kg m^2 s^-2"
                   (Dim.toString (U.dim Un.joule) = "kg m^2 s^-2")

    (* Construction / projection *)
    val () = check "scalar is dimensionless" (U.dimensionless (U.scalar 3.0))
    val () = check "scalar magnitude" (close (U.magnitude (U.scalar 3.0), 3.0))
    val () = check "metre not dimensionless" (not (U.dimensionless Un.metre))

    (* Same-dimension addition / subtraction *)
    val threeMetres = U.scale (3.0, Un.metre)
    val fourMetres  = U.scale (4.0, Un.metre)
    val () = check "3 m + 4 m = 7 m"
                   (close (U.magnitude (threeMetres ++ fourMetres), 7.0)
                    andalso Dim.equal (U.dim (threeMetres ++ fourMetres), Dim.length))
    val () = check "4 m - 3 m = 1 m"
                   (close (U.magnitude (fourMetres -- threeMetres), 1.0))

    (* Mismatched dimensions raise *)
    val oneSecond = U.scale (1.0, Un.second)
    val () = check "m + s raises Dimension"
                   (raisesDimension (fn () => threeMetres ++ oneSecond))
    val () = check "m - s raises Dimension"
                   (raisesDimension (fn () => threeMetres -- oneSecond))
    val () = check "equal across dims raises Dimension"
                   (raisesDimension (fn () => U.equal (threeMetres, oneSecond)))
    val () = check "compare across dims raises Dimension"
                   (raisesDimension (fn () => U.compare (threeMetres, oneSecond)))

    (* Multiplication / division build new dimensions *)
    val area = threeMetres ** fourMetres
    val () = check "3 m * 4 m = 12 m^2 (magnitude)"
                   (close (U.magnitude area, 12.0))
    val () = check "3 m * 4 m = 12 m^2 (dimension)"
                   (Dim.equal (U.dim area, Dim.pow (Dim.length, 2)))
    val speed = U.scale (10.0, Un.metre) // U.scale (2.0, Un.second)
    val () = check "10 m / 2 s = 5 m/s (magnitude)"
                   (close (U.magnitude speed, 5.0))
    val () = check "10 m / 2 s = 5 m/s (dimension)"
                   (Dim.toString (U.dim speed) = "m s^-1")

    (* Negation and power *)
    val () = check "negate magnitude"
                   (close (U.magnitude (U.~ threeMetres), ~3.0))
    val cube = U.pow (U.scale (2.0, Un.metre), 3)
    val () = check "(2 m)^3 = 8 m^3 (magnitude)" (close (U.magnitude cube, 8.0))
    val () = check "(2 m)^3 = 8 m^3 (dimension)"
                   (Dim.equal (U.dim cube, Dim.pow (Dim.length, 3)))
    val inverse = U.pow (U.scale (4.0, Un.second), ~1)
    val () = check "(4 s)^-1 = 0.25 s^-1 (magnitude)"
                   (close (U.magnitude inverse, 0.25))
    val () = check "(4 s)^-1 dimension is s^-1"
                   (Dim.toString (U.dim inverse) = "s^-1")

    (* equal / compare within a dimension *)
    val () = check "3 m equal 3 m" (U.equal (threeMetres, U.scale (3.0, Un.metre)))
    val () = check "3 m not equal 4 m" (not (U.equal (threeMetres, fourMetres)))
    val () = check "compare 3 m 4 m = LESS"
                   (U.compare (threeMetres, fourMetres) = LESS)
    val () = check "compare 4 m 3 m = GREATER"
                   (U.compare (fourMetres, threeMetres) = GREATER)

    (* A physics sanity check: F = m a, 2 kg * 9.81 m/s^2 ~ 19.62 N *)
    val accel = U.scale (9.81, Un.metre) // (oneSecond ** oneSecond)
    val force = U.scale (2.0, Un.kilogram) ** accel
    val () = check "F = m a has newton dimension"
                   (Dim.equal (U.dim force, U.dim Un.newton))
    val () = check "F = m a magnitude ~ 19.62"
                   (close (U.magnitude force, 19.62))

    (* Derived-unit identities *)
    val () = check "watt = joule / second (dimension)"
                   (Dim.equal (U.dim Un.watt, U.dim (Un.joule // Un.second)))
    val () = check "volt = watt / ampere (dimension)"
                   (Dim.equal (U.dim Un.volt, U.dim (Un.watt // Un.ampere)))
    val () = check "hertz = 1 / second (dimension)"
                   (Dim.toString (U.dim Un.hertz) = "s^-1")
    val () = check "coulomb = ampere second (dimension)"
                   (Dim.toString (U.dim Un.coulomb) = "s A")

    (* toString *)
    val () = check "scalar toString has no unit"
                   (U.toString (U.scalar 2.5) = Real.toString 2.5)
    val () = check "quantity toString has unit suffix"
                   (U.toString threeMetres = Real.toString 3.0 ^ " m")
  in
    print ("\n" ^ Int.toString (!passed) ^ " passed, "
           ^ Int.toString (!failed) ^ " failed\n");
    OS.Process.exit (if !failed = 0 then OS.Process.success else OS.Process.failure)
  end

val () = run ()
