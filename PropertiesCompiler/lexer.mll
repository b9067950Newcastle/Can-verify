{ open Parser
  exception Error
}

rule token = parse
| '\n' { Lexing.new_line lexbuf; token lexbuf }
| "//"[^'\n']* { token lexbuf }
| " " { token lexbuf }
| "that" { THAT }
| "the belief" { THE_BELIEF }
| "holds"'.'? { HOLDS }
| "What" { WHAT }
| "is" { IS }
| "eventually" { EVENTUALLY }
| "the minimum" { MINIMUM }
| "the maximum" { MAXIMUM }
| "probability" { PROBABILITY }
| ['A'-'z' '0'-'9' '_' '-']['A'-'z' '0'-'9' '_' '-']* as str { BEL_NAME str }
| eof { EOF }
| _ { raise Error }
