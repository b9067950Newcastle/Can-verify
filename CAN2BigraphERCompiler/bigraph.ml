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
let event = Printf.sprintf "Event{%s}.Identifier.E(1)"

let empty_pb evt =
  Printf.printf "WARNING - The plan-body of a plan for %s is empty\n%!" evt;
  let str = "1" in
  str

let rec cond c =
  match c with
  | True -> "1"
  | False -> "F"
  | Name str -> Printf.sprintf "B(\"%s\").1" (var str)
  | Mult (c1, c2) -> Printf.sprintf "%s | %s" (cond c1) (cond c2)

let goal sc e fc =
  Printf.sprintf "Goal.(SC.(%s) | %s | FC.(%s))" (cond sc) (event e) (cond fc)

let seq_pb pb1 pb2 = Printf.sprintf "Seq.(%s | Cons.(%s))" pb1 pb2
let conc_pb pb1 pb2 = Printf.sprintf "Conc.(L.(%s) | R.(%s))" pb1 pb2

let belief str ch posv negv=
  if String.equal posv "" then 
  	if String.equal str "" then Printf.sprintf "%s" ch
  	else Printf.sprintf "%s | %s" str ch
  else
    let posv_int = int_of_string posv in
    let negv_int = int_of_string negv in
    if String.equal str "" then Printf.sprintf "B(\"%s\").(Pw(%d) | Nw(%d))" ch posv_int negv_int
    else Printf.sprintf "%s | B(\"%s\").(Pw(%d) | Nw(%d))" str ch posv_int negv_int


let desire str ch d_n =
  if String.equal str "" then event ch
  else Printf.sprintf "%s | Event{%s}.Identifier.E(%s)" str ch d_n

let transform_belief array =
  let n = Array.length array in
  let rec scan i acc =
    if i >= n then acc
    else
      match array.(i) with
      | Belief (b, posv, negv) ->
      		let new_belief_str = belief "" b posv negv in
          let acc = Array.append acc [| new_belief_str |] in
          scan (i + 1) acc
  in
  scan 0 [||]

let transform_desire array =
  let n = Array.length array in
  let rec scan i acc =
    if i >= n then acc
    else
      match array.(i) with
      | Desire (d, d_n) ->
          let new_desire_str = desire "" d d_n in
          let acc = Array.append acc [| new_desire_str |] in
          scan (i + 1) acc
  in
  scan 0 [||]

let str_build_belief array =
  Array.fold_left (fun acc el -> if acc = "" then el else acc ^ " | " ^ el) "" (transform_belief array)

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
  desires := Array.fold_left (fun acc el -> if acc = "" then el else acc ^ " | " ^ el) "" !desires_array

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
        Array.fold_left (fun acc el -> if acc = "" then el else acc ^ " | " ^ el) "" array)

let rec find_i array elt n =
  (* must start with i=1 because of how are built the array *)
  if n >= Array.length array then None
  else
    match array.(n) with
    | h :: _ -> if String.equal h elt then Some n else find_i array elt (n + 1)
    | [] -> None

let plan_array_build plan_num event c pb =
  store_plan_cond event c;
  let c = cond c in
  let plan_s = Printf.sprintf "Plan.(Identifier.P(%s) | Pre.(%s) | PB.(%s))" plan_num c pb in
  let i = find_i !plans event 1 in
  match i with
  | Some i -> !plans.(i) <- !plans.(i) @ [ plan_s ]
  | None -> plans := Array.append !plans [| [ event; plan_s ] |]

let action_str_build act cond del ac_posv ac_posv_eff add ac_negv ac_negv_eff =
  actions :=
    !actions
    ^ Printf.sprintf "big %s = Act.(Pre.(%s) | Effect.(Revise.B(\"%s\").Pw(%s) | EffectWeight(%s)) | Effect.(Revise.B(\"%s\").Nw(%s) | EffectWeight(%s)));\n" act cond
        del ac_posv ac_posv_eff add ac_negv ac_negv_eff

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
  "#
# only agent-level rules are norm rules
# the rest of rules are instantenous rules
# the idea is that when an Reduce is added, 
# after the applications of all instantenous rules in the background, the next step is produced.  


# this verision has epistemic belief reasoning. 
# so a MDP where each state is encoded to model uncertain information. 

## CONTROLS

ctrl Check = 0;
ctrl Del = 0;
ctrl Add = 0;
atomic ctrl T = 0; # true
atomic ctrl F = 0; # false

