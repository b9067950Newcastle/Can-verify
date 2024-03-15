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
  let output = open_out "out.can" in
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
