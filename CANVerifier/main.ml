let static = ref false
let dynamic = ref false
let bigfile = ref false
let prop = ref []
let states = ref 4000
let prop_file = ref ""

let main can_file =
  Printf.printf "\nCAN-Verify\n==========\n\n%!";
  if !dynamic then static := true;
  if !bigfile then static := true;
  if !static then (
    Printf.printf "Static check in progress ...\n%!";
    let ast_can = CAN2BigraphERCompiler.Compiler.parse_can can_file in
    CAN2BigraphERCompiler.Precompile.c_program ast_can;
    CAN2BigraphERCompiler.Checking.check_types ();
    Printf.printf "Static check completed\n\n%!";
    (if not (String.equal "" !prop_file) then
     let ast_prop = PropertiesCompiler.Compiler.parse_prop !prop_file in
     prop := PropertiesCompiler.Compile.c_properties ast_prop);
    CAN2BigraphERCompiler.Bigraph.preds := !PropertiesCompiler.Compile.preds;
    let big = CAN2BigraphERCompiler.Compile.c_program ast_can in
    if !dynamic then
      let rec inner_main l =
        match l with
        | (nb, h) :: t ->
            Printf.printf
              "\nDynamic check in progress for belief base %d...\n%!" nb;
            let filename = Filename.remove_extension can_file in
            let filename = filename ^ "_" ^ string_of_int nb in
            CAN2BigraphERCompiler.Bigraph.output_big (filename ^ ".big") h;
            let _ =
              Sys.command
                (Printf.sprintf
                   "bigrapher full -M %d -p %s.tra -l %s.csl --solver=MCARD \
                    %s.big"
                   !states filename filename filename)
            in
            PropertiesCompiler.Io.add_prop (filename ^ ".csl") !prop;
            let _ =
              Sys.command
                (Printf.sprintf "prism -importtrans %s.tra %s.csl" filename
                   filename)
            in
            let _ =
              Sys.command
                (Printf.sprintf "rm -f %s.tra %s.csl" filename filename)
            in
            (if not !bigfile then
             let _ = Sys.command (Printf.sprintf "rm -f %s.big" filename) in
             ());
            Printf.printf "Dynamic check completed for belief base %d\n%!" nb;
            inner_main t
        | [] -> Printf.printf "End of program\n%!"
      in
      inner_main big
    else if !bigfile then
      let rec func l =
        match l with
        | (nb, h) :: t ->
            let filename = Filename.remove_extension can_file in
            CAN2BigraphERCompiler.Bigraph.output_big
              (filename ^ "_" ^ string_of_int nb ^ ".big")
              h;
            func t
        | [] -> ()
      in
      func big)

let () =
  let args =
    [
      ("-static", Arg.Set static, " Do a static check on the CAN syntax");
      ( "-dynamic",
        Arg.Set dynamic,
        " Verify the CAN model with BigraphER and PRISM" );
      ("-p", Arg.Set_string prop_file, " Property file for PRISM");
      ("-Ms", Arg.Set_int states, " Maximum number of states allowed");
      ( "-mp",
        Arg.Set_int CAN2BigraphERCompiler.Checking.min_plan,
        " Minimum number of plans required" );
      ( "-Mp",
        Arg.Set_int CAN2BigraphERCompiler.Checking.max_plan,
        " Maximum number of plans allowed" );
      ( "-mc",
        Arg.Set_int CAN2BigraphERCompiler.Checking.min_char,
        " Minimum number of characters required" );
      ( "-Mc",
        Arg.Set_int CAN2BigraphERCompiler.Checking.max_char,
        " Maximum number of characters allowed" );
      ("-big", Arg.Set bigfile, " Export the CAN model to .big file");
    ]
    |> Arg.align
  in
  let usage =
    Printf.sprintf "%s [options] [-p prop.txt] file.can" Sys.argv.(0)
  in
  Arg.parse args main usage
