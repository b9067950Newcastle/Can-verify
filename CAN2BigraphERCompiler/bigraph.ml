open Syntax
open Checking

let actions = ref ""
let vars = ref [||]
let plans = ref [| [] |]
let beliefs = ref []
let desires_array = ref [||]
let belief_base = ref []
let nb_bel = ref 0
let desires = ref ""
let preds = ref [||]

let store_array fct array str =
  if not (Array.exists (fun x -> String.equal x str) !array) then (
    array := Array.append !array [| str |];
    fct str)
  else fct str

let var = store_array (fun x -> x) vars
let a_type = store_array (fun _ -> ()) actions_type_array
let e_type = store_array (fun _ -> ()) events_type_array
let b_type = store_array (fun _ -> ()) beliefs_type_array
let unknown = store_array (fun _ -> "") undeclared
let event = Printf.sprintf "Event{%s}"

let empty_pb evt =
  Printf.printf "WARNING - The plan-body of a plan for %s is empty\n%!" evt;
  let str = "1" in
  str

let rec cond c =
  match c with
  | True -> "1"
  | False -> "F"
  | Name str -> Printf.sprintf "B(\"%s\")" (var str)
  | Mult (c1, c2) -> Printf.sprintf "%s | %s" (cond c1) (cond c2)

let goal sc e fc =
  Printf.sprintf "Goal.(SC.(%s) | %s | FC.(%s))" (cond sc) (event e) (cond fc)

let seq_pb pb1 pb2 = Printf.sprintf "Seq.(%s | Cons.(%s))" pb1 pb2
let conc_pb pb1 pb2 = Printf.sprintf "Conc.(L.(%s) | R.(%s))" pb1 pb2

let belief str ch =
  if String.equal str "" then Printf.sprintf "B(\"%s\")" ch
  else Printf.sprintf "%s | B(\"%s\")" str ch

let desire str ch =
  if String.equal str "" then event ch
  else Printf.sprintf "%s | Event{%s}" str ch

let transform_belief array =
  let n = Array.length array in
  let rec scan i acc =
    if i >= n then acc
    else
      match array.(i) with
      | Belief b ->
          let acc = Array.append acc [| b |] in
          scan (i + 1) acc
  in
  scan 0 [||]

let transform_desire array =
  let n = Array.length array in
  let rec scan i acc =
    if i >= n then acc
    else
      match array.(i) with
      | Desire d ->
          let acc = Array.append acc [| d |] in
          scan (i + 1) acc
  in
  scan 0 [||]

let str_build_belief array = Array.fold_left belief "" (transform_belief array)

let rec strs_build_belief list =
  match list with
  | (nb, b) :: t ->
      if List.mem_assoc nb !beliefs then raise Error_type.BeliefBasesError
      else (
        nb_bel := !nb_bel + 1;
        beliefs := !beliefs @ [ (!nb_bel, (nb, str_build_belief b)) ];
        belief_base := !belief_base @ [ (nb, transform_belief b) ];
        strs_build_belief t)
  | [] -> ()

let str_build_desire array =
  desires_array := transform_desire array;
  desires := Array.fold_left desire "" !desires_array

let set s =
  match s with
  | Del array | Add array ->
      let array = transform_belief array in
      if Array.length array = 1 && String.equal array.(0) "" then "1"
      else (
        Array.iter
          (fun x ->
            let _ = var x in
            ())
          array;
        Array.fold_left belief "" array)

let rec find_i array elt n =
  (* must start with i=1 because of how are built the array *)
  if n >= Array.length array then None
  else
    match array.(n) with
    | h :: _ -> if String.equal h elt then Some n else find_i array elt (n + 1)
    | [] -> None

let plan_array_build event c pb =
  store_plan_cond event c;
  let c = cond c in
  let plan_s = Printf.sprintf "Plan.(Pre.(%s) | PB.(%s))" c pb in
  let i = find_i !plans event 1 in
  match i with
  | Some i -> !plans.(i) <- !plans.(i) @ [ plan_s ]
  | None -> plans := Array.append !plans [| [ event; plan_s ] |]

