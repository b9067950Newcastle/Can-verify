(***********************************************************************)
(*                                                                     *)
(*                             CAN-Verify                              *)
(*                                                                     *)
(*                         Thibault Rivoalen                           *)
(*                        Intern from the ENAC                         *)
(*                                                                     *)
(***********************************************************************)

(** Main module for the tool *)

val static : bool ref
val dynamic : bool ref
val states : int ref
val prop : string list ref
val bigfile : bool ref
val prop_file : string ref
val main : string -> unit
