type cond = True | False | Name of string | Mult of cond * cond

type plan_body =
  | Seq_PB of plan_body * plan_body
  | Conc_PB of plan_body * plan_body
  | Goal of cond * string * cond
  | Event_Act of string
  | Empty

type belief = Belief of string * string * string
type desire = Desire of string * string
type plan = Plan of string * string * cond * plan_body
type set = Add of belief array | Del of belief array
type action = Action of string * cond * set * string * string * set * string * string

type line =
  | Seq_line of line * line
  | Beliefs of (int * belief array) list
  | Desires of desire array
  | Plans of plan array
  | Actions of action array

type program = line