ctrl Intentions = 0;
ctrl Intent = 0;

ctrl Desires = 0;

ctrl Beliefs = 0;

# now the belief literals have to be nested with the weight
fun ctrl B(n) = 0;

ctrl Reduce = 0;
atomic ctrl ReduceF = 0;
atomic ctrl GReduceF = 0;

ctrl Act = 0;
ctrl Pre = 0;

ctrl Event = 1;

ctrl Plans = 0;
ctrl PlanSet = 1;
ctrl Plan = 0;
ctrl PB = 0;

# Tree
ctrl Try = 0; #OR-Like
ctrl Seq = 0; #AND-Like
ctrl Cons = 0;

ctrl Conc = 0;
ctrl L = 0;
ctrl R = 0;

# CheckToken can be discarded if we are verbose in the related rules
atomic ctrl CheckToken = 0;

ctrl Goal = 0;
ctrl SC = 0;
ctrl FC = 0;


# Nil for 1 
atomic ctrl Nil = 0;

# Try for special case:
ctrl Trys = 0;


# controls for the identifier of events and plans
ctrl Identifier = 0;
atomic fun ctrl E(n) = 0;
atomic fun ctrl P(n) = 0;


# controls for epistemic beliefs modelling

atomic fun ctrl Pw(pw) = 0;
atomic fun ctrl Nw(nw) = 0;

# now the effects of actions are to revise the epistemic beliefs
ctrl Revise = 0;
# the input of the epistemic state has the following data structure

# stochastic actions
ctrl Effect = 0;
atomic fun ctrl EffectWeight(n) = 0;



## END Controls

# Check contains the formula to be checked against the belief base
# Check cannot be nested under the Beliefs 
# as it will cause problems in the rule check_F(n) when declared as instan rules.
# when there are some same formulas in two different check due to our weak condition check
# Instead I nest Check under the entity (e.g. plans) for which the check is needed
# and giving the final check result as child of Check
# thus no link and no CheckRes control needed



# the current entaiment is done to check if each literal is held true
# if not, then False is given
# we do not support disjunction for now


#   int pw0 = [1:1:10];
fun react truth_atom_T_0(atom,pw0) =
       B(atom).(Pw(pw0) | Nw(0) | id)
    -[1]-> 
       B(atom).(Pw(pw0) | Nw(0) | T | id)
       if !T in param;

#   int pw1 = [2:1:10];
fun react truth_atom_T_1(atom,pw1) =
       B(atom).(Pw(pw1) | Nw(1) | id)
    -[1]-> 
       B(atom).(Pw(pw1) | Nw(1) | T | id)
       if !T in param;

#   int pw2 = [3:1:10];
fun react truth_atom_T_2(atom,pw2) =
       B(atom).(Pw(pw2) | Nw(2) | id)
    -[1]-> 
       B(atom).(Pw(pw2) | Nw(2) | T | id)
       if !T in param;

#   int pw3= [4:1:10];
fun react truth_atom_T_3(atom,pw3) =
       B(atom).(Pw(pw3) | Nw(3) | id)
    -[1]-> 
       B(atom).(Pw(pw3) | Nw(3) | T | id)
       if !T in param;

#   int pw4= [5:1:10];
fun react truth_atom_T_4(atom,pw4) =
       B(atom).(Pw(pw4) | Nw(4) | id)
    -[1]-> 
       B(atom).(Pw(pw4) | Nw(4) | T | id)
       if !T in param;

#   int pw5= [6:1:10];
fun react truth_atom_T_5(atom,pw5) =
       B(atom).(Pw(pw5) | Nw(5) | id)
    -[1]-> 
       B(atom).(Pw(pw5) | Nw(5) | T | id)
       if !T in param;

#   int pw6= [7:1:10];
fun react truth_atom_T_6(atom,pw6) =
       B(atom).(Pw(pw6) | Nw(6) | id)
    -[1]-> 
       B(atom).(Pw(pw6) | Nw(6) | T | id)
       if !T in param;

#   int pw7= [8:1:10];
fun react truth_atom_T_7(atom,pw7) =
       B(atom).(Pw(pw7) | Nw(7) | id)
    -[1]-> 
       B(atom).(Pw(pw7) | Nw(7) | T | id)
       if !T in param;

