(***********************************************************************)
(*                                                                     *)
(*                     CAN to BigraphER Compiler                       *)
(*                                                                     *)
(*                         Thibault Rivoalen                           *)
(*                        Intern from the ENAC                         *)
(*                                                                     *)
(***********************************************************************)

(** Module in charge of building the internal translation from CAN to BigraphER *)

val c_pb : Syntax.plan_body -> string -> string
(** Constructs the plan body into a string. *)

val c_plan : Syntax.plan list -> unit
(** Constructs the internal storage of plans to gather plans into PlanSets for BigraphER *)

val c_action : Syntax.action list -> unit
(** Constructs the internal storage of actions for BigraphER *)

val c_line : Syntax.line -> unit
(** Constructs the internal storage for beliefs, desires, plan via {!val:c_plan} and actions via {!val:c_action}. *)

val c_program : Syntax.line -> (int * string) list
(** Translates the whole program (in CAN) into BigraphER code, with the reaction rules and initialisation of the PBRS.*)
