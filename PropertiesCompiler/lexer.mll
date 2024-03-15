{ open Parser
  exception Error
}

rule token = parse
| '\n' { Lexing.new_line lexbuf; token lexbuf }
| "//"[^'\n']* { token lexbuf }
| " " { token lexbuf }
| "In" { IN }
| "all" { ALL }
| "some" { SOME }
| "executions," { EXECUTIONS }
| "eventually" { EVENTUALLY }
| "the belief" { THE_BELIEF }
| "the beliefs" { THE_BELIEFS }
| '(' { LB } | ')' { RB } | ',' { COMMA }
| "possible" { POSSIBLE }
| "holds"'.'? { HOLDS }
| "hold"'.'? { HOLD }
| ['A'-'z' '0'-'9' '_' '-']['A'-'z' '0'-'9' '_' '-']* as str { BEL_NAME str }
| eof { EOF }
| _ { raise Error }
