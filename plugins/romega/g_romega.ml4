(*************************************************************************

   PROJET RNRT Calife - 2001
   Author: Pierre Crégut - France Télécom R&D
   Licence : LGPL version 2.1

 *************************************************************************)

(*i camlp4deps: "grammar/grammar.cma" i*)

DECLARE PLUGIN "romega_plugin"

open Ltac_plugin
open Names
open Refl_omega
open Stdarg

let eval_tactic name =
  let dp = DirPath.make (List.map Id.of_string ["PreOmega"; "omega"; "Coq"]) in
  let kn = KerName.make2 (MPfile dp) (Label.make name) in
  let tac = Tacenv.interp_ltac kn in
  Tacinterp.eval_tactic tac

let romega_tactic unsafe l =
  let tacs = List.map
    (function
       | "nat" -> eval_tactic "zify_nat"
       | "positive" -> eval_tactic "zify_positive"
       | "N" -> eval_tactic "zify_N"
       | "Z" -> eval_tactic "zify_op"
       | s -> CErrors.user_err Pp.(str ("No ROmega knowledge base for type "^s)))
    (Util.List.sort_uniquize String.compare l)
  in
  Tacticals.New.tclTHEN
    (Tacticals.New.tclREPEAT (Proofview.tclPROGRESS (Tacticals.New.tclTHENLIST tacs)))
    (Tacticals.New.tclTHEN
       (* because of the contradiction process in (r)omega,
          we'd better leave as little as possible in the conclusion,
          for an easier decidability argument. *)
       (Tactics.intros)
       (total_reflexive_omega_tactic unsafe))

TACTIC EXTEND romega
|  [ "romega" ] -> [ romega_tactic false [] ]
|  [ "unsafe_romega" ] -> [ romega_tactic true [] ]
END

TACTIC EXTEND romega'
| [ "romega" "with" ne_ident_list(l) ] ->
    [ romega_tactic false (List.map Names.Id.to_string l) ]
| [ "romega" "with" "*" ] -> [ romega_tactic false ["nat";"positive";"N";"Z"] ]
END
