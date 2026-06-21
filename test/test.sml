(* Tests for sml-negotiate, against RFC 9110 examples. *)

structure NegotiateTests =
struct
  open Harness

  fun run () =
    let
      val () = section "parse weighted list"
      val es = Negotiate.parse "text/html;q=0.8, application/json"
      val () = checkInt "two entries" (2, List.length es)
      val () = checkString "first value" ("text/html", #value (List.nth (es, 0)))
      val () = checkBool "first q" (true, Real.== (#q (List.nth (es, 0)), 0.8))
      val () = checkBool "second q default 1" (true, Real.== (#q (List.nth (es, 1)), 1.0))

      val () = section "Accept media negotiation (RFC 9110 q-rules)"
      (* json has implicit q=1, html has q=0.8 -> json wins *)
      val () = checkBool "prefers higher q"
                 (true, Negotiate.acceptMedia
                          { header = "text/html;q=0.8, application/json"
                          , offers = ["text/html", "application/json"] }
                        = SOME "application/json")
      val () = checkBool "type/* wildcard"
                 (true, Negotiate.acceptMedia
                          { header = "text/*"
                          , offers = ["application/json", "text/plain"] }
                        = SOME "text/plain")
      val () = checkBool "*/* matches first offer"
                 (true, Negotiate.acceptMedia
                          { header = "*/*"
                          , offers = ["application/json", "text/html"] }
                        = SOME "application/json")
      val () = checkBool "no acceptable offer"
                 (true, Negotiate.acceptMedia
                          { header = "image/png"
                          , offers = ["text/html"] } = NONE)
      val () = checkBool "q=0 excludes"
                 (true, Negotiate.acceptMedia
                          { header = "text/html;q=0, application/json;q=0.5"
                          , offers = ["text/html", "application/json"] }
                        = SOME "application/json")
      val () = checkBool "empty header -> first offer"
                 (true, Negotiate.acceptMedia
                          { header = "", offers = ["text/html", "x"] }
                        = SOME "text/html")

      val () = section "Accept-Encoding"
      val () = checkBool "prefers gzip"
                 (true, Negotiate.acceptEncoding
                          { header = "gzip, deflate;q=0.5"
                          , offers = ["deflate", "gzip"] } = SOME "gzip")
      val () = checkBool "* wildcard"
                 (true, Negotiate.acceptEncoding
                          { header = "*"
                          , offers = ["br"] } = SOME "br")
      val () = checkBool "identity fallback"
                 (true, Negotiate.acceptEncoding
                          { header = "br"   (* not offered *)
                          , offers = ["gzip", "identity"] } = SOME "identity")
      val () = checkBool "identity disabled -> NONE"
                 (true, Negotiate.acceptEncoding
                          { header = "identity;q=0"
                          , offers = ["identity"] } = NONE)

      val () = section "Accept-Language (prefix matching)"
      val () = checkBool "en matches en-US"
                 (true, Negotiate.acceptLanguage
                          { header = "en"
                          , offers = ["fr", "en-US"] } = SOME "en-US")
      val () = checkBool "exact preferred by q"
                 (true, Negotiate.acceptLanguage
                          { header = "fr;q=0.9, en;q=0.8"
                          , offers = ["en-US", "fr-CA"] } = SOME "fr-CA")
      val () = checkBool "no match"
                 (true, Negotiate.acceptLanguage
                          { header = "de"
                          , offers = ["en", "fr"] } = NONE)

      val () = section "whitespace tolerance"
      val es2 = Negotiate.parse "  text/html ;  q=0.7  ,  text/plain  "
      val () = checkBool "trims tokens" (true, #value (List.nth (es2, 0)) = "text/html")
      val () = checkBool "trims q" (true, Real.== (#q (List.nth (es2, 0)), 0.7))
    in
      ()
    end
end
