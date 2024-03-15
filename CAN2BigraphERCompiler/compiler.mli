(***********************************************************************)
(*                                                                     *)
(*                     CAN to BigraphER Compiler                       *)
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

val parsing : string -> Syntax.program
(** Inner function of {!val:parse_can} allowing to find every syntax error at once. *)

val parse_can : string -> Syntax.program
(** Parses the file with the help of [Menhir]. *)
