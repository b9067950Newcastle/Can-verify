(***********************************************************************)
(*                                                                     *)
(*                     CAN to BigraphER Compiler                       *)
(*                                                                     *)
(*                         Thibault Rivoalen                           *)
(*                        Intern from the ENAC                         *)
(*                                                                     *)
(***********************************************************************)

(** Module for static checking *)

(** {2 Checking for missing elements} *)

(** {3 Helping funcitons} *)

val string_of_cond : string array -> Syntax.cond -> string array
(** Transform a condition into a string array. *)

(** {3 Global storing} *)

(** {4 Variables} *)

val actions_type_array : string array ref
(** Ref that contains all the strings referred as actions. *)

val events_type_array : string array ref
(** Ref that contains all the strings referred as events. *)

val beliefs_type_array : string array ref
(** Ref that contains all the strings referred as beliefs. *)

val undeclared : string array ref
(** Ref that contains all the strings referred as events or actions but without any declaration. *)

val type_error : string array ref
(** Ref that contains all the strings referred in two or more different types. *)

val req_belief : (string * string array array) list ref
(** Ref that contains the required beliefs for the plans to be applicable.*)

val errors : int ref
(** Ref that contains the number of errors in the model. *)

val warnings : int ref
(** Ref that contains the number of warnings in the model. *)

val plan_act_error : bool ref
(** Ref that contains if the plans or actions make errors in the model. *)

val belief_errors : int ref
(** Ref that contains the number of wrong belief bases in the model. *)

val not_app_plan : string array ref
(** Ref that contains all the non applicable plans with the initial belief base. *)

val no_belief : bool ref
(** Ref that says if there is no belief implemented. *)

val min_plan : int ref
(** Ref that contains the minimum number of plans required (default 2). *)

val max_plan : int ref
(** Ref that contains the maximum number of plans allowed (default 100). *)

val min_char : int ref
(** Ref that contains the minimum number of characters required for the names (default 2). *)

val max_char : int ref
(** Ref that contains the maximum number of characters allowed for the names (default 20). *)

(** {4 Functions} *)

val store_plan_cond : string -> Syntax.cond -> unit
(** Stores the preconditions of each plan in the list assoc {!val:req_belief} with the event as key. *)

(** {3 Checking functions} *)

val check_length : string -> unit
(** Checks if the length of the string in parameter is not too short nor too long. *)

val beliefs_check : string array -> unit
(** Checks if there is/are belief(s) in the model. *)

val desires_check : string array -> unit
(** Checks if there is/are desire(s) in the model. *)

val plans_check : string list array -> unit
(** Checks if every plan meets the requirement for the length of the name. *)

val check_length_char_array : string array -> unit
(** Checks the length of every element of the array with {!val:check_length}. *)

val check_types : unit -> unit
(** Checks if the strings in {!val:actions_type_array}, {!val:events_type_array} and {!val:beliefs_type_array} are not in the other arrays. *)

val check_once : string list array -> unit
(** Checks the plans and actions. *)

val check_all : string array -> string array -> int -> unit
(** Checks the beliefs and desires. *)
