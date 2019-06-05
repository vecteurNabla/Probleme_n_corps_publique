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
   }
;;

type cond_init = float * corps list
;;


val g_norm : float
;;

val g_1 : float
;;

val ( -- ) : vecteur -> vecteur -> vecteur
;;
(** soustraction sur R^2*)

val norme_carre : vecteur -> float
;;
(** renvoie la norme 2 au carré de l'argument*)

type calc_acc = cond_init -> vecteur list
;;

val calc_acc_naif : calc_acc;;

(** calc_acc_naif (g, c) renvoie la liste des accélération des corps de c,
    calculées naïvement, avec la const grav univ g *)

val construit_arbre : corps list -> noeud
;;
(** juste pour lest tests, ne pas utiliser sinon *)

val calc_acc_arbre : float -> calc_acc;;

(* val calc_acc_arbre_2 : float -> calc_acc;; *)

(** idem que calc_acc_naif, mais par la méthode des arbres *)

type methode = (float * vecteur array list -> vecteur array list) ->
               float -> vecteur array list -> float ->
               (float * vecteur array list)
;;

val euler : methode;;

val rk4 : methode;;

(** les méthodes d'intégration, à donner à pb_n_corps *)


val pb_n_corps : methode -> calc_acc -> cond_init -> float -> float ->
                 vecteur array list
;;

(** pb_n_corpsf a c t dt renvoie la liste des positions successives
    corps de c, intégrées par la méthode f, avec les accélérations
    calculées par la méthode a *)
