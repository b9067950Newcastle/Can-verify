%{ open Syntax %}
%token EOF IN ALL SOME EXECUTIONS POSSIBLE THE_BELIEF THE_BELIEFS HOLDS HOLD COMMA LB RB EVENTUALLY
%left COMMA
%token <string> BEL_NAME
%start <Syntax.properties> properties
%%

properties:
    | line EOF { $1 }

line:
    | line_t line { Seq_line($1, $2) }
    | line_t { $1 }

line_t:
    | IN ALL POSSIBLE EXECUTIONS EVENTUALLY THE_BELIEF BEL_NAME HOLDS { Prop(All, [|$7|]) }
    | IN SOME EXECUTIONS EVENTUALLY THE_BELIEF BEL_NAME HOLDS { Prop(Som, [|$6|]) }
    | IN ALL POSSIBLE EXECUTIONS EVENTUALLY THE_BELIEFS LB bel RB HOLD { Prop(All, $8) }
    | IN SOME EXECUTIONS EVENTUALLY THE_BELIEFS LB bel RB HOLD { Prop(Som, $7) }

bel:
    | bel COMMA bel {Array.append $1 $3}
    | BEL_NAME {Array.make 1 $1}
