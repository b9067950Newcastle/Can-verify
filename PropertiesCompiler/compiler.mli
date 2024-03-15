(***********************************************************************)
(*                                                                     *)
(*                        Properties Compiler                          *)
(*                                                                     *)
(*                         Thibault Rivoalen                           *)
(*                        Intern from the ENAC                         *)
(*                                                                     *)
(***********************************************************************)

(** Module that parses the program *)

val discarded : int array ref
(** Store every line that needs to be discarded to execute parsing.*)

val errors : int ref
(** Counts the number of errors during parsing.*)

val file : string ref
(** Contains the file that the program parses.*)

val parsing : string -> Syntax.properties
(** Inner function of {!val:parse_prop} allowing to find every syntax error at once. *)

val parse_prop : string -> Syntax.properties
(** Parses the file with the help of [Menhir]. *)
