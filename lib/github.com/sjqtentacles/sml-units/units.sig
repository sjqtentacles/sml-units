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
  end
end
