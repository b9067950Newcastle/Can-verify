(***********************************************************************)
(*                                                                     *)
(*                     CAN to BigraphER Compiler                       *)
(*                                                                     *)
(*                         Thibault Rivoalen                           *)
(*                        Intern from the ENAC                         *)
(*                                                                     *)
(***********************************************************************)

(** Module in charge of storing internally beliefs, desires, plans and actions
 and to translate each CAN line to BigraphER code.*)

(** {2 Global variables for storing} *)

val actions : string ref
(** Ref that contains the actions in BigraphER code.*)

val vars : string array ref
(** Ref that contains each belief/variable that appears in the CAN code.*)

val plans : string list array ref
(** Ref that contains each plan set that appears in the CAN code.*)

val beliefs : (int * (int * string)) list ref
(** Ref that contains each belief base and its number indexed from 1 that appears in the CAN code in BigraphER code.*)

val belief_base : (int * string array) list ref
(** Ref that contains each belief base that appears in the CAN code.*)

val desires_array : string array ref
(** Ref that contains each desire that appears in the CAN code.*)

val nb_bel : int ref
(** Ref that contains the number of belief bases. *)

val desires : string ref
(** Ref that contains each desire that appears in the CAN code encoded in BigraphER.*)

val preds : string array array ref
(** Ref that contains the predicates for the user's properties. *)

(** {2 Translation functions} *)

val empty_pb : string -> string
(** Function used to raise the empty plan-body warning. *)

val store_array : (string -> string) -> string array ref -> string -> string
(** Stores the string internally in the array ref and apply a function to the output.*)

val var : string -> string
(** Partial function for {!val:store_array} {!val:vars}.*)

val a_type : string -> unit
(** Partial function for {!val:store_array} {!val:Checking.actions_type_array}.*)

val b_type : string -> unit
(** Partial function for {!val:store_array} {!val:Checking.beliefs_type_array}.*)

val e_type : string -> unit
(** Partial function for {!val:store_array} {!val:Checking.events_type_array}.*)

val unknown : string -> string
(** Partial function for {!val:store_array} {!val:Checking.undeclared}.*)

val event : string -> string
(** Writes the event into BigraphER code. *)

val cond : Syntax.cond -> string
(** Writes the conditions into BigraphER code.*)

val goal : Syntax.cond -> string -> Syntax.cond -> string
(** Writes the goals into BigraphER code.*)

val seq_pb : string -> string -> string
(** Writes the sequence in the plan bodies into BigraphER code.*)

val conc_pb : string -> string -> string
(** Writes the concurency in the plan bodies into BigraphER code.*)

val transform_belief : Syntax.belief array -> string array
(** Transforms the belief array into string array for {!val:str_build_belief}.*)

val transform_desire : Syntax.desire array -> string array
(** Transforms the desire array into string array for {!val:str_build_desire}. *)

val belief : string -> string -> string
(** Helper function for a [fold_left] that concatenate the beliefs with the good typo.*)

val desire : string -> string -> string
(** Helper function for a [fold_left] that concatenate the desires with the good typo.*)

val str_build_belief : Syntax.belief array -> string
(** Folds left the array with the helper function {!val:belief}.*)

val strs_build_belief : (int * Syntax.belief array) list -> unit
(** Recursive function that stores the belief bases in {!val:beliefs}. *)

val str_build_desire : Syntax.desire array -> unit
(** Folds left the array with the helper function {!val:desire} to put it into the string ref {!val:desires}.*)

val set : Syntax.set -> string
(** Writes the addition/deletion sets into BigraphER code.*)

val find_i : string list array -> string -> int -> int option
(** [find_i array elt n] is used on [array] to find if [elt] is inside [array]. Returns either
 the index if present or [None] if not.*)

val plan_array_build : string -> Syntax.cond -> string -> unit
(** Contructs the ref {!val:plans} with BigraphER code.*)

val action_str_build : string -> string -> string -> string -> unit
(** Constructs the ref {!val:actions} with BigraphER code. *)

val fold_merge : string -> string -> string
val fold_lines : string -> string -> string
val fold_var : string -> string -> string
val fold_preds_name : string -> string -> string
val fold_preds : string -> string -> string
val fold_decl : string -> string -> string

(** {2 Writing a .big file} *)

val make_plans : unit -> string
(** Generates the plan sets.*)

val print_var : unit -> string
(** Generates the BigraphER code from the ref {!val:Checking.req_belief}.*)

val make_predicates : unit -> string array * string array
(** Generates the BigraphER code for the predicates. *)

val print_preds : string array -> string
(** Writes the outputs of {!val:make_predicates} into one string for the .big file. *)

val print_react_rules : string
(** String that contains the reaction rules to execute the BDI with BigraphER.*)

val print_bigraph_sim : string
(** String that contains the initialisation to execute the BDI with BigraphER.*)

val print_code : string -> string -> string -> string -> string
(** Helper function for {!val:make_code}.*)

val make_code :
  (int * string) list -> int -> string -> string -> (int * string) list
(** Helper function for {!val:make_program}.*)

val make_program : unit -> (int * string) list
(** Generates the whole BigraphER code into one string, with the reactions rules and the initialisation of the PBRS for all the belief bases.*)

val output_big : string -> string -> unit
(** Writes a string from {!val:make_program} into a .big file *)
