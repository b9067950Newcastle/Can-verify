(***********************************************************************)
(*                                                                     *)
(*                     CAN to BigraphER Compiler                       *)
(*                                                                     *)
(*                         Thibault Rivoalen                           *)
(*                        Intern from the ENAC                         *)
(*                                                                     *)
(***********************************************************************)

(** Module in charge of the precompilation for typing. *)

val c_cond : Syntax.cond -> unit
(** Types the conditions. *)

val c_set : Syntax.set -> unit
(** Types the sets. *)

val c_pb : Syntax.plan_body -> unit
(** Types the plan bodies. *)

val c_plan : Syntax.plan list -> unit
(** Types the plans. *)

val c_action : Syntax.action list -> unit
(** Types the actions. *)

val c_line : Syntax.line -> unit
(** Types the lines. *)

val c_program : Syntax.line -> unit
(** Types the program. *)