let action_str_build act cond del add =
  actions :=
    !actions
    ^ Printf.sprintf "big %s = Act.(Pre.(%s) | Del.(%s) | Add.(%s));\n" act cond
        del add

let fold_merge str ch =
  if String.equal str "" then ch else Printf.sprintf "%s \n\t\t| %s" ch str

let make_plans () =
  let length = Array.length !plans in
  let rec scan i acc =
    if i >= length then acc
    else
      match !plans.(i) with
      | h :: t ->
          let plan_set =
            Printf.sprintf "PlanSet{%s}.(%s)" h (List.fold_left fold_merge "" t)
          in
          let acc = Array.append acc [| plan_set |] in
          scan (i + 1) acc
      | [] -> scan (i + 1) acc
  in
  let plan_sets = scan 0 [||] in
  Array.fold_left fold_merge "" plan_sets

let fold_lines str ch = Printf.sprintf "%s\n%s" ch str

let fold_var str ch =
  if String.equal str "" then Printf.sprintf "\"%s\"" ch
  else Printf.sprintf "%s, \"%s\"" str ch

let print_var () =
  let vars = Array.fold_left fold_var "" !vars in
  Printf.sprintf "string vars = { %s };" vars

let print_react_rules =
  "ctrl Check = 0;\n\
   ctrl Del = 0;\n\
   ctrl Add = 0;\n\
   atomic ctrl T = 0; # true\n\
   atomic ctrl F = 0; # false\n\n\
   ctrl Intentions = 0;\n\
   ctrl Intent = 0;\n\n\
   ctrl Desires = 0;\n\n\
   ctrl Beliefs = 0;\n\
   atomic fun ctrl B(n) = 0;\n\n\
   ctrl Reduce = 0;\n\
   atomic ctrl ReduceF = 0;\n\
   atomic ctrl GReduceF = 0;\n\n\
   ctrl Act = 0;\n\
   ctrl Pre = 0;\n\n\
   atomic ctrl Event = 1;\n\n\
   ctrl Plans = 0;\n\
   ctrl PlanSet = 1;\n\
   ctrl Plan = 0;\n\
   ctrl PB = 0;\n\n\
   # Tree\n\
   ctrl Try = 0; #OR-Like\n\
   ctrl Seq = 0; #AND-Like\n\
   ctrl Cons = 0;\n\n\
   ctrl Conc = 0;\n\
   ctrl L = 0;\n\
   ctrl R = 0;\n\n\
   # CheckToken can be discarded if we are verbose in the related rules\n\
   atomic ctrl CheckToken = 0;\n\n\
   ctrl Goal = 0;\n\
   ctrl SC = 0;\n\
   ctrl FC = 0;\n\n\n\
   # Nil for 1\n\
   atomic ctrl Nil = 0;\n\n\
   # Try for special case:\n\
   ctrl Trys = 0;\n\n\
   ## END Controls\n\n\
   # Check contains the formula to be checked against the belief base\n\
   # Check cannot be nested under the Beliefs\n\
   # as it will cause problems in the rule check_F(n) when declared as instan \
   rules.\n\
   # when there are some same formulas in two different check due to our weak \
   condition check\n\
   # Instead I nest Check under the entity (e.g. plans) for which the check is \
   needed\n\
   # and giving the final check result as child of Check\n\
   # thus no link and no CheckRes control needed\n\n\
   fun react check_T(n) =\n\
   Beliefs.(B(n) | id) || Check.(B(n) | id)\n\
   -[1]->\n\
   Beliefs.(B(n) | id) || Check.id;\n\n\
   react check_end =\n\
   Beliefs.id || Check.1\n\
   -[1]->\n\
   Beliefs.id || Check.T;\n\n\
   fun react check_F(n) =\n\
   Beliefs.id || Check.(B(n) | id)\n\
   -[1]->\n\
   Beliefs.id || Check.F\n\
   @[0] if !B(n) in param;\n\n\n\
   fun react add_notin(n) =\n\
   Beliefs.(Add.(B(n) | id) | id)\n\
   -[1]->\n\
   Beliefs.(Add.id | B(n) | id) @[0,1] if !B(n) in param;\n\n\
   fun react add_in(n) =\n\
   Beliefs.(Add.(B(n) | id) | B(n) | id)\n\
   -[1]->\n\
   Beliefs.(Add.id | B(n) | id) @[0,1];\n\n\
   react add_end =\n\
   Beliefs.(Add.1 | id)\n\
   -[1]->\n\
   Beliefs.id;\n\n\
   fun react del_in(n) =\n\
   Beliefs.(Del.(B(n) | id) | B(n) | id)\n\
   -[1]->\n\
   Beliefs.(Del.id | id);\n\n\
   fun react del_notin(n) =\n\
   Beliefs.(Del.(B(n) | id) | id)\n\
   -[1]->\n\
   Beliefs.(Del.id | id) if !B(n) in param;\n\n\
   react delete_end =\n\
   Beliefs.(Del.1 | id)\n\
   -[1]->\n\
   Beliefs.id @[0];\n\n\
   ## END Beliefs\n\n\
   ## Core actions\n\
   react act_check =\n\
   Reduce.Act.(Pre.id | Add.id | Del.id)\n\
   -[1]->\n\
   Reduce.Act.(Pre.id | Add.id | Del.id | Check.id)\n\
   @[0,1,2,0];\n\n\
   # Reduce is swallowed here\n\
   # but instan rules for belief adding and deletion operator still apply\n\
   react act_T =\n\
   Beliefs.id\n\
   || Reduce.Act.(id | Add.id | Del.id | Check.T)\n\
   -[1]->\n\
   Beliefs.(id | Add.id | Del.id)\n\
   || Nil\n\
   @[0,2,3];\n\n\
   # Reduce is swallowed here\n\
   # but ReduceF will still have to be picked up by the failure recovery rules\n\
   react act_F =\n\
   Reduce.Act.(id | Check.F)\n\
   -[1]->\n\
   ReduceF @[];\n\n\
   # Event\n\
   # Reduce is swallowed here and has to be added again for next agent step\n\
   react reduce_event =\n\
   Reduce.Event{ps}\n\
   || Plans.(PlanSet{ps}.id | id)\n\
   -[1]->\n\
   PlanSet{ps}.id\n\
   || Plans.(PlanSet{ps}.id | id)\n\
   @[0,0,1];\n\n\
   # Plan Selection\n\
   # CheckToken can be discarded if we enumerate all components of Plan\n\
   react select_plan_check =\n\
   Reduce.PlanSet{ps}.(Plan.(Pre.id | CheckToken | id) | id)\n\
   -[1]->\n\
   Reduce.PlanSet{ps}.(Plan.(Pre.id | Check.id | id) | id)\n\
   @[0,0,1,2];\n\n\
   # Reduce is swallowed here and has to be added again for next agent step\n\
   react select_plan_T =\n\
   Reduce.PlanSet{ps}.(Plan.(Pre.id | Check.T | PB.id) | id)\n\
   -[1]->\n\
   Try.(id | Cons.PlanSet{ps}.id) @[1,2];\n\n\
   # Reduce is swallowed here\n\
   # but ReduceF will still have to be picked up for the failure recovery rule\n\
   # or picked up by the intention failure rule\n\
   react select_plan_F =\n\
   Reduce.PlanSet{ps}.id\n\
   -[1]->\n\
   ReduceF | {ps} @[]\n\
   if !CheckToken in param, !Check.T in param;\n\n\
   react reset_planset =\n\
   Try.(id | Cons.PlanSet{ps}.(Plan.(Check.id | id) | id))\n\
   -[1]->\n\
   Try.(id | Cons.PlanSet{ps}.(Plan.(CheckToken | id) | id))\n\
   @[0,2,3];\n\n\
   react init_plansets =\n\
   Plans.(PlanSet{ps}.(Plan.(Pre.id | PB.id) | id) | id)\n\
   -[1]->\n\
   Plans.(PlanSet{ps}.(Plan.(CheckToken | Pre.id | PB.id) | id) | id);\n\n\
   ## Sequencing\n\
   react reduce_seq =\n\
   Reduce.Seq.(id | Cons.id)\n\
   -[1]->\n\
   Seq.(Reduce.id | Cons.id);\n\n\
   react seq_succ =\n\
   Reduce.Seq.(Nil | Cons.id)\n\
   -[1]->\n\
   Reduce.id;\n\n\
   # this rule is rather artifical and purely intermedia for better structural \
   update\n\
   react seq_fail =\n\
   Seq.(ReduceF | Cons.id)\n\
   -[1]->\n\
   ReduceF @[];\n\n\
   ## Failure Recovery\n\
   react try_seq =\n\
   Reduce.Try.(id | Cons.id)\n\
   -[1]->\n\
   Try.(Reduce.id | Cons.id);\n\n\
   react try_succ_unique =\n\
   Try.(Nil | Cons.id)\n\
   -[1]->\n\
   Trys.(Nil | Cons.id);\n\n\
   react try_succ =\n\
   Reduce.Trys.(Nil | Cons.id)\n\
   -[1]->\n\
   Nil @[];\n\n\
   react try_failure =\n\
   Try.(ReduceF | Cons.id)\n\
   -[1]->\n\
   Reduce.id;\n\n\
   # Agent-Level Steps\n\
   # all normal rules\n\
   # Constraint intention_step < {intention_step, intention_done_succ}\n\
   react a_event =\n\
   Desires.(id | Event{e})\n\
   || Intentions.id\n\
   -[1]->\n\
   Desires.id\n\
   || Intentions.(id | Intent.Event{e});\n\n\
   react intention_step =\n\
   Intent.id\n\
   -[1]->\n\
   Intent.Reduce.id;\n\n\
   react intention_done_F =\n\
   Intent.Reduce.ReduceF -[1]-> 1;\n\n\
   react intention_done_succ =\n\
   Intent.Reduce.Nil -[1]-> 1;\n\n\
   # Concurrency\n\
   # all instan rules\n\
   react conc_nil_R=\n\
   Reduce.Conc.(L.Nil | R.id)\n\
   -[1]->\n\
   Conc.(L.Nil | R.Reduce.id);\n\n\
   react conc_nil_L =\n\
   Reduce.Conc.(L.id | R.Nil)\n\
   -[1]->\n\
   Conc.(L.Reduce.id | R.Nil);\n\n\
   react conc_L =\n\
   Reduce.Conc.(L.id | id)\n\
   -[1]->\n\
   Conc.(L.Reduce.id | id);\n\n\
   react conc_R =\n\
   Reduce.Conc.(R.id | id)\n\
   -[1]->\n\
   Conc.(R.Reduce.id | id);\n\n\
   react conc_succ =\n\
   Reduce.Conc.(L.Nil | R.Nil)\n\
   -[1]->\n\
   Nil;\n\n\
   react conc_fail_L =\n\
   Conc.(L.ReduceF | id)\n\
   -[1]->\n\
   ReduceF @[];\n\n\
   react conc_fail_R =\n\
   Conc.(R.ReduceF | id)\n\
   -[1]->\n\
   ReduceF @[];\n\n\n\
   # Declarative goals #\n\
   # all instan rules\n\
   react goal_check =\n\
   Reduce.Goal.(SC.id | id | FC.id)\n\
   -[1]->\n\
   Reduce.Goal.(SC.(id | Check.id) | id | FC.(id | Check.id))\n\
   @[0,0,1,2,2]\n\
   if !Check in param;\n\n\
   react goal_suc =\n\
   Reduce.Goal.(SC.(id | Check.T) | id)\n\
   -[1]->\n\
   Nil @[];\n\n\
   react goal_fail =\n\
   Reduce.Goal.(FC.(id | Check.T) | id)\n\
   -[1]->\n\
   Act.(Pre.F | Add.1 | Del.1) @[];\n\n\
   react goal_init =\n\
   Reduce.Goal.(SC.(id | Check.F) | id | FC.(id | Check.F))\n\
   -[1]->\n\
   Goal.(SC.id | Try.(id | Cons.id) | FC.id)\n\
   @[0,1,1,2]\n\
   if !Try in param, !Trys in param;\n\n\
   react goal_reduce =\n\
   Reduce.Goal.(SC.(id | Check.F) | Try.(id | Cons.id) | FC.(id | Check.F))\n\
   -[1]->\n\
   Goal.(SC.id | Try.(Reduce.id | Cons.id) | FC.id);\n\n\
   react goal_persist_nil =\n\
   Reduce.Goal.(SC.(id | Check.F) | Trys.(Nil | Cons.id) | FC.(id | Check.F))\n\
   -[1]->\n\
   Goal.(SC.id | Try.(id | Cons.id) | FC.id)\n\
   @[0,1,1,2];\n\n\
   # the following rule is used as instan rules\n\
   # because I have the problem that when there is no plan applicable for the \
   top event in the declarative goal\n\
   # i.e. goal(SC.id | Try.(Reduce.F | Cons.id) | FC.id)\n\
   # the current order of the rules would apply try_failure (which is not what \
   we want)\n\
   # as we want goal_persist\n\
   # however in order to apply goal_persist, Reduce needs to be introduced \
   (i.e. application of rule Intention_step)\n\
   # so the best way to fix this is to create a new type for ReduceF in \
   declarative goal for the top-level failure\n\
   # the none-top-level failure can still be handled by the try_failure though \
   in the declarative goal.\n\
   react goal_root_failure_transform =\n\
   Goal.(id | Try.(ReduceF | Cons.id))\n\
   -[1]->\n\
   Goal.(id | Try.(GReduceF | Cons.id));\n\n\n\n\
   react goal_persist =\n\
   Reduce.Goal.(SC.(id | Check.F) | Try.(GReduceF | Cons.id) | FC.(id | \
   Check.F))\n\
   -[1]->\n\
   Goal.(SC.id | Try.(id | Cons.id) | FC.id)\n\
   @[0,1,1,2];\n\n\
   # this is the two type of properties we would like to check\n\
   # first to track that the intention is completed and removed, thus empty\n\
   big failure = Intent.ReduceF;\n\
   big no_failure = Intent.Nil;\n\
   big empty_intention = Intentions.1;"

