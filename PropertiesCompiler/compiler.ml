open Io
open Error_type

let error_type = function
  | Lexer.Error -> "Lexing error"
  | Parser.Error -> "Property Syntax error"
  | _ -> ""

let discarded = ref [| 0 |]
let errors = ref 0
let file = ref ""
let last_line = ref 0
let last_col = ref 1000
let last_tok = ref "  "

let rec parsing f =
  let ch = open_in f in
  let lexbuf = Lexing.from_channel ch in
  try
    let ast = Parser.properties Lexer.token lexbuf in
    close_in ch;
    ast
  with exn ->
    let n = Array.length !discarded - 1 in
    let open Lexing in
    let p = lexbuf.lex_start_p in
    (* error position in buffer *)
    let l = p.pos_lnum + n
    and c = p.pos_cnum - p.pos_bol
    and tok = lexeme lexbuf in
    Printf.eprintf "%s line %d, column %d, token \"%s\"\n%!" (error_type exn) l
      c tok;
    if String.equal !last_tok tok && !last_line = l - 1 && !last_col = c then
      raise NothingRecognized;
    last_tok := tok;
    last_line := l;
    last_col := c;
    discarded := Array.append !discarded [| l |];
    errors := !errors + 1;
    close_in ch;
    discard_line !file !discarded;
    let _ = parsing "out.txt" in
    raise PropertiesError

let parse_prop f =
  file := f;
  Printf.printf "Parsing %s ...\n%!" f;
  try parsing f
  with _ ->
    let ast = parsing "out.txt" in
    Printf.eprintf
      "\n%d syntax error(s) encountered, see above for details\n\n%!" !errors;
    let _ = Sys.command "rm -f out.txt" in
    ast
