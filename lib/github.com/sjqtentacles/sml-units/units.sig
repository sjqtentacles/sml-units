(* units.sig

   Runtime dimensional analysis for physical quantities.

   A `quantity` pairs a real magnitude (expressed in SI base units) with a
   `Dim.t` describing its dimension as a 7-tuple of integer exponents over the
   SI base dimensions:

       (mass, length, time, current, temperature, amount, luminosity)

   Addition and subtraction require matching dimensions and raise `Dimension`
   otherwise. Multiplication and division add and subtract the exponents.
   Powers multiply them. Because the dimension is carried at runtime, mistakes
   like adding a length to a time are caught dynamically rather than silently
   producing nonsense. *)

signature UNITS =
sig
  (* Dimensions: a free abelian group over the seven SI base dimensions,
     written additively in the exponents. *)
  structure Dim :
  sig
    type t

    val dimensionless : t

    (* The seven SI base dimensions. *)
    val mass         : t   (* kilogram  *)
    val length       : t   (* metre     *)
    val time         : t   (* second    *)
    val current      : t   (* ampere    *)
    val temperature  : t   (* kelvin    *)
    val amount       : t   (* mole      *)
    val luminosity   : t   (* candela   *)

    val equal : t * t -> bool
    val mul   : t * t -> t        (* add exponents     *)
    val div   : t * t -> t        (* subtract exponents *)
    val inv   : t -> t            (* negate exponents  *)
    val pow   : t * int -> t      (* scale exponents   *)

    (* A stable, human-readable rendering such as "kg m s^-2" or "1" for the
       dimensionless dimension. *)
    val toString : t -> string
  end

  type quantity
  type t = quantity

  (* Raised by + and - when the operands have different dimensions. *)
  exception Dimension

  (* Construction. `scalar x` is dimensionless; `quantity (x, d)` attaches a
     dimension directly. *)
  val scalar    : real -> quantity
  val quantity  : real * Dim.t -> quantity

  (* Projection. `magnitude q` is the numeric value in SI base units. *)
  val magnitude : quantity -> real
  val dim       : quantity -> Dim.t

  val dimensionless : quantity -> bool

  (* Arithmetic. +/- raise `Dimension` on a mismatch. *)
  val +    : quantity * quantity -> quantity
  val -    : quantity * quantity -> quantity
  val *    : quantity * quantity -> quantity
  val /    : quantity * quantity -> quantity
  val ~    : quantity -> quantity
  val pow  : quantity * int -> quantity

  (* Scale a quantity by a dimensionless real. *)
  val scale : real * quantity -> quantity

  (* Unit conversion.

     Because a quantity is always stored in SI base units, a "unit" is itself a
     quantity whose magnitude is the size of one such unit in SI base units --
     e.g. `Units.metre` is 1 m, `Prefix.kilo Units.metre` is 1 km (= 1000 m),
     `Units.hour` is 1 h (= 3600 s).

     `convert (q, unit)` re-expresses `q` as a plain number of those units,
     i.e. `magnitude q / magnitude unit`, provided the dimensions agree.
     It raises `Dimension` on a mismatch (e.g. metres to seconds); `convertOpt`
     returns `NONE` instead. Conversion is purely multiplicative and so does
     not cover affine scales such as degrees Celsius -- see `Temperature`. *)
  val convert    : quantity * quantity -> real
  val convertOpt : quantity * quantity -> real option

  (* Comparison requires matching dimensions (raises `Dimension` otherwise). *)
  val equal   : quantity * quantity -> bool
  val compare : quantity * quantity -> order

  val toString : quantity -> string

  (* A small catalogue of named SI units and a few common derived ones, each a
     quantity of magnitude 1 in the appropriate dimension. Multiply a scalar by
     these to build quantities, e.g. `scale (9.81, metre / second / second)`. *)
  structure Units :
  sig
    val kilogram : quantity
    val metre    : quantity
    val second   : quantity
    val ampere   : quantity
    val kelvin   : quantity
    val mole     : quantity
    val candela  : quantity

    (* Common derived units. *)
    val newton  : quantity   (* kg m / s^2      *)
    val joule   : quantity   (* N m             *)
    val watt    : quantity   (* J / s           *)
    val pascal  : quantity   (* N / m^2         *)
    val hertz   : quantity   (* 1 / s           *)
    val coulomb : quantity   (* A s             *)
    val volt    : quantity   (* W / A           *)

    (* A couple of common non-SI time units, each expressed in seconds, handy
       as conversion targets. *)
    val minute  : quantity   (* 60 s            *)
    val hour    : quantity   (* 3600 s          *)
  end

  (* SI decimal prefixes. Each scales a unit (or any quantity) by its power of
     ten, preserving the dimension: `Prefix.kilo Units.metre` is 1 km, i.e. a
     quantity of magnitude 1000 with the length dimension. *)
  structure Prefix :
  sig
    val tera  : quantity -> quantity   (* 10^12  *)
    val giga  : quantity -> quantity   (* 10^9   *)
    val mega  : quantity -> quantity   (* 10^6   *)
    val kilo  : quantity -> quantity   (* 10^3   *)
    val hecto : quantity -> quantity   (* 10^2   *)
    val deca  : quantity -> quantity   (* 10^1   *)
    val deci  : quantity -> quantity   (* 10^-1  *)
    val centi : quantity -> quantity   (* 10^-2  *)
    val milli : quantity -> quantity   (* 10^-3  *)
    val micro : quantity -> quantity   (* 10^-6  *)
    val nano  : quantity -> quantity   (* 10^-9  *)
    val pico  : quantity -> quantity   (* 10^-12 *)
  end

  (* Affine temperature scales. Multiplicative `convert` cannot express the
     273.15 K / 32 degF offsets, so these dedicated helpers build a temperature
     `quantity` (stored in kelvin) from a Celsius or Fahrenheit reading and
     recover the reading from a temperature. The projections raise `Dimension`
     if handed a non-temperature quantity. *)
  structure Temperature :
  sig
    val fromCelsius    : real -> quantity
    val toCelsius      : quantity -> real
    val fromFahrenheit : real -> quantity
    val toFahrenheit   : quantity -> real
  end
end
