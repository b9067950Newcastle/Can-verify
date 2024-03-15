type quantity = All | Som
type line = Seq_line of line * line | Prop of quantity * string array
type properties = line
