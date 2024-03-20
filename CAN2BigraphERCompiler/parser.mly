%{ open Syntax %}
%token EOF BELIEF DESIRE PLAN ARROW GOAL LB RB COLON TRUE FALSE COMMA SEMI_COL CONCURENCY AND LP RP LA RA ACTION STOP
%left COMMA CONCURENCY AND
%right SEMI_COL
%token <string> STRING
%token <string> NUM
%start <Syntax.program> program
%%

program:
    | line EOF { $1 }

line:
    | line_t line { Seq_line($1, $2) }
    | line_t { $1 }

line_t:
    | BELIEF belief_num { Beliefs($2) }
    | DESIRE desire { Desires($2) }
    | PLAN plan { Plans($2) }
    | ACTION action { Actions($2) }

belief_num:
    | belief_num_t { $1 }
    | belief_num_t belief_num { $1 @ $2 }

belief_num_t:
    | NUM belief { [(int_of_float (float_of_string $1), $2)] }
    | NUM { [(int_of_float (float_of_string $1), [|Belief("", "", "")|])] }

belief:
    | belief COMMA belief { Array.append $1 $3 }
    | STRING COLON LA STRING COMMA STRING RA { Array.make 1 (Belief($1, $4, $6)) }

desire:
    | desire COMMA desire { Array.append $1 $3 }
    | STRING { Array.make 1 (Desire($1)) }

plan:
    | plan_t { $1 }
    | plan_t plan { Array.append $1 $2 }

plan_t:
    | STRING COLON cond ARROW pb STOP { Array.make 1 (Plan($1, $3, $5)) }
    | STRING COLON cond ARROW STOP { Array.make 1 (Plan($1, $3, Empty)) }

pb:
    | pb SEMI_COL pb { Seq_PB($1, $3) }
    | pb CONCURENCY pb { Conc_PB($1, $3) }
    | STRING { Event_Act($1) }
    | goal { $1 }

goal:
    | GOAL LP cond COMMA STRING COMMA cond RP { Goal($3, $5, $7) }

cond:
    | TRUE { True }
    | FALSE { False }
    | STRING { Name($1) }
    | cond AND cond { Mult($1, $3) }

action :
    | action_t { $1 }
    | action_t action { Array.append $1 $2 }

action_t :
    | STRING COLON cond ARROW LA set RA COMMA LA set RA { Array.make 1 (Action($1, $3, Del($6), Add($10))) }

set :
    | set COMMA set { Array.append $1 $3 }
    | STRING COLON LB STRING COMMA STRING RB { Array.make 1 (Belief($1, $4, $6)) }