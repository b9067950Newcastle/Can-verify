open Syntax
open Bigraph

let rec c_cond cond =
  match cond with
  | Name str -> b_type str
  | Mult (c1, c2) ->
      c_cond c1;
      c_cond c2
  | _ -> ()

let rec c_pb plan_body =
  match plan_body with
  | Seq_PB (pb1, pb2) ->
      c_pb pb1;
      c_pb pb2
  | Conc_PB (pb1, pb2) ->
      c_pb pb1;
      c_pb pb2
  | Goal (sc, event, fc) ->
      c_cond sc;
      e_type event;
      c_cond fc
  | Event_Act _ | Empty -> ()

let rec c_plan plans =
  match plans with
  | h :: t -> (
      match h with
      | Plan (event, c, pb) ->
          e_type event;
          c_cond c;
          c_pb pb;
          c_plan t)
  | [] -> ()

let c_set set =
  match set with
  | Add b | Del b ->
      Array.iter
        (fun x ->
          match x with
          | Belief bel -> if not (String.equal bel "") then b_type bel else ())
        b

let rec c_action actions =
  match actions with
  | h :: t -> (
      match h with
      | Action (str, c, del, add) ->
          a_type str;
          c_cond c;
          c_set del;
          c_set add;
          c_action t)
  | [] -> ()

let rec c_line line =
  match line with
  | Plans p ->
      let plans_list = Array.to_list p in
      c_plan plans_list
  | Actions a ->
      let actions_list = Array.to_list a in
      c_action actions_list
  | Seq_line (l1, l2) ->
      c_line l1;
      c_line l2
  | Beliefs b ->
      let rec scan l =
        match l with
        | (_, h) :: t ->
            Array.iter (fun x -> match x with Belief bel -> b_type bel) h;
            scan t
        | [] -> ()
      in
      scan b
  | Desires d -> Array.iter (fun x -> match x with Desire des -> e_type des) d

let c_program program = c_line program
