exception NoStaticCheck
exception NothingRecognized
exception CANModelError
exception BeliefBasesError

let () =
  Printexc.register_printer (function
    | NoStaticCheck ->
        Some (Printf.sprintf "NoStaticCheck\nStatic check failed%!")
    | NothingRecognized ->
        Some
          (Printf.sprintf
             "NothingRecognized\n\
              Nothing was recognized while parsing.\n\
              Static check failed%!")
    | BeliefBasesError ->
        Some
          (Printf.sprintf
             "BeliefBasesError\n\
              Error while declaring the number of beliefs bases.\n\
              Static check failed%!")
    | _ -> None)
