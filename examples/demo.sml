(* demo.sml - runtime dimensional analysis on fixed quantities. Dimensions are
   printed with the library's own deterministic Dim.toString; magnitudes are
   obtained with `convert` and printed through a forced-decimal formatter
   (fixed 6 fractional digits, leading "-" for negatives) rather than
   Real.toString, whose formatting differs across compilers. Every conversion
   here is chosen to land on an exact value, so the rounded output is identical
   on every run and on both compilers. *)

(* Forced-decimal real formatter: always a decimal point, 6 fractional digits,
   leading "-" (not "~"). Rounding to 6 dp absorbs last-bit float noise so the
   text is stable across compilers. *)
fun fmtReal r =
  let
    val s = if Real.signBit r then "-" else ""
    val a = Real.abs r
    val scaled = Real.realRound (a * 1000000.0)
    val whole = Real.floor (scaled / 1000000.0)
    val frac  = Real.floor scaled - whole * 1000000
    fun pad6 n = StringCvt.padLeft #"0" 6 (Int.toString n)
  in s ^ Int.toString whole ^ "." ^ pad6 frac end

structure U  = Units
structure Un = U.Units
structure P  = U.Prefix
structure T  = U.Temperature

fun mul (a, b) = U.* (a, b)
fun quot (a, b) = U./ (a, b)

(* 90 km/h expressed in m/s *)
val speed = U.scale (90.0, quot (P.kilo Un.metre, Un.hour))
val () = print ("90 km/h in m/s = " ^ fmtReal (U.convert (speed, quot (Un.metre, Un.second)))
                ^ "   dim = " ^ U.Dim.toString (U.dim speed) ^ "\n")

(* Force: F = m * a = 2 kg * 3 m/s^2 *)
val accel = U.scale (3.0, quot (quot (Un.metre, Un.second), Un.second))
val force = mul (U.scale (2.0, Un.kilogram), accel)
val () = print ("2 kg * 3 m/s^2 = " ^ fmtReal (U.convert (force, Un.newton))
                ^ " N   dim = " ^ U.Dim.toString (U.dim force) ^ "\n")

(* Energy: E = F * d = 10 N * 5 m *)
val energy = mul (U.scale (10.0, Un.newton), U.scale (5.0, Un.metre))
val () = print ("10 N * 5 m     = " ^ fmtReal (U.convert (energy, Un.joule))
                ^ " J   dim = " ^ U.Dim.toString (U.dim energy) ^ "\n")

(* Affine temperature conversions *)
val () = print ("100 C in F     = " ^ fmtReal (T.toFahrenheit (T.fromCelsius 100.0)) ^ "\n")
val () = print ("32 F in C      = " ^ fmtReal (T.toCelsius (T.fromFahrenheit 32.0)) ^ "\n")
