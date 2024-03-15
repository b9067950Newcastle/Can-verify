let req_belief = ref []
let errors = ref 0
let warnings = ref 0
let plan_act_error = ref false
let belief_errors = ref 0
let not_app_plan = ref [||]
let no_belief = ref false
let min_plan = ref 2
let max_plan = ref 100
let min_char = ref 2
let max_char = ref 20
let actions_type_array = ref [||]
let events_type_array = ref [||]
let beliefs_type_array = ref [||]
let type_error = ref [||]
let undeclared = ref [||]

let rec string_of_cond acc c =
  match c with
  | Syntax.Name s ->
      let acc = Array.append acc [| s |] in
      acc
  | Syntax.Mult (c1, c2) -> string_of_cond (string_of_cond acc c2) c1
  | Syntax.True ->
      let acc = Array.append acc [| "true" |] in
      acc
  | Syntax.False ->
      let acc = Array.append acc [| "false" |] in
      acc

let check_length s =
  let n = String.length s - 2 in
  if n < !min_char then (
    Printf.printf
      "Representation warning - This string %s is too short (%d characters min)\n\
       %!"
      s !min_char;
    warnings := !warnings + 1)
  else if n > !max_char then (
    Printf.printf
      "Representation warning - This string %s is too long (%d characters max)\n\
       %!"
      s !max_char;
    warnings := !warnings + 1)

let store_plan_cond event cond =
  let pre = string_of_cond [||] cond in
  let boolean = List.assoc_opt event !req_belief in
  match boolean with
  | None -> req_belief := !req_belief @ [ (event, [| pre |]) ]
  | Some p ->
      req_belief := List.remove_assoc event !req_belief;
      let pres = Array.append [| pre |] p in
      req_belief := !req_belief @ [ (event, pres) ]

let beliefs_check belief_base =
  let rec scan l =
    match l with
    | [] -> ()
    | (event, pres) :: t ->
        let rec scan_pres i =
          let boolean = ref false in
          let rec scan_array j =
            if j >= Array.length pres.(i) then !boolean
            else if
              Array.length pres.(i) = 1 && String.equal "true" pres.(i).(0)
            then true
            else if
              Array.exists (fun x -> String.equal x pres.(i).(j)) belief_base
            then (
              boolean := true;
              scan_array (j + 1))
            else false
          in
          if i >= Array.length pres then
            not_app_plan := Array.append !not_app_plan [| event |]
          else if scan_array 0 then ()
          else scan_pres (i + 1)
        in
        scan_pres 0;
        scan t
  in
  if Array.length belief_base = 0 then no_belief := true;
  scan !req_belief

let desires_check desires =
  let problem = ref false in
  let rec scan i =
    if i >= Array.length desires then !problem
    else if Array.exists (fun x -> String.equal x desires.(i)) !not_app_plan
    then (
      problem := true;
      scan (i + 1))
    else false
  in
  if Array.length desires = 0 then (
    Printf.eprintf "No desires were implemented\n%!";
    errors := !errors + 1)
  else if !no_belief then
    if scan 0 then (
      Printf.printf
        "Error - No belief were implemented and the agent cannot start with \
         the external event(s).\n\
         %!";
      errors := !errors + 1)
    else
      Printf.printf
        "WARNING - No belief were implemented, but the agent can start with \
         the external event(s).\n\
         %!"
  else if scan 0 then (
    Printf.printf
      "Error - Belief were implemented, but the agent cannot start with the \
       external event(s).\n\
       %!";
    errors := !errors + 1)
  else ()

let plans_check plans =
  let n = Array.length plans - 1 in
  if n < !min_plan then (
    Printf.printf
      "Representation warning - Only %d plan(s) have been declared on the %d \
       required\n\
       %!"
      n !min_plan;
    warnings := !warnings + 1)
  else if n > !max_plan then (
    Printf.eprintf
      "Representation warning - Too much plans have been declared (%d) (%d max)\n\
       %!"
      n !max_plan;
    warnings := !warnings + 1)

let check_length_char_array array =
  let rec scan i =
    if i >= Array.length array then ()
    else (
      check_length array.(i);
      scan (i + 1))
  in
  scan 0

let check_types () =
  let compare elt array =
    if Array.exists (fun x -> String.equal elt x) array then
      if not (Array.exists (fun x -> String.equal elt x) !type_error) then
        type_error := Array.append !type_error [| elt |]
  in
  let rec scan i array fct =
    if i >= Array.length array then ()
    else (
      fct array.(i);
      scan (i + 1) array fct)
  in
  scan 0 !beliefs_type_array (fun x ->
      compare x !events_type_array;
      compare x !actions_type_array);
  scan 0 !events_type_array (fun x -> compare x !actions_type_array);
  let n = Array.length !type_error in
  if n <> 0 then (
    Array.iter
      (fun x ->
        Printf.eprintf "Type Error - Cannot determine the type of %s\n%!" x)
      !type_error;
    Printf.eprintf "\n %d type error(s) were encountered\n%!" n;
    raise Error_type.NoStaticCheck)

let check_undeclared () =
  let n = Array.length !undeclared in
  if n <> 0 then
    Array.iter
      (fun x ->
        Printf.eprintf
          "Existence Error - %s is not declared as action or event\n%!" x;
        errors := !errors + 1)
      !undeclared

let check_once plan =
  check_undeclared ();
  check_length_char_array !events_type_array;
  check_length_char_array !actions_type_array;
  check_length_char_array !beliefs_type_array;
  plans_check plan;
  if !warnings <> 0 then
    Printf.printf "\n%d warning(s) encountered, see above for details\n\n%!"
      !warnings;
  if !errors <> 0 then (
    Printf.eprintf
      "\n%d model error(s) encountered, see above for details\n\n%!" !errors;
    raise Error_type.NoStaticCheck);
  errors := 0;
  warnings := 0

let check_all desire belief_base nb =
  Printf.printf "Checking for belief base %d ... \n%!" nb;
  beliefs_check belief_base;
  desires_check desire;
  if !warnings <> 0 then
    Printf.printf "\n%d warning(s) encountered, see above for details\n\n%!"
      !warnings;
  if !errors <> 0 then (
    Printf.eprintf
      "\n%d model error(s) encountered, see above for details\n\n%!" !errors;
    belief_errors := !belief_errors + 1)
  else Printf.printf "Checking OK\n\n%!";
  no_belief := false;
  not_app_plan := [||];
  errors := 0;
  warnings := 0
