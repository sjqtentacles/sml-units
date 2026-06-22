(* units.sml

   Implementation of runtime dimensional analysis. Dimensions are a 7-tuple of
   integer exponents over the SI base dimensions; a quantity is a real
   magnitude (already reduced to SI base units) tagged with its dimension. *)

structure Units :> UNITS =
struct

  structure Dim =
  struct
    (* (mass, length, time, current, temperature, amount, luminosity) *)
    type t = int * int * int * int * int * int * int

    val dimensionless = (0, 0, 0, 0, 0, 0, 0)

    val mass        = (1, 0, 0, 0, 0, 0, 0)
    val length      = (0, 1, 0, 0, 0, 0, 0)
    val time        = (0, 0, 1, 0, 0, 0, 0)
    val current     = (0, 0, 0, 1, 0, 0, 0)
    val temperature = (0, 0, 0, 0, 1, 0, 0)
    val amount      = (0, 0, 0, 0, 0, 1, 0)
    val luminosity  = (0, 0, 0, 0, 0, 0, 1)

    fun equal ((a1,a2,a3,a4,a5,a6,a7), (b1,b2,b3,b4,b5,b6,b7)) =
        a1=b1 andalso a2=b2 andalso a3=b3 andalso a4=b4
        andalso a5=b5 andalso a6=b6 andalso a7=b7

    fun mul ((a1,a2,a3,a4,a5,a6,a7), (b1,b2,b3,b4,b5,b6,b7)) =
        (a1+b1, a2+b2, a3+b3, a4+b4, a5+b5, a6+b6, a7+b7)

    fun divide ((a1,a2,a3,a4,a5,a6,a7), (b1,b2,b3,b4,b5,b6,b7)) =
        (a1-b1, a2-b2, a3-b3, a4-b4, a5-b5, a6-b6, a7-b7)
    val op div = divide

    fun inv (a1,a2,a3,a4,a5,a6,a7) =
        (~a1, ~a2, ~a3, ~a4, ~a5, ~a6, ~a7)

    fun pow ((a1,a2,a3,a4,a5,a6,a7), n) =
        (a1*n, a2*n, a3*n, a4*n, a5*n, a6*n, a7*n)

    fun toString (m,l,t,i,k,n,j) =
        let
          val parts = [("kg", m), ("m", l), ("s", t), ("A", i),
                       ("K", k), ("mol", n), ("cd", j)]
          fun render (sym, e) =
              if e = 0 then NONE
              else if e = 1 then SOME sym
              else SOME (sym ^ "^" ^ (if e < 0 then "-" ^ Int.toString (~e)
                                      else Int.toString e))
          val shown = List.mapPartial render parts
        in
          case shown of
              [] => "1"
            | _  => String.concatWith " " shown
        end
  end

  type quantity = real * Dim.t
  type t = quantity

  exception Dimension

  fun scalar x = (x, Dim.dimensionless)
  fun quantity (x, d) = (x, d)

  fun magnitude (x, _) = x
  fun dim (_, d) = d

  fun dimensionless (_, d) = Dim.equal (d, Dim.dimensionless)

  fun add ((x, dx), (y, dy)) =
      if Dim.equal (dx, dy) then (Real.+ (x, y), dx) else raise Dimension

  fun sub ((x, dx), (y, dy)) =
      if Dim.equal (dx, dy) then (Real.- (x, y), dx) else raise Dimension

  fun mul ((x, dx), (y, dy)) = (Real.* (x, y), Dim.mul (dx, dy))

  fun quot ((x, dx), (y, dy)) = (Real./ (x, y), Dim.div (dx, dy))

  fun neg (x, d) = (Real.~ x, d)

  fun pow ((x, d), n) = (Math.pow (x, Real.fromInt n), Dim.pow (d, n))

  fun scale (k, (x, d)) = (Real.* (k, x), d)

  fun convert ((x, dx), (u, du)) =
      if Dim.equal (dx, du) then Real./ (x, u) else raise Dimension

  fun convertOpt (q as (_, dx), unit as (_, du)) =
      if Dim.equal (dx, du) then SOME (convert (q, unit)) else NONE

  val op + = add
  val op - = sub
  val op * = mul
  val op / = quot
  val op ~ = neg

  fun equal ((x, dx), (y, dy)) =
      if Dim.equal (dx, dy) then Real.== (x, y) else raise Dimension

  fun compare ((x, dx), (y, dy)) =
      if Dim.equal (dx, dy) then Real.compare (x, y) else raise Dimension

  fun toString (x, d) =
      if Dim.equal (d, Dim.dimensionless)
      then Real.toString x
      else Real.toString x ^ " " ^ Dim.toString d

  structure Units =
  struct
    val kilogram = (1.0, Dim.mass)
    val metre    = (1.0, Dim.length)
    val second   = (1.0, Dim.time)
    val ampere   = (1.0, Dim.current)
    val kelvin   = (1.0, Dim.temperature)
    val mole     = (1.0, Dim.amount)
    val candela  = (1.0, Dim.luminosity)

    val newton  = quot (mul (kilogram, metre), mul (second, second))
    val joule   = mul (newton, metre)
    val watt    = quot (joule, second)
    val pascal  = quot (newton, mul (metre, metre))
    val hertz   = quot (scalar 1.0, second)
    val coulomb = mul (ampere, second)
    val volt    = quot (watt, ampere)

    val minute  = scale (60.0, second)
    val hour    = scale (3600.0, second)
  end

  structure Prefix =
  struct
    fun tera  q = scale (1E12,  q)
    fun giga  q = scale (1E9,   q)
    fun mega  q = scale (1E6,   q)
    fun kilo  q = scale (1E3,   q)
    fun hecto q = scale (1E2,   q)
    fun deca  q = scale (1E1,   q)
    fun deci  q = scale (1E~1,  q)
    fun centi q = scale (1E~2,  q)
    fun milli q = scale (1E~3,  q)
    fun micro q = scale (1E~6,  q)
    fun nano  q = scale (1E~9,  q)
    fun pico  q = scale (1E~12, q)
  end

  structure Temperature =
  struct
    val zeroCelsius = 273.15   (* K *)

    fun fromCelsius c = (Real.+ (c, zeroCelsius), Dim.temperature)

    fun toCelsius (k, d) =
        if Dim.equal (d, Dim.temperature)
        then Real.- (k, zeroCelsius)
        else raise Dimension

    fun fromFahrenheit f =
        (Real.+ (Real.* (Real.- (f, 32.0), Real./ (5.0, 9.0)), zeroCelsius),
         Dim.temperature)

    fun toFahrenheit (k, d) =
        if Dim.equal (d, Dim.temperature)
        then Real.+ (Real.* (Real.- (k, zeroCelsius), Real./ (9.0, 5.0)), 32.0)
        else raise Dimension
  end
end
