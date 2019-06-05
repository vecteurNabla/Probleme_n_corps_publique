
type vecteur = float array
;;

type corps = {
  mass : float;
  mutable pos : vecteur;
  mutable vit : vecteur;
  (* mutable noeud : noeud option; *)
}

 and noeud = {
  (* prof : int; *)
  mutable etiq : corps option;
  x : vecteur;
  y : vecteur;
  mutable fils : noeud array option;
  (* parent : noeud option; *)
};;



(*couple (g, c) où g est la valeur à utiliser pour la constante de
 *gravitation universelle, suivant les exemples, et c la liste des
 *corps, avec leurs masses, positions initiales et vitesses initiales
 *)

type cond_init = float * corps list
;;

   
(*constante de gravitation universelle, à changer selon les exemples *)
let g_norm = 6.67408e-11;;
let g_1 = 1.;;



(* Quelques nécessités pour map2 /ocaml magic !/ *)

external length : 'a array -> int = "%array_length"
external unsafe_get: 'a array -> int -> 'a = "%array_unsafe_get"
external unsafe_set: 'a array -> int -> 'a -> unit = "%array_unsafe_set"
external create: int -> 'a -> 'a array = "caml_make_vect"
external create_float: int -> float array = "caml_make_float_vect"
                                

  (* val map2 : 'a array -> 'a array -> 'a array
   * alias de Array.map2, qui n'est pas implémentée dans la version de
   * caml présente au lycée (copiée depuis la bib std)
   *)

let map2 f a b =
  let la = length a in
  let lb = length b in
  if la <> lb then
    invalid_arg "Array.map2: arrays must have the same length"
  else begin
    if la = 0 then [||] else begin
      let r = create la (f (unsafe_get a 0) (unsafe_get b 0)) in
      for i = 1 to la - 1 do
        unsafe_set r i (f (unsafe_get a i) (unsafe_get b i))
      done;
      r
    end
  end
;;


  (* val list_map5 : ('a->'b->'c->'d->'e->'f)->'a list-> ... ->'f list
   * comme List.map2, mais avec 5 listes
   *)

let rec list_map5 f l1 l2 l3 l4 l5 =
  match (l1, l2, l3, l4, l5) with
    ([], [], [], [], []) -> []
  | (a1::r1, a2::r2, a3::r3, a4::r4, a5::r5) -> let r = f a1 a2 a3 a4 a5 in
                                        r :: (list_map5 f r1 r2 r3 r4 r5)
  | (_, _, _, _, _) -> invalid_arg "list_map5"
;;



  (* val ( ++ ) : vecteur -> vecteur -> vecteur
   * X ++ X' renvoie la somme vectorielle de X et X', où X et X' sont des
   * vecteurs de mêmes dimensions
   *)


let ( ++ ) x x' =
  map2 ( +. ) x x'
;;

let ( -- ) x x' =
  map2 ( -. ) x x'
;;



  (* val ( +++ ) : float array array -> % -> %
   * x +++ x' renvoie la somme matricielle de x et x', où x et x' sont
   * deux matrices de flottants de mêmes dimmensions
   *)

let ( +++ ) x x' =
  map2 ( map2 ( +. )) x x'
;;

  (* val ( **. ) : float -> vecteur -> vecteur
   * a **. x renvoie le produit de a par x, où a est un
   * flottant, x un vecteur 
   *)


let ( **. ) a x =
  Array.map (fun y -> a *. y  ) x
;;
  


  (* val ( *** ) : float -> float array array -> %
   * a *** x renvoie le produit de a par x, où a est un flottant et x
   * une matrice de flottants
   *)

let ( *** ) a x=
  Array.map (Array.map (fun y -> a *. y)) x
;;



  (* val cree_fils : noeud -> unit
   * cree_fils n crée 4 fils au noeud n, séparant la zone de l'espace
   * représentée par n en 4, de sorte que : f2 | f3
   *                                        ---|---
   *                                        f0 | f1
   *)


let cree_fils n =
  let x1, x2 = n.x.(0), n.x.(1) in
  let y1, y2 = n.y.(0), n.y.(1) in
  (* let d = n.prof in *)
  let f0 = {(* prof = d+1; *) etiq = None;
            x = [| x1; (x1+.x2)/.2.|];
            y = [| y1; (y1+.y2)/.2.|];
            fils = None;
            (* parent = Some(n) *)} in
  let f1 = {(* prof = d+1; *) etiq = None;
            x = [| (x1+.x2)/.2.; x2|];
            y = [| y1; (y1+.y2)/.2.|];
            fils = None;
            (* parent = Some(n) *)} in
  let f2 = {(* prof = d+1; *) etiq = None;
            x = [| x1; (x1+.x2)/.2.|];
            y = [| (y1+.y2)/.2.; y2|];
            fils = None;
            (* parent = Some(n) *)} in
  let f3 = {(* prof = d+1 ;*) etiq = None;
            x = [| (x1+.x2)/.2.; x2|];
            y = [| (y1+.y2)/.2.; y2|];
            fils = None;
            (* parent = Some(n) *)} in
  n.fils <- Some([|f0; f1; f2; f3|])