#   int pw8= [9:1:10];
fun react truth_atom_T_8(atom,pw8) =
       B(atom).(Pw(pw8) | Nw(8) | id)
    -[1]-> 
       B(atom).(Pw(pw8) | Nw(8) | T | id)
       if !T in param;

#   int pw9 = 10;
fun react truth_atom_T_9(atom,pw9) =
       B(atom).(Pw(pw9) | Nw(9) | id)
    -[1]-> 
       B(atom).(Pw(pw9) | Nw(9) | T | id)
       if !T in param;





#   int nw0 = [0:1:10];
fun react false_atom_T_0(atom,nw0) =
       B(atom).(Pw(0) | Nw(nw0) | T | id)
    -[1]-> 
       B(atom).(Pw(0) | Nw(nw0) | id);

#   int nw1 = [1:1:10];
fun react false_atom_T_1(atom,nw1) =
       B(atom).(Pw(1) | Nw(nw1) | T | id)
    -[1]-> 
       B(atom).(Pw(1) | Nw(nw1) | id);

#   int nw2 = [2:1:10];
fun react false_atom_T_2(atom,nw2) =
       B(atom).(Pw(2) | Nw(nw2) | T | id)
    -[1]-> 
       B(atom).(Pw(2) | Nw(nw2) | id);

#   int nw3= [3:1:10];
fun react false_atom_T_3(atom,nw3) =
       B(atom).(Pw(3) | Nw(nw3) | T | id)
    -[1]-> 
       B(atom).(Pw(3) | Nw(nw3) | id);

#   int nw4= [4:1:10];
fun react false_atom_T_4(atom,nw4) =
       B(atom).(Pw(4) | Nw(nw4) | T | id)
    -[1]-> 
       B(atom).(Pw(4) | Nw(nw4) | id);

#   int nw5= [5:1:10];
fun react false_atom_T_5(atom,nw5) =
       B(atom).(Pw(5) | Nw(nw5) | T | id)
    -[1]-> 
       B(atom).(Pw(5) | Nw(nw5) | id);

#   int nw6= [6:1:10];
fun react false_atom_T_6(atom,nw6) =
       B(atom).(Pw(6) | Nw(nw6) | T | id)
    -[1]-> 
       B(atom).(Pw(6) | Nw(nw6) | id);

#   int nw7= [7:1:10];
fun react false_atom_T_7(atom,nw7) =
       B(atom).(Pw(7) | Nw(nw7) | T | id)
    -[1]-> 
       B(atom).(Pw(7) | Nw(nw7) | id);

#   int pw8= [8:1:10];
fun react false_atom_T_8(atom,nw8) =
       B(atom).(Pw(8) | Nw(nw8) | T | id)
    -[1]-> 
       B(atom).(Pw(8) | Nw(nw8) | id);

#   int pw9 = [9:1:10];
fun react false_atom_T_9(atom,nw9) =
       B(atom).(Pw(9) | Nw(nw9) | T | id)
    -[1]-> 
       B(atom).(Pw(9) | Nw(nw9) | id);



#   int pw0 = [1:1:10];
fun react comparator_atoms_T_0(atom,pw0) =
       B(atom).(Pw(pw0) | Nw(0) | id)
    || Check.(B(atom).1 | id)
    -[1]-> 
       B(atom).(Pw(pw0) | Nw(0) | id)
    || Check.id;

#   int pw1 = [2:1:10];
fun react comparator_atoms_T_1(atom,pw1) =
       B(atom).(Pw(pw1) | Nw(1) | id)
    || Check.(B(atom).1 | id)
    -[1]-> 
       B(atom).(Pw(pw1) | Nw(1) | id)
    || Check.id;

#   int pw2 = [3:1:10];
fun react comparator_atoms_T_2(atom,pw2) =
       B(atom).(Pw(pw2) | Nw(2) | id)
    || Check.(B(atom).1 | id)
    -[1]-> 
       B(atom).(Pw(pw2) | Nw(2) | id)
    || Check.id;

#   int pw3= [4:1:10];
fun react comparator_atoms_T_3(atom,pw3) =
       B(atom).(Pw(pw3) | Nw(3) | id)
    || Check.(B(atom).1 | id)
    -[1]-> 
       B(atom).(Pw(pw3) | Nw(3) | id)
    || Check.id;

#   int pw4= [5:1:10];
fun react comparator_atoms_T_4(atom,pw4) =
       B(atom).(Pw(pw4) | Nw(4) | id)
    || Check.(B(atom).1 | id)
    -[1]-> 
       B(atom).(Pw(pw4) | Nw(4) | id)
    || Check.id;

