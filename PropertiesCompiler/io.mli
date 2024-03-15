(***********************************************************************)
(*                                                                     *)
(*                        Properties Compiler                          *)
(*                                                                     *)
(*                         Thibault Rivoalen                           *)
(*                        Intern from the ENAC                         *)
(*                                                                     *)
(***********************************************************************)

(** Module that handles the input and output. *)

val built_in_prop : string
(** Contains the four built-in properties in PRISM language. *)

val read_file_to_string : string -> string
(** Reads a file and return its content. *)

val discard_line : string -> int array -> unit
(** [discard_line file array] discards the lines in [array] from file. *)

val add_prop : string -> string list -> unit
(** Adds the properties in parameter to check for PRISM in the file given in parameter. *)
