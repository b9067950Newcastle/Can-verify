{ open Parser
  exception Error
}

let beliefs = "// "(('I'|'i')"nitial ")?('B'|'b')"elief bases"
let events = "// "(('E'|'e')"xternal ")?('E'|'e')"vent"'s'?
let plans = "// "('P'|'p')"lan"('s'|(' '('L'|'l')"ibrary"))?
let actions = "// "('A'|'a')"ction"('s'|("s "('D'|'d')"escription"))?

rule token = parse
| '\n' { Lexing.new_line lexbuf; token lexbuf }
| beliefs { BELIEF }
| events { DESIRE }
| plans { PLAN }
| actions { ACTION }
| "//"[^'\n']* { Lexing.new_line lexbuf; token lexbuf }
| " " { token lexbuf }
| '.' { STOP }
| "<-" { ARROW }
| "goal" { GOAL }
| ['1' - '9']['0'-'9']*'.' as num { NUM num }
| '(' { LP } | ')' { RP } | '<' { LA } | '>' { RA } | '{' { LB } | '}' { RB }
| ',' { COMMA } | ';' { SEMI_COL } | ':' { COLON } | "||" { CONCURENCY }
| '&' { AND }
| "true" { TRUE } | "false" { FALSE }
| ['A'-'z' '0'-'9' '_' '-']*  as str { STRING str }
| eof { EOF }
| _ { raise Error }