let print_bigraph_sim =
  "    init model;\n\
  \   rules = [\n\
  \   # change to Trys control\n\
  \   (try_succ_unique),\n\n\
  \   # add CheckToken for all initial user-specified plans\n\
  \   (init_plansets),\n\n\
  \   (goal_root_failure_transform),\n\n\
  \   # Plan selection token housekeeping\n\
  \   (reset_planset),\n\n\
  \   # Atomic set ops\n\
  \   ( check_T(vars),\n\
  \   check_end,\n\
  \   check_F(vars),\n\
  \   add_notin(vars),\n\
  \   add_in(vars),\n\
  \   add_end,\n\
  \   del_in(vars),\n\
  \   del_notin(vars),\n\
  \   delete_end\n\
  \   ),\n\n\
  \   # actually reduce the programs\n\
  \   ( reduce_event,\n\
  \   act_check,\n\
  \   select_plan_check,\n\
  \   goal_check\n\
  \   ),\n\n\
  \   # the follow-up of the above actual reduction of the programs\n\
  \   ( act_T,\n\
  \   act_F,\n\
  \   select_plan_F,\n\
  \   goal_suc,\n\
  \   goal_fail,\n\
  \   goal_init\n\
  \   ),\n\n\
  \   # special cases of rules specifying how the AND/OR tree is explored    \
   excluding those having ReduceF\n\
  \   (conc_succ, goal_persist_nil),\n\n\
  \   # conc_succ has to have a higher priority than both conc_nil_L and \
   conc_nil_R\n\
  \   (conc_nil_L, conc_nil_R),\n\n\
  \   (seq_succ),\n\
  \   (try_succ),\n\n\
  \   # special cases of rules to specify how the AND/OR tree should be \
   explored    for handling ReduceF\n\
  \   (goal_persist, conc_fail_L, conc_fail_R),\n\
  \   (seq_fail),\n\
  \   (try_failure),\n\n\
  \   # non-special cases of rules to specify how the AND/OR tree should be    \
   explored\n\
  \   # rule conc_L and conc_R need to be the normal rules if concurrency is \
   ever    used\n\
  \   (goal_reduce),\n\
  \   (reduce_seq),\n\
  \   (try_seq),\n\n\
  \   # special cases of agent level operation\n\
  \   (intention_done_succ, intention_done_F),\n\n\n\
  \   # non-determinism of rules which have to be a normal rule to allow    \
   branching\n\n\
  \   {select_plan_T, conc_L, conc_R},\n\n\n\
  \   # non-special cases of agent level operation\n\
  \   {a_event, intention_step}\n\
  \   ];"