#   int pw5= [6:1:10];
fun react comparator_atoms_T_5(atom,pw5) =
       B(atom).(Pw(pw5) | Nw(5) | id)
    || Check.(B(atom).1 | id)
    -[1]-> 
       B(atom).(Pw(pw5) | Nw(5) | id)
    || Check.id;

#   int pw6= [7:1:10];
fun react comparator_atoms_T_6(atom,pw6) =
       B(atom).(Pw(pw6) | Nw(6) | id)
    || Check.(B(atom).1 | id)
    -[1]-> 
       B(atom).(Pw(pw6) | Nw(6) | id)
    || Check.id;

#   int pw7= [8:1:10];
fun react comparator_atoms_T_7(atom,pw7) =
       B(atom).(Pw(pw7) | Nw(7) | id)
    || Check.(B(atom).1 | id)
    -[1]-> 
       B(atom).(Pw(pw7) | Nw(7) | id)
    || Check.id;

#   int pw8= [9:1:10];
fun react comparator_atoms_T_8(atom,pw8) =
       B(atom).(Pw(pw8) | Nw(8) | id)
    || Check.(B(atom).1 | id)
    -[1]-> 
       B(atom).(Pw(pw8) | Nw(8) | id)
    || Check.id;

#   int pw9 = 10;
fun react comparator_atoms_T_9(atom,pw9) =
       B(atom).(Pw(pw9) | Nw(9) | id)
    || Check.(B(atom).1 | id)
    -[1]-> 
       B(atom).(Pw(pw9) | Nw(9) | id)
    || Check.id;


react check_end_T =
    Beliefs.id || Check.1
    -[1]->
    Beliefs.id || Check.T;

react check_end_F =
    Beliefs.id || Check.id
    -[1]->
    Beliefs.id || Check.F
    @[0] if !T in param, !F in param;


# rules for revising compact epistemic belief base

fun react revise_pw(atom,pw1,pw2) =
    Beliefs.(B(atom).(Pw(pw1) | id) | Revise.(B(atom).Pw(pw2) | id) | id)
    -[1]->
    Beliefs.(B(atom).(Pw(pw1+pw2) | id) | Revise.id | id);

fun react revise_nw(atom,nw1,nw2) =
    Beliefs.(B(atom).(Nw(nw1) | id) | Revise.(B(atom).Nw(nw2) | id) | id)
    -[1]->
    Beliefs.(B(atom).(Nw(nw1+nw2) | id) | Revise.id | id);

react revise_end =
    Beliefs.(Revise.1 | id)
    -[1]->
    Beliefs.id;


## END Beliefs

## Core actions
react act_check =
  Reduce.Act.(Pre.id | id)
  -[1]->
  Reduce.Act.(Pre.id | id | Check.id)
  @[0,1,0] if !Check in param;

# action execution is extended to model the stochastic effects of action
fun react act_T(n) =
     Beliefs.id
  || Reduce.Act.(id | Effect.(Revise.id | EffectWeight(n)) | Check.T)
  -[n]->
     Beliefs.(id | Revise.id)
  || Nil
  @[0,2];


# Reduce is swallowed here
# but ReduceF will still have to be picked up by the failure recovery rules 
react act_F =
  Reduce.Act.(id | Check.F)
  -[1]->
  ReduceF @[];

# Event
# Reduce is swallowed here and has to be added again for next agent step
react reduce_event =
    Reduce.Event{ps}.1
 || Plans.(PlanSet{ps}.id | id)
 -[1]->
    PlanSet{ps}.id
 || Plans.(PlanSet{ps}.id | id)
 @[0,0,1];

# Plan Selection
# CheckToken can be discarded if we enumerate all components of Plan
react select_plan_check =
    Reduce.PlanSet{ps}.(Plan.(Pre.id | CheckToken | id) | id)
 -[1]->
    Reduce.PlanSet{ps}.(Plan.(Pre.id | Check.id | id) | id)
  @[0,0,1,2];

# Reduce is swallowed here and has to be added again for next agent step
react select_plan_T_1 =
    Reduce.PlanSet{ps}.(Plan.(Pre.id | Check.T | PB.id | Identifier.P(1)) | id)
  -[1]->
    Try.(id | Cons.PlanSet{ps}.id) @[1,2];
