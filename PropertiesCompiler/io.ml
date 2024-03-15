let built_in_prop =
  "\n\n\
   A [ F (\"no_failure\"&(X \"empty_intention\")) ];\n\
  \ E [ F (\"no_failure\"&(X \"empty_intention\")) ];\n\
  \ A [ F (\"failure\"&(X \"empty_intention\")) ];\n\
  \ E [ F (\"failure\"&(X \"empty_intention\")) ];\n"

let read_file_to_string str =
  let rec read_stream stream =
    try
      let line = input_line stream in
      line :: read_stream stream
    with End_of_file -> []
  in
  let stream = open_in str in
  String.concat "\n" (read_stream stream)

let discard_line file discarded =
  let input = open_in file in
  let output = open_out "out.txt" in
  let rec scan l =
    let str = input_line input in
    if Array.exists (fun x -> x = l) discarded then scan (l + 1)
    else (
      Printf.fprintf output "%s" (str ^ "\n");
      scan (l + 1))
  in
  try scan 1
  with _ ->
    close_in input;
    close_out output

let add_prop file prop =
  let content = read_file_to_string file in
  let out = open_out file in
  Printf.fprintf out "%s"
    (content ^ built_in_prop
    ^ List.fold_left (fun ch p -> Printf.sprintf "%s\n%s" ch p) "" prop);
  close_out out
