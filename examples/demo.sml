(* demo.sml - parse a weighted Accept header and run the three RFC 9110
   negotiation helpers. Deterministic: q values are printed with a fixed
   digit count (never Real.toString), with negative zero normalized. *)

structure N = Negotiate

fun normZero (r : real) : real = if Real.== (r, 0.0) then 0.0 else r
fun fmtQ (r : real) : string = Real.fmt (StringCvt.FIX (SOME 1)) (normZero r)

fun showOpt NONE = "(none)"
  | showOpt (SOME s) = s

fun printEntry ({value, q} : N.entry) =
  print ("  " ^ value ^ "  (q=" ^ fmtQ q ^ ")\n")

val () = print "parse \"text/html;q=0.8, application/json, image/*;q=0.5\":\n"
val entries = N.parse "text/html;q=0.8, application/json, image/*;q=0.5"
val () = List.app printEntry entries

val () = print "\nacceptMedia: wildcard preferences vs. server offers:\n"
val mediaChoice =
  N.acceptMedia
    { header = "text/plain;q=0.5, text/*;q=0.8, */*;q=0.1"
    , offers = ["application/json", "text/html", "text/plain"] }
val () = print ("  chosen = " ^ showOpt mediaChoice ^ "\n")

val () = print "\nacceptEncoding: identity implicit unless explicitly q=0:\n"
val encChoiceA =
  N.acceptEncoding { header = "gzip;q=0.5, identity;q=0", offers = ["identity", "gzip"] }
val () = print ("  identity disabled, gzip offered -> " ^ showOpt encChoiceA ^ "\n")
val encChoiceB =
  N.acceptEncoding { header = "deflate;q=0.5, identity;q=0", offers = ["identity"] }
val () = print ("  identity disabled, only identity offered -> "
                ^ showOpt encChoiceB ^ "\n")

val () = print "\nacceptLanguage: RFC 4647 prefix matching (\"en\" ~ \"en-US\"):\n"
val langChoice =
  N.acceptLanguage { header = "en, fr;q=0.5", offers = ["fr-FR", "en-US"] }
val () = print ("  chosen = " ^ showOpt langChoice ^ "\n")