react select_plan_T_2 =
    Reduce.PlanSet{ps}.(Plan.(Pre.id | Check.T | PB.id | Identifier.P(2)) | id)
  -[1]->
    Try.(id | Cons.PlanSet{ps}.id) @[1,2];
react select_plan_T_3 =
    Reduce.PlanSet{ps}.(Plan.(Pre.id | Check.T | PB.id | Identifier.P(3)) | id)
  -[1]->
    Try.(id | Cons.PlanSet{ps}.id) @[1,2];
react select_plan_T_4 =
    Reduce.PlanSet{ps}.(Plan.(Pre.id | Check.T | PB.id | Identifier.P(4)) | id)
  -[1]->
    Try.(id | Cons.PlanSet{ps}.id) @[1,2];
react select_plan_T_5 =
    Reduce.PlanSet{ps}.(Plan.(Pre.id | Check.T | PB.id | Identifier.P(5)) | id)
  -[1]->
    Try.(id | Cons.PlanSet{ps}.id) @[1,2];
react select_plan_T_6 =
    Reduce.PlanSet{ps}.(Plan.(Pre.id | Check.T | PB.id | Identifier.P(6)) | id)
  -[1]->
    Try.(id | Cons.PlanSet{ps}.id) @[1,2];
react select_plan_T_7 =
    Reduce.PlanSet{ps}.(Plan.(Pre.id | Check.T | PB.id | Identifier.P(7)) | id)
  -[1]->
    Try.(id | Cons.PlanSet{ps}.id) @[1,2];
react select_plan_T_8 =
    Reduce.PlanSet{ps}.(Plan.(Pre.id | Check.T | PB.id | Identifier.P(8)) | id)
  -[1]->
    Try.(id | Cons.PlanSet{ps}.id) @[1,2];
react select_plan_T_9 =
    Reduce.PlanSet{ps}.(Plan.(Pre.id | Check.T | PB.id | Identifier.P(9)) | id)
  -[1]->
    Try.(id | Cons.PlanSet{ps}.id) @[1,2];
react select_plan_T_10 =
    Reduce.PlanSet{ps}.(Plan.(Pre.id | Check.T | PB.id | Identifier.P(10)) | id)
  -[1]->
    Try.(id | Cons.PlanSet{ps}.id) @[1,2];

# Reduce is swallowed here
# but ReduceF will still have to be picked up for the failure recovery rule
# or picked up by the intention failure rule
react select_plan_F =
    Reduce.PlanSet{ps}.id
  -[1]->
    ReduceF | {ps} @[]
    if !CheckToken in param, !Check.T in param;

react reset_planset =
  Try.(id | Cons.PlanSet{ps}.(Plan.(Check.id | id) | id))
  -[1]->
  Try.(id | Cons.PlanSet{ps}.(Plan.(CheckToken | id) | id))
  @[0,2,3];

# this rule needs to be revised as Plan has one more nested entities called identifier
react init_plansets =
  Plans.(PlanSet{ps}.(Plan.(Pre.id | PB.id | Identifier.id) | id) | id)
  -[1]->
  Plans.(PlanSet{ps}.(Plan.(CheckToken | Pre.id | PB.id | Identifier.id) | id) | id);

## Sequencing
react reduce_seq =
  Reduce.Seq.(id | Cons.id)
  -[1]->
  Seq.(Reduce.id | Cons.id);

react seq_succ =
  Reduce.Seq.(Nil | Cons.id)
  -[1]->
  Reduce.id;

# this rule is rather artifical and purely intermedia for better structural update
react seq_fail =
  Seq.(ReduceF | Cons.id)
  -[1]->
  ReduceF @[];

## Failure Recovery
react try_seq =
  Reduce.Try.(id | Cons.id)
  -[1]->
  Try.(Reduce.id | Cons.id);

react try_succ_unique =
  Try.(Nil | Cons.id)
  -[1]->
  Trys.(Nil | Cons.id);

react try_succ =
  Reduce.Trys.(Nil | Cons.id)
  -[1]->
  Nil @[];

react try_failure =
  Try.(ReduceF | Cons.id)
  -[1]->
  Reduce.id;



# Concurrency
# all instan rules
react conc_nil_R=
  Reduce.Conc.(L.Nil | R.id)
  -[1]->
  Conc.(L.Nil | R.Reduce.id);

react conc_nil_L =
  Reduce.Conc.(L.id | R.Nil)
  -[1]->
  Conc.(L.Reduce.id | R.Nil);

