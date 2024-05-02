%{ open Syntax %}
%token EOF THE_BELIEF HOLDS EVENTUALLY WHAT IS MAXIMUM MINIMUM PROBABILITY THAT
%token <string> BEL_NAME
%start <Syntax.properties> properties
%%

properties:
    | line EOF { $1 }

line:
    | line_t line { Seq_line($1, $2) }
    | line_t { $1 }

line_t:
    | WHAT IS MINIMUM PROBABILITY THAT EVENTUALLY THE_BELIEF BEL_NAME HOLDS { Prop(All, [|$8|]) }
    | WHAT IS MAXIMUM PROBABILITY THAT EVENTUALLY THE_BELIEF BEL_NAME HOLDS { Prop(Som, [|$8|]) }
