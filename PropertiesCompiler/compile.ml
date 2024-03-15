open Syntax

let preds = ref [||]
let c_quantity q = match q with All -> "A" | Som -> "E"

let fold_bel str ch =
  if String.equal str "" then Printf.sprintf "predicate_%s" ch
  else Printf.sprintf "%s_%s" str ch

let c_belief bel = Array.fold_left fold_bel "" bel
let build_prop q beliefs = Printf.sprintf "%s [F (\"%s\")];" q beliefs

let rec c_line line =
  match line with
  | Seq_line (l1, l2) -> c_line l1 @ c_line l2
  | Prop (quantity, beliefs) ->
      preds := Array.append !preds [| beliefs |];
      [ build_prop (c_quantity quantity) (c_belief beliefs) ]

let c_properties properties = c_line properties
