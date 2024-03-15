(***********************************************************************)
(*                                                                     *)
(*                        Properties Compiler                          *)
(*                                                                     *)
(*                         Thibault Rivoalen                           *)
(*                        Intern from the ENAC                         *)
(*                                                                     *)
(***********************************************************************)

(** Module in charge of building the internal translation from human language to PRISM properties *)

val preds : string array array ref
val fold_bel : string -> string -> string

val c_quantity : Syntax.quantity -> string
(** Translates the quantity into a string. *)

val c_belief : string array -> string
(** Translates the beliefs into a string. *)

val build_prop : string -> string -> string
(** Builds the whole property string. *)

val c_line : Syntax.line -> string list
(** Constructs the AST for the properties. *)

val c_properties : Syntax.properties -> string list
(** Translates the properties in human language to PRISM language. *)