react conc_L =
  Reduce.Conc.(L.id | id)
  -[1]->
  Conc.(L.Reduce.id | id);

react conc_R =
  Reduce.Conc.(R.id | id)
  -[1]->
  Conc.(R.Reduce.id | id);

react conc_succ =
  Reduce.Conc.(L.Nil | R.Nil)
  -[1]->
  Nil;

react conc_fail_L =
  Conc.(L.ReduceF | id)
  -[1]->
  ReduceF @[];

react conc_fail_R =
  Conc.(R.ReduceF | id)
  -[1]->
  ReduceF @[];


# Declarative goals #
# all instan rules
react goal_check =
  Reduce.Goal.(SC.id | id | FC.id)
   -[1]->
  Reduce.Goal.(SC.(id | Check.id) | id | FC.(id | Check.id))
  @[0,0,1,2,2]
  if !Check in param;

react goal_suc =
  Reduce.Goal.(SC.(id | Check.T) | id)
  -[1]->
  Nil @[];

react goal_fail =
  Reduce.Goal.(FC.(id | Check.T) | id)
  -[1]->
  Act.(Pre.F | Add.1 | Del.1) @[];

react goal_init =
  Reduce.Goal.(SC.(id | Check.F) | id | FC.(id | Check.F))
  -[1]->
  Goal.(SC.id | Try.(id | Cons.id) | FC.id)
  @[0,1,1,2]
  if !Try in param, !Trys in param;

react goal_reduce =
  Reduce.Goal.(SC.(id | Check.F) | Try.(id | Cons.id) | FC.(id | Check.F))
  -[1]->
  Goal.(SC.id | Try.(Reduce.id | Cons.id) | FC.id);

react goal_persist_nil =
  Reduce.Goal.(SC.(id | Check.F) | Trys.(Nil | Cons.id) | FC.(id | Check.F))
  -[1]->
  Goal.(SC.id | Try.(id | Cons.id) | FC.id)
  @[0,1,1,2];

# the following rule is used as instan rules
# because I have the problem that when there is no plan applicable for the top event in the declarative goal
# i.e. goal(SC.id | Try.(Reduce.F | Cons.id) | FC.id)
# the current order of the rules would apply try_failure (which is not what we want)
# as we want goal_persist
# however in order to apply goal_persist, Reduce needs to be introduced (i.e. application of rule Intention_step)
# so the best way to fix this is to create a new type for ReduceF in declarative goal for the top-level failure
# the none-top-level failure can still be handled by the try_failure though in the declarative goal.
react goal_root_failure_transform = 
Goal.(id | Try.(ReduceF | Cons.id))
-[1]->
Goal.(id | Try.(GReduceF | Cons.id));



react goal_persist =
Reduce.Goal.(SC.(id | Check.F) | Try.(GReduceF | Cons.id) | FC.(id | Check.F))
-[1]->
Goal.(SC.id | Try.(id | Cons.id) | FC.id)
@[0,1,1,2];



# Agent-Level Steps
# all normal rules
# Constraint intention_step < {intention_step, intention_done_succ}
react a_event_1 =
     Desires.(id | Event{e}.Identifier.E(1))
  || Intentions.id
  -[1]->
     Desires.id
  || Intentions.(id | Intent.(Event{e}.1 | Identifier.E(1)));
react a_event_2 =
     Desires.(id | Event{e}.Identifier.E(2))
  || Intentions.id
  -[1]->
     Desires.id
  || Intentions.(id | Intent.(Event{e}.1 | Identifier.E(2)));
react a_event_3 =
     Desires.(id | Event{e}.Identifier.E(3))
  || Intentions.id
  -[1]->
     Desires.id
  || Intentions.(id | Intent.(Event{e}.1 | Identifier.E(3)));
react a_event_4 =
     Desires.(id | Event{e}.Identifier.E(4))
  || Intentions.id
  -[1]->
     Desires.id
  || Intentions.(id | Intent.(Event{e}.1 | Identifier.E(4)));
react a_event_5 =
     Desires.(id | Event{e}.Identifier.E(5))
  || Intentions.id
  -[1]->
     Desires.id
  || Intentions.(id | Intent.(Event{e}.1 | Identifier.E(5)));

react intention_step_1 =
  Intent.(id | Identifier.E(1))
  -[1]->
  Intent.(Reduce.id | Identifier.E(1))
  if !Reduce in param;