;;


  (* val constr_arbre : noeud -> corps list -> unit
   * constr_arbre n c construit récursivement l'arbre répartissant les
   * corps de c, contenus dans la région de l'espace représentée par n
   *)


let rec constr_arbre n c =
  let nb_corps = List.length c in
  if nb_corps > 1 then
    begin
      cree_fils n;
      let m, pos, c0, c1, c2, c3 = 
        List.fold_left (fun a x ->
            let m, pos, c0, c1, c2, c3 = a in
            if x.pos.(0) < (n.x.(0)+.n.x.(1))/.2. then
              if x.pos.(1) < (n.y.(0)+.n.y.(1))/.2. then
                m +. x.mass, pos ++ (x.mass **. x.pos), x::c0, c1, c2, c3
              else m +. x.mass, pos ++ (x.mass **. x.pos), c0, c1, x::c2, c3
            else
              if x.pos.(1) < (n.y.(0)+.n.y.(1))/.2. then
                m +. x.mass, pos ++ (x.mass **. x.pos), c0, x::c1, c2, c3
              else m +. x.mass, pos ++ (x.mass **. x.pos), c0, c1, c2, x::c3
          ) (0.0, [|0.; 0.|], [], [], [], []) c
      in
      n.etiq <- Some({ mass = m; pos = (1./.m) **. pos; vit = [|0.;0.|];
                       (* noeud = Some(n)*)});
      let Some(fils) = n.fils in
      Array.iteri (fun i x -> constr_arbre x [|c0; c1; c2; c3|].(i)
        ) fils;
    end
  else if nb_corps = 1 then
    begin
      let [corps] = c in 
      n.etiq <- Some(corps);
      (* corps.noeud <- Some(n); *)
    end
  else ()
;;

  (* val freres : noeud -> noeud list
   * freres n renvoie les frères de n dont l'étiquette est non vide, sauf
   * si n est la racine de l'arbre, dans ce cas lève une exception
   *) 


(* let freres n =
 *   if n.prof = 0 then
 *     failwith "Le noeud est la racine"
 *   else let Some(parent) = n.parent in
 *     let Some(tab) = parent.fils in
 *     Array.fold_left (fun a x -> if x == n || x.etiq = None then a
 *                                 (\* == nécessaire, sinon pas assez de
 *                                  * mémoire, du coup on vérifie
 *                                  * simplement les addresses, il ne
 *                                  * devrait pas y avoir de pb *\)
 *                                 else x::a
 *       ) [] tab
 * ;; *)


  (* val norme_carre : vecteur -> float
   * norme x renvoie la norme 2 au carré de x
   *)

let norme_carre x =
  Array.fold_left (fun a x -> a +. (x*.x)) 0. x
;;


  (* val fg : float -> corps -> corps -> vecteur
   * fg g a b renvoie F_a/b, la force gravitationnelle exercée par le
   * corps a sur le corps b, avec la const grav univ g
   *)

let fg g a b =
  let u = a.pos -- b.pos in
  let d2 = norme_carre u in
  let theta = atan2 u.(1) u.(0) in
  (g *. a.mass *. b.mass /. d2) **. [| cos theta; sin theta |]
;;



  (* val fn : corps list -> vecteur array array
   * fn c renvoie la matrice f.(i).(j) des forces exercées par le
   * corps j sur le corps i
   *)

let fn (g, c) =
  let n = List.length c in
  let f = Array.make_matrix n n [|infinity; infinity|] in
  List.iteri (fun i ci ->
      List.iteri (fun j cj ->
          if f.(i).(j) = [|infinity; infinity|] then
            if i = j then f.(i).(j) <- [|0.; 0.|]
            else begin
                let force =  fg g cj ci in
                f.(i).(j) <- force;
                f.(j).(i) <- (-1.) **. force
              end
        ) c
    ) c;
  f
;;

type calc_acc = cond_init -> vecteur list
;;

type methode = (float * vecteur array list -> vecteur array list) ->
               float -> vecteur array list -> float ->
               (float * vecteur array list)
;;


  (* val calc_acc_naif : calc_acc 
   * calc_acc_naif (g, c) renvoie la liste des accélération des corps de c,
   * calculées naïvement, avec la const grav univ g
   *)


let calc_acc_naif (g, c) =
  let f = fn (g, c) in
  List.mapi (fun i x -> (1./.x.mass) **.
      Array.fold_left (fun a y -> a ++ y) [|0.;0.|] f.(i)
    ) c
