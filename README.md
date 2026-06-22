# sml-units

[![CI](https://github.com/sjqtentacles/sml-units/actions/workflows/ci.yml/badge.svg)](https://github.com/sjqtentacles/sml-units/actions/workflows/ci.yml)

Runtime dimensional analysis for Standard ML.

`sml-units` lets you attach physical dimensions to numbers and have the
arithmetic checked at runtime. Adding a length to a time raises an exception
instead of silently producing a meaningless number; multiplying a force by a
distance produces an energy with the correct dimension automatically.

A `quantity` is a `real` magnitude (always stored in SI base units) tagged
with a `Dim.t`, the dimension expressed as a 7-tuple of integer exponents over
the SI base dimensions:

```
(mass, length, time, current, temperature, amount, luminosity)
```

- `+` and `-` require matching dimensions and raise `Units.Dimension` otherwise.
- `*` and `/` add and subtract the exponents.
- `pow` multiplies them.

## Portability

Pure Standard ML using only the Basis library. Verified on:

- **MLton**
- **Poly/ML**

The sources are shared via an [ML Basis](http://mlton.org/MLBasis) (`.mlb`)
file. MLton consumes it natively; for Poly/ML the test target simply `use`s
the sources in order.

## Building and testing

```sh
make test        # build + run the suite under MLton (default)
make test-poly   # run the suite under Poly/ML
make all-tests   # run under both
make clean
```

## Installing with smlpkg

`sml-units` follows the conventions of the
[`smlpkg`](https://github.com/diku-dk/smlpkg) package manager. There is no
registry or account to sign up for -- packages are referenced directly by
their git URL. In your own project's directory:

```sh
smlpkg add github.com/sjqtentacles/sml-units
smlpkg sync
```

This downloads the library into `lib/github.com/sjqtentacles/sml-units/`.
Reference it from your own `.mlb` with a relative path to `units.mlb`:

```
lib/github.com/sjqtentacles/sml-units/units.mlb
```

For Poly/ML, `use` the sources in order:

```sml
use "lib/github.com/sjqtentacles/sml-units/units.sig";
use "lib/github.com/sjqtentacles/sml-units/units.sml";
```

## Usage

```sml
structure U  = Units
structure Un = Units.Units   (* the named-unit catalogue *)

infix 6 ++ -- ; infix 7 ** //
val op ++ = U.+  and op -- = U.-
val op ** = U.*  and op // = U./

(* F = m a:  2 kg * 9.81 m/s^2 *)
val accel = U.scale (9.81, Un.metre) // (Un.second ** Un.second)
val force = U.scale (2.0, Un.kilogram) ** accel

val () = print (U.toString force ^ "\n")          (* magnitude + "kg m s^-2" *)
val () = print (U.Dim.toString (U.dim force) ^ "\n")

(* This raises Units.Dimension: *)
val bad = U.scale (3.0, Un.metre) ++ U.scale (1.0, Un.second)
```

The named-unit catalogue (`Units.Units`) provides the seven SI base units
(`kilogram`, `metre`, `second`, `ampere`, `kelvin`, `mole`, `candela`) plus
common derived units (`newton`, `joule`, `watt`, `pascal`, `hertz`,
`coulomb`, `volt`) and a couple of non-SI time units (`minute`, `hour`), each
a quantity expressed in SI base units.

## Conversion, prefixes and temperatures

Since a quantity is always stored in SI base units, a *unit* is just a
quantity whose magnitude is its size in SI base units. `convert (q, unit)`
re-expresses `q` as a plain number of those units, raising `Units.Dimension`
on a dimension mismatch; `convertOpt` returns `NONE` instead.

```sml
structure U  = Units
structure Un = Units.Units

val km = U.Prefix.kilo Un.metre              (* 1 km = 1000 m *)
U.convert (km, Un.metre)                      (* 1000.0 *)
U.convert (Un.hour, Un.second)                (* 3600.0 *)
U.convertOpt (Un.metre, Un.second)            (* NONE: m and s differ *)
```

`Prefix` applies the SI decimal prefixes (`tera` … `pico`, including `kilo`,
`milli`, `micro`, `nano`) to any quantity, scaling the magnitude and keeping
the dimension. Conversion is multiplicative, so affine temperature scales get
dedicated helpers in `Temperature`:

```sml
U.Temperature.fromCelsius 0.0                 (* 273.15 K *)
U.Temperature.toFahrenheit
  (U.Temperature.fromCelsius 100.0)           (* 212.0 *)
```

## Project layout

```
sml.pkg                                          smlpkg manifest
Makefile                                         build + test
lib/github.com/sjqtentacles/sml-units/
  units.sig                                      the UNITS signature
  units.sml                                      the implementation
  units.mlb                                      MLB for consumers
test/
  test.mlb                                       test basis (MLton)
  test.sml                                       assertion suite
.github/workflows/ci.yml                         CI (MLton + Poly/ML)
```

## License

MIT. See [LICENSE](LICENSE).
