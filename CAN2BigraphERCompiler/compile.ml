open Syntax
open Bigraph

let rec c_pb plan_body evt =
  match plan_body with
  | Seq_PB (pb1, pb2) -> seq_pb (c_pb pb1 evt) (c_pb pb2 evt)
  | Conc_PB (pb1, pb2) -> conc_pb (c_pb pb1 evt) (c_pb pb2 evt)
  | Goal (sc, event, fc) -> goal sc event fc
  | Event_Act str ->
      if Array.exists (fun x -> String.equal x str) !Checking.events_type_array
      then event str
      else if
        Array.exists (fun x -> String.equal x str) !Checking.actions_type_array
      then str
      else unknown str
  | Empty -> empty_pb evt

let rec c_plan plans =
  match plans with
  | h :: t -> (
      match h with
      | Plan (event, c, pb) ->
          plan_array_build event c (c_pb pb event);
          c_plan t)
  | [] -> ()

let rec c_action actions =
  match actions with
  | h :: t -> (
      match h with
      | Action (str, c, del, add) ->
          action_str_build str (cond c) (set del) (set add);
          c_action t)
  | [] -> ()

let rec c_line line =
  match line with
  | Seq_line (l1, l2) ->
      c_line l1;
      c_line l2
  | Beliefs b -> strs_build_belief b
  | Desires d -> str_build_desire d
  | Plans p ->
      let plans_list = Array.to_list p in
      c_plan plans_list
  | Actions a ->
      let actions_list = Array.to_list a in
      c_action actions_list

let c_program program =
  c_line program;
  make_program ()