react intention_step_2 =
  Intent.(id | Identifier.E(2))
  -[1]->
  Intent.(Reduce.id | Identifier.E(2))
  if !Reduce in param;

react intention_step_3 =
  Intent.(id | Identifier.E(3))
  -[1]->
  Intent.(Reduce.id | Identifier.E(3))
  if !Reduce in param;

react intention_step_4 =
  Intent.(id | Identifier.E(4))
  -[1]->
  Intent.(Reduce.id | Identifier.E(4))
  if !Reduce in param;

react intention_step_5 =
  Intent.(id | Identifier.E(5))
  -[1]->
  Intent.(Reduce.id | Identifier.E(5))
  if !Reduce in param;

# as i have not make the rule A_update explicit yet as an non-deterministic action
# i will just keep them as instan rules using id for now
react intention_done_F =
  Intent.(Reduce.ReduceF | id) -[1]-> 1@[];

react intention_done_succ =
   Intent.(Reduce.Nil | id) -[1]-> 1@[];


big failure = Intent.(ReduceF | id);
big no_failure = Intent.(Nil | id);
big empty_intention = Intentions.1;

   "
let print_bigraph_sim =
  "  int pw0 = [1:1:10];
    int pw1 = [2:1:10];
    int pw2 = [3:1:10];
    int pw3 = [4:1:10];
    int pw4 = [5:1:10];
    int pw5 = [6:1:10];
    int pw6 = [7:1:10];
    int pw7 = [8:1:10];
    int pw8 = [9:1:10];
    int pw9 = 10;

    int nw0 = [0:1:10];
    int nw1 = [1:1:10];
    int nw2 = [2:1:10];
    int nw3 = [3:1:10];
    int nw4 = [4:1:10];
    int nw5 = [5:1:10];
    int nw6 = [6:1:10];
    int nw7 = [7:1:10];
    int nw8 = [8:1:10];
    int nw9 = [9:1:10];

    # ranges of 0 to 10 for positive and negative value for revision
    int r1 = [0:1:10];
    int r2 = [0:1:10];

    # cap for stochastic effect weight
    int stocap = 10;
    int stos = [1:1:stocap];




    # init model_patrolling;
    # init model_concurrency;
    # init model_retrieval;
      init model;



    rules = [

            # change to Trys control
            (try_succ_unique),

            # add CheckToken for all initial user-specified plans    
            (init_plansets),

            (goal_root_failure_transform),

            # Plan selection token housekeeping
            (reset_planset),



            # constant belief true entailment

            (
            truth_atom_T_0(vars,pw0),
            truth_atom_T_1(vars,pw1),
            truth_atom_T_2(vars,pw2),
            truth_atom_T_3(vars,pw3),
            truth_atom_T_4(vars,pw4),
            truth_atom_T_5(vars,pw5),
            truth_atom_T_6(vars,pw6),
            truth_atom_T_7(vars,pw7),
            truth_atom_T_8(vars,pw8),
            truth_atom_T_9(vars,pw9),
            false_atom_T_0(vars,nw0),
            false_atom_T_1(vars,nw1),
            false_atom_T_2(vars,nw2),
            false_atom_T_3(vars,nw3),
            false_atom_T_4(vars,nw4),
            false_atom_T_5(vars,nw5),
            false_atom_T_6(vars,nw6),
            false_atom_T_7(vars,nw7),
            false_atom_T_8(vars,nw8),
            false_atom_T_9(vars,nw9)

            ),


            # epistemic belief entialment
            ( 
            comparator_atoms_T_0(vars,pw0),
            comparator_atoms_T_1(vars,pw1),
            comparator_atoms_T_2(vars,pw2),
            comparator_atoms_T_3(vars,pw3),
            comparator_atoms_T_4(vars,pw4),
            comparator_atoms_T_5(vars,pw5),
            comparator_atoms_T_6(vars,pw6),
            comparator_atoms_T_7(vars,pw7),
            comparator_atoms_T_8(vars,pw8),
            comparator_atoms_T_9(vars,pw9)
            ),

            (
            check_end_T
            ),

            (
            check_end_F
            ),            

            # epistemic belief revision

            (
            revise_pw(vars,r1,r2),
            revise_nw(vars,r1,r2),    
            revise_end
            ),       

            # actually reduce the programs
            ( reduce_event,
              act_check,
              select_plan_check,
              goal_check
            ),

            # the follow-up of the above actual reduction of the programs 
            ( act_F,
              select_plan_F,
              goal_suc,
              goal_fail,
              goal_init
            ),

            # special cases of rules specifying how the AND/OR tree is explored excluding those having ReduceF
            (conc_succ, goal_persist_nil),

            # conc_succ has to have a higher priority than both conc_nil_L and conc_nil_R           
            (conc_nil_L, conc_nil_R), 

            (seq_succ), 
            (try_succ),

            # special cases of rules to specify how the AND/OR tree should be explored for handling ReduceF
            (goal_persist, conc_fail_L, conc_fail_R),
            (seq_fail),
            (try_failure),

            # non-special cases of rules to specify how the AND/OR tree should be explored
            # rule conc_L and conc_R need to be the normal rules if concurrency is ever used
            (goal_reduce),       
            (reduce_seq),  
            (try_seq),
            
            # special cases of agent level operation
            (intention_done_succ, intention_done_F),


            # non-determinism of rules which have to be a normal rule to allow branching
            {act_T(stos)},
            {select_plan_T_1, 
             select_plan_T_2,
             select_plan_T_3,
             select_plan_T_4,
             select_plan_T_5,
             select_plan_T_6,
             select_plan_T_7,
             select_plan_T_8,
             select_plan_T_9,
             select_plan_T_10,
             conc_L, 
             conc_R
             },


            # non-special cases of agent level operation
            {a_event_1, 
             a_event_2,
             a_event_3,
             a_event_4,
             a_event_5,
             intention_step_1,
             intention_step_2,
             intention_step_3,
             intention_step_4,
             intention_step_5
             }
            ];
    actions = [
        instrules = {try_succ_unique, init_plansets, goal_root_failure_transform, reset_planset, truth_atom_T_0, truth_atom_T_1, truth_atom_T_2, truth_atom_T_3, truth_atom_T_4, truth_atom_T_5, truth_atom_T_6, truth_atom_T_7, truth_atom_T_8, truth_atom_T_9, false_atom_T_0, false_atom_T_1, false_atom_T_2, false_atom_T_3, false_atom_T_4, false_atom_T_5, false_atom_T_6, false_atom_T_7, false_atom_T_8, false_atom_T_9, comparator_atoms_T_0, comparator_atoms_T_1, comparator_atoms_T_2, comparator_atoms_T_3, comparator_atoms_T_4, comparator_atoms_T_5, comparator_atoms_T_6, comparator_atoms_T_7, comparator_atoms_T_8, comparator_atoms_T_9, check_end_T, check_end_F, revise_pw, revise_nw, revise_end, reduce_event, act_check, select_plan_check, goal_check, act_F, select_plan_F, goal_suc, goal_fail, goal_init, conc_succ, goal_persist_nil, conc_nil_L, conc_nil_R, seq_succ, try_succ, goal_persist, conc_fail_L, conc_fail_R, seq_fail, try_failure, goal_reduce, reduce_seq, try_seq, intention_done_succ, intention_done_F},
        executing_action = {act_T},
        selecting_event_1 = {a_event_1},
        selecting_event_2 = {a_event_2},
        selecting_event_3 = {a_event_3},
        selecting_event_4 = {a_event_4},
        selecting_event_5 = {a_event_5},
        selecting_intention_1  = {intention_step_1},
        selecting_intention_2  = {intention_step_2},
        selecting_intention_3  = {intention_step_3},
        selecting_intention_4  = {intention_step_4},
        selecting_intention_5  = {intention_step_5},
        selecting_plan_1 = {select_plan_T_1},
        selecting_plan_2 = {select_plan_T_2},
        selecting_plan_3 = {select_plan_T_3},
        selecting_plan_4 = {select_plan_T_4},
        selecting_plan_5 = {select_plan_T_5},
        selecting_plan_6 = {select_plan_T_6},
        selecting_plan_7 = {select_plan_T_7},
        selecting_plan_8 = {select_plan_T_8},
        selecting_plan_9 = {select_plan_T_9},
        selecting_plan_10 = {select_plan_T_10},
        selecting_concurrent_left = {conc_L},
        selecting_concurrent_right = {conc_R}

              ];
  "

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
        Printf.sprintf "B(\"%s\").(T|id)"
          (Array.fold_left (fun acc el -> if acc = "" then el else acc ^ " | " ^ el) "" !preds.(i))
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
    (Printf.sprintf "begin abrs\n\t%s\n%s\n%s" (print_var ()) print_bigraph_sim
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