;;

  (* val enveloppe_carre : corps list -> vecteur * vecteur
   * enveloppe_carre c renvoie le plus petit carre de l'espace
   * contenant tous les corps de c : [|xmin; xmax|], [|ymin; ymax|]
   *)


let enveloppe_carre c =
  let k::r = c in
  let x, y = [|k.pos.(0); k.pos.(0)|], [|k.pos.(1); k.pos.(1)|] in
  List.iter (fun k -> let [| xk; yk|] = k.pos in
                      if xk < x.(0) then
                        x.(0) <- xk;
                      if xk > x.(1) then
                        x.(1) <- xk;
                      if yk < y.(0) then
                        y.(0) <- yk;
                      if yk > y.(1) then
                        y.(1) <- yk;
    ) r;
  let dx = x.(1) -. x.(0) in
  let dy = y.(1) -. y.(0) in
  if dx > dy then
    begin
      y.(1) <- y.(1) +. ((dx -. dy)/.2.);
      y.(0) <- y.(0) -. ((dx -. dy)/.2.)
    end
  else
    begin
      x.(1) <- x.(1) +. ((dy -. dx)/.2.);
      x.(0) <- x.(0) -. ((dy -. dx)/.2.)
    end;
  x, y
;;


  (* val construit_arbre : corps list -> noeud
   * construit_arbre c construit l'arbre des corps de c, et renvoie la
   * racine 
   *)


let construit_arbre c =
  let x, y = enveloppe_carre c in
  let racine = { (* prof = 0; *)
                 etiq = None;
                 x = x;
                 y = y;
                 fils = None;
                 (* parent = None *)
               } in
  constr_arbre racine c;
  racine
;;



  (* val calc_acc_arbre : float -> calc_acc
   * idem que calc_acc_naif, mais par la méthode des arbres, avec le
   * paramètre theta
   *)


(* let calc_acc_arbre theta (g, c) =
 *   ignore(construit_arbre c);
 *   List.map (fun x ->
 *       let rec visite n =
 *         if n.fils = None ||
 *              let dist = sqrt (norme_carre (x.pos -- [|(n.x.(1)+.n.x.(0))
 *                                                       /.2.;
 *                                                       (n.y.(1)+.n.y.(0))
 *                                                       /.2.|] )) in
 *              let larg = n.x.(1) -. n.x.(0) in
 *              (larg /. dist) <= theta
 *         then
 *           let Some(y) = n.etiq in
 *           fg g y x
 *         else
 *           let Some(fils) = n.fils in
 *           Array.fold_left (fun a f -> if f.etiq <> None then
 *                                         a ++ (visite f)
 *                                       else a
 *             ) [|0.;0.|] fils
 *       in
 *       let rec somme s k =
 *         if k.prof = 0 then s
 *         else
 *           let freresk = freres k in
 *           let Some(parent) = k.parent in
 *           somme (List.fold_left (fun a f -> a ++ (visite f)) s freresk)
 *             parent
 *       in
 *       let Some(noeudx) = x.noeud in
 *       (1./.x.mass) **. (somme [|0.;0.|] noeudx)
 *     ) c
 * ;; *)

let calc_acc_arbre theta (g, c) =
  let racine = construit_arbre c in
  List.map (fun x ->
      let rec visite n =
        if n.fils = None ||
             let dist = sqrt (norme_carre (x.pos -- [|(n.x.(1)+.n.x.(0))
                                                      /.2.;
                                                      (n.y.(1)+.n.y.(0))
                                                      /.2.|] )) in
             let larg = n.x.(1) -. n.x.(0) in
             (larg /. dist) <= theta
        then
          let Some(y) = n.etiq in
          if y = x then [|0.; 0.|]
          else fg g y x
        else
          let Some(fils) = n.fils in
          Array.fold_left (fun a f -> if f.etiq <> None then
                                        a ++ (visite f)
                                      else a
            ) [|0.;0.|] fils
      in
      (1./.x.mass) **. (visite racine)
    ) c
;;




  (* val fonction : calc_acc -> cond_init  -> float * vecteur array
   * list -> vecteur array list 
   * fonction t y a c renvoie y', où y est la liste des tableaux
   * [|pos(n); vit(n)|] des corps de c à l'instant t, les accs
   * calculées avec a
   * f a c est la fonction donnée en argument à une méthode d'intégration
   *)

let fonction a (g, c) (t, y) =
  List.iter2 (fun x x' -> x.pos <- x'.(0)) c y;
  List.map2 (fun v acc -> [|v.(1); acc|]) y (a (g, c))
;;

  (* val euler/rk4 : methode
   * méthode d'intégration, assez explicite, non?
   *)

