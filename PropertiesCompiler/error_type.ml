exception PropertiesError
exception NothingRecognized

let () =
  Printexc.register_printer (function
    | NothingRecognized ->
        Some
          (Printf.sprintf
             "NothingRecognized\nNothing was recognized while parsing.\n%!")
    | PropertiesError ->
        Some (Printf.sprintf "PropertiesError\nCannot analyse with PRISM\n%!")
    | _ -> None)
