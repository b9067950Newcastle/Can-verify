(***********************************************************************)
(*                                                                     *)
(*                     CAN to BigraphER Compiler                       *)
(*                                                                     *)
(*                         Thibault Rivoalen                           *)
(*                        Intern from the ENAC                         *)
(*                                                                     *)
(***********************************************************************)

(** Module that handles the input and output. *)

val read_file_to_string : string -> string
(** Reads a file and return its content. *)

val discard_line : string -> int array -> unit
(** Discards the lines in the array from the file. *)