let euler f t y dt =
  t+.dt, List.map2 (fun x x' -> x +++ (dt *** x')) y (f (t, y))
;;

let rk4 f t y dt =
  let p1 = f (t, y) in
  let t2 = t +. dt/.2. in
  let y2 = List.map2 (fun x x' -> x +++ ((dt/.2.) *** x')) y p1 in
  let p2 = f (t2, y2) in
  let y3 = List.map2 (fun x x' -> x +++ ((dt/.2.) *** x')) y p2 in
  let p3 = f (t2, y3) in
  let t4 = t +. dt in
  let y4 = List.map2 (fun x x' -> x +++ (dt *** x')) y p3 in
  let p4 = f (t4, y4) in
  t4, list_map5 (fun x x1 x2 x3 x4 ->
          x +++ (dt *** (((1./.6.) *** (x1+++x4)) +++ ((1./.3.) *** (x2+++x3))))
        ) y p1 p2 p3 p4
;;

  
  (* val pb_n_corps : methode -> calc_acc -> cond_init -> float -> float ->
   * vecteur array list
   * pb_n_corpsf a c t dt renvoie la liste des positions successives
   * corps de c, intégrées par la méthode f, avec les accélérations
   * calculées par la méthode a
   *)

let pb_n_corps f a (g, c) t dt =
  let n = List.length c in
  let y0 = List.map (fun x -> [|x.pos; x.vit|]) c in
  let t0 = 0.0 in
  let pos0 = Array.make n [|nan; nan|] in
  List.iteri (fun i x ->
      pos0.(i) <- x.pos;
    ) c;
  (* f (fonction a c) t0 y0 dt renvoie (t1, y1) *)
  let l = List.init (int_of_float (t/.dt))
            (fun i -> (float_of_int i) *. dt) in
  let poss, tf, yf = List.fold_left (fun b x ->
                        let possn, tn, yn = b in
                        let tn1, yn1 = f (fonction a (g, c)) x yn dt in
                        List.iter2 (fun k v -> k.pos <- v.(0)) c yn1;
                        let posn1 = Array.make n [|nan; nan|] in
                        List.iteri (fun i k ->
                            posn1.(i) <- k.pos;
                          ) c;
                        posn1::possn, tn1, yn1
                      ) ([pos0], t0, y0) l in
  List.rev poss
;;



  (* conditions initiales *)

let conditions_initiales =
    let m0 = 5.972e24 in
    let m1 = 7.348e22 in
    let m2 = 5.000e5 in
    let pos0 = [|0.; 0.|] in
    let pos1 = [|3.844e8; 0.|] in
    let centre_grav = (1./.(m0+.m1)) **. ((m0**.pos0) ++ (m1**.pos1)) in
    let pos2 = [|(pos1.(0) +. centre_grav.(0))/.2.;
                 ((sqrt 3.)/.2.) *. (pos1.(0) -. centre_grav.(0))
               |] in
    let vit_y_1 = sqrt (g_norm *. (m0+.m1)/.pos1.(0)) in
    let vit0 = [|0.; -.(m1/.m0)*.vit_y_1|] in
    let vit1 = [|0.; vit_y_1|] in
    let vit2 = vit_y_1 **. [|-.(sqrt 3.)/.2.; 0.5|] in
    [|(g_norm,
     [{mass = m0; pos = pos0; vit = vit0; (* noeud = None *)};
      {mass = m1; pos = pos1; vit = vit1; (* noeud = None *)};
      {mass = m2; pos = pos2; vit = vit2; (* noeud = None *)}
     ]
    );
    (1. ,
     [{mass = 1.; pos = [|0.; 0.|]; vit = [|0.;0.|]; (* noeud = None *)};
      {mass = 1.; pos = [|1.; 0.|]; vit = [|0.;0.|]; (* noeud = None *)};
      {mass = 1.; pos = [|0.; 1.|]; vit = [|0.;0.|]; (* noeud = None *)};
      {mass = 1.; pos = [|-1.; 0.|]; vit = [|0.;0.|]; (* noeud = None *)};
      {mass = 1.; pos = [|0.; -1.|]; vit = [|0.;0.|]; (* noeud = None *)}
     ]
    )
  |]
;;

(* let conds = conditions_initiales.(int_of_string Sys.argv.(1))
 * 
 * let tests = pb_n_corps rk4 calc_acc_arbre conds (30.*.86400.) 60.
 * ;;
 * 
 * 
 *)
  

  (* int -> int -> float * Tipe.corps lsit 
   * lit le fichier conds/rand_condsi_n_corps.dat, contenant des conditions initiales
   * formatées, et crée la liste des corps correspondante
   *)


let read_input n i =
  let ic = open_in ("conds/rand_conds"^(string_of_int i)^"_"
                    ^(string_of_int n)^"_corps.dat") in
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
;;


