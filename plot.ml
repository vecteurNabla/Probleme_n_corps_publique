open Tipe

let () =
  if Sys.argv.(1) = "help" then
    begin
      Printf.printf "
         Ce programme permet d'afficher un graphe de la trajectoire
         de corps (en 2 dimensions), à partir de conditions initiales
         données, avec une méthode d'intégration donnée, une méthode de
         calcul des accélérations données, une durée et un temps donné.\n";
      Printf.printf "
         Syntaxe : \n
         \t $ ./plot help \n
         affiche cette aide\n\n
         \t $ ./plot ki ka i t h theta\n
         ki est 0 ou 1, 0 pour la méthode d'euler, 1 pour rk4\n
         ka est 0 ou 1, 0 pour le calcul naïf, 1 pour Barnes-Hut avec
         le paramètre theta, un flottant, 1.0 par défault\n
         i est un entier, indique au programme de lire le fichier
         \"condi.dat\" pour les conditions initiales. Trois fichiers
         sont fournis : \"cond0.dat\", \"cond1.dat\" et
         \"cond2.dat\". Se référer au README.md pour le formattage des
         fichiers de conditions initiales.\n
         t est la durée, un flottant\n
         h est le pas de temps, un flottant.\n\n";
      Printf.printf "
         Le programme crée alors plusieurs fichiers : \n
         \t \"icorpsk.dat\" pour k allant de 1 à n, si \"condi.dat\"
         contient n corps, contenant les polistions successives du
         corps k\n
         \t \"plot_cond_ini_i.plot\", un fichier lisible par gnuplot
         par exemple, permettant de tracer les trajectoires.\n\n";
      flush stdout;
    end
  else
  (* float array array list -> out_channel array -> unit
   * imprime dans les canaux de ocs les données contenues 
   * dans l, où l est une liste de tableaux contenant chacun
   * les positions à un instant donné des corps 
   * Le canal ocs.(i) contiendra donc les positions successives
   * du corps i
   *)
  let print_output l ocs =
    List.iter (fun x ->
        Array.iter2 (fun v oc -> Printf.fprintf oc "%e %e\n" (v.(0))
                                   (v.(1))
          ) x ocs;
      ) l in
  (* int -> float * Tipe.corps lsit 
   * lit le fichier condi.dat, contenant des conditions initiales
   * formatées, et crée la liste des corps correspondante
   *)
  let read_input i =
    let ic = open_in ("cond" ^ (string_of_int i) ^ ".dat") in
    let g = float_of_string (input_line ic) in
    let try_read () =
      try
        let space = input_line ic in
        let mass_s = input_line ic in
        let pos_s = input_line ic in
        let vit_s = input_line ic in
        let mass = float_of_string mass_s in
        let pos = Array.of_list (List.map (float_of_string)
                                   (List.map (String.trim)
                                      (String.split_on_char ',' pos_s)
                                   )
                    ) in
        let vit = Array.of_list (List.map (float_of_string)
                                   (List.map (String.trim)
                                      (String.split_on_char ',' vit_s)
                                   )
                    ) in
        Some({mass = mass; pos = pos; vit = vit; (* noeud = None *)})
      with End_of_file -> None
    in
    let rec loop acc = match try_read () with
      | Some s -> loop (s::acc)
      | None -> close_in ic; (g, List.rev acc) 
    in loop []
  in
  let k = int_of_string Sys.argv.(3) in
  let conds = read_input k in
  let files = Array.init (List.length (snd conds)) (fun i ->
                  Sys.argv.(3) ^ "corps" ^ (string_of_int i) ^ ".dat"
                ) in
  let t = float_of_string (Sys.argv.(4)) in
  let h = float_of_string (Sys.argv.(5)) in
  let theta = if Array.length Sys.argv >= 7 then float_of_string (Sys.argv.(6))
              else 1. in
  let meth_int = [| euler; rk4|] in
  let meth_acc = [| calc_acc_naif; calc_acc_arbre theta|] in
  let ki = int_of_string (Sys.argv.(1)) in
  let ka = int_of_string (Sys.argv.(2)) in
  let tests = pb_n_corps meth_int.(ki) meth_acc.(ka) conds t h in
  let ocs = Array.map (open_out) files in
  print_output tests ocs;
  Array.iter (close_out) ocs;
  let oc = open_out ("plot_cond_ini_" ^ Sys.argv.(3) ^ ".plot") in
  begin
    Printf.fprintf oc "set size square\n";
    Printf.fprintf oc "plot ";
    Array.iter (fun x ->
        begin
          Printf.fprintf oc "'%s', " x;
        end
      ) files
  end;
  close_out oc
;;

  