let fold_preds_name str ch =
  if String.equal str "" then ch else Printf.sprintf "%s_%s" str ch

let make_predicates () =
  let rec scan i names decls =
    if i >= Array.length !preds then (names, decls)
    else
      let pred_name = Array.fold_left fold_preds_name "" !preds.(i) in
      let names =
        Array.append names [| Printf.sprintf "predicate_%s" pred_name |]
      in
      let decl =
        Printf.sprintf "Beliefs.(%s | id)"
          (Array.fold_left belief "" !preds.(i))
      in
      let decl = Printf.sprintf "big predicate_%s = %s;\n" pred_name decl in
      let decls = Array.append decls [| decl |] in
      scan (i + 1) names decls
  in
  let names, decls = scan 0 [||] [||] in
  let names =
    Array.append names [| "failure"; "no_failure"; "empty_intention" |]
  in
  (names, decls)

let fold_preds str ch =
  if String.equal str "" then ch else Printf.sprintf "%s, %s" str ch

let fold_decl str ch =
  if String.equal str "" then ch else Printf.sprintf "%s %s" str ch

let print_preds preds =
  Printf.sprintf "\tpreds = {%s};\nend" (Array.fold_left fold_preds "" preds)

let print_code actions beliefs desires plans =
  let big =
    Printf.sprintf "%s\nbig model = %s\n || %s\n || Intentions.1 \n || %s;"
      actions beliefs desires plans
  in
  let pred_names, pred_decls = make_predicates () in
  Printf.sprintf "%s\n\n%s\n%s\n\n%s" print_react_rules
    (Array.fold_left fold_decl "" pred_decls)
    big
    (Printf.sprintf "begin pbrs\n\t%s\n%s\n%s" (print_var ()) print_bigraph_sim
       (print_preds pred_names))

let rec make_code acc i desires_str_l plans_str_l =
  if i > !nb_bel then
    if !belief_errors <> 0 then raise Error_type.NoStaticCheck else acc
  else
    let nb, belief = List.assoc i !beliefs in
    let beliefs_str_l = Printf.sprintf "Beliefs.(%s)" belief in
    check_all !desires_array (List.assoc nb !belief_base) nb;
    let code = print_code !actions beliefs_str_l desires_str_l plans_str_l in
    let acc = acc @ [ (nb, code) ] in
    make_code acc (i + 1) desires_str_l plans_str_l

let make_program () =
  let plans_str_l = Printf.sprintf "Plans.(\n\t\t%s\n\t)" (make_plans ()) in
  let desires_str_l = Printf.sprintf "Desires.(%s)" !desires in
  check_once !plans;
  make_code [] 1 desires_str_l plans_str_l

let output_big file prog =
  let ch = open_out file in
  Printf.fprintf ch "%s" prog;
  close_out ch
