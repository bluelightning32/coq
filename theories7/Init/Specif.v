(***********************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team    *)
(* <O___,, *        INRIA-Rocquencourt  &  LRI-CNRS-Orsay              *)
(*   \VV/  *************************************************************)
(*    //   *      This file is distributed under the terms of the      *)
(*         *       GNU Lesser General Public License Version 2.1       *)
(***********************************************************************)

(*i $Id$ i*)

Set Implicit Arguments.
V7only [Unset Implicit Arguments.].

(** Basic specifications : Sets containing logical information *)

Require Notations.
Require Datatypes.
Require Logic.

(** Subsets *)

(** [(sig A P)], or more suggestively [{x:A | (P x)}], denotes the subset 
    of elements of the Set [A] which satisfy the predicate [P].
    Similarly [(sig2 A P Q)], or [{x:A | (P x) & (Q x)}], denotes the subset 
    of elements of the Set [A] which satisfy both [P] and [Q]. *)

Inductive sig [A:Set;P:A->Prop] : Set
    := exist : (x:A)(P x) -> (sig A P).

Inductive sig2 [A:Set;P,Q:A->Prop] : Set
    := exist2 : (x:A)(P x) -> (Q x) -> (sig2 A P Q).

(** [(sigS A P)], or more suggestively [{x:A & (P x)}], is a subtle variant
    of subset where [P] is now of type [Set].
    Similarly for [(sigS2 A P Q)], also written [{x:A & (P x) & (Q x)}]. *)
     
Inductive sigS [A:Set;P:A->Set] : Set
    := existS : (x:A)(P x) -> (sigS A P).

Inductive sigS2 [A:Set;P,Q:A->Set] : Set
    := existS2 : (x:A)(P x) -> (Q x) -> (sigS2 A P Q).

Arguments Scope sig [type_scope type_scope].
Arguments Scope sig2 [type_scope type_scope type_scope].
Arguments Scope sigS [type_scope type_scope].
Arguments Scope sigS2 [type_scope type_scope type_scope].

Notation "{ x : A  |  P }" := (sig A [x:A]P) : type_scope.
Notation "{ x : A  |  P  &  Q }" := (sig2 A [x:A]P [x:A]Q) : type_scope.
Notation "{ x : A  &  P }" := (sigS A [x:A]P) : type_scope.
Notation "{ x : A  &  P  &  Q }" := (sigS2 A [x:A]P [x:A]Q) : type_scope.

Add Printing Let sig.
Add Printing Let sig2.
Add Printing Let sigS.
Add Printing Let sigS2.


(** Projections of sig *)

Section Subset_projections.

  Variable A:Set.
  Variable P:A->Prop.

  Definition proj1_sig :=
   [e:(sig A P)]Cases e of (exist a b) => a  end.

  Definition proj2_sig :=
   [e:(sig A P)]
     <[e:(sig A P)](P (proj1_sig e))>Cases e of (exist a b) => b  end.

End Subset_projections.


(** Projections of sigS *)

Section Projections.

  Variable A:Set.
  Variable P:A->Set.

 (** An element [y] of a subset [{x:A & (P x)}] is the pair of an [a] of 
     type [A] and of a proof [h] that [a] satisfies [P].
     Then [(projS1 y)] is the witness [a]
     and [(projS2 y)] is the proof of [(P a)] *)

  Definition projS1 : (sigS A P) -> A
           := [x:(sigS A P)]Cases x of (existS a _) => a end.
  Definition projS2 : (x:(sigS A P))(P (projS1 x))
           := [x:(sigS A P)]<[x:(sigS A P)](P (projS1 x))> 
                  Cases x of (existS _ h) => h end.

End Projections.


(** Extended_booleans *)

Inductive sumbool [A,B:Prop] : Set
    := left  : A -> {A}+{B}
     | right : B -> {A}+{B}

where "{ A } + { B }" := (sumbool A B) : type_scope.

Inductive sumor [A:Set;B:Prop] : Set
    := inleft  : A -> A+{B}
     | inright : B -> A+{B}

where "A + { B }" := (sumor A B) : type_scope.

(** Choice *)

Section Choice_lemmas.

  (** The following lemmas state various forms of the axiom of choice *)

  Variables S,S':Set.
  Variable R:S->S'->Prop.
  Variable R':S->S'->Set.
  Variables R1,R2 :S->Prop.

  Lemma Choice : ((x:S)(sig ? [y:S'](R x y))) ->
                     (sig ? [f:S->S'](z:S)(R z (f z))).
  Proof.
   Intro H.
   Exists [z:S]Cases (H z) of (exist y _) => y end.
   Intro z; NewDestruct (H z); Trivial.
  Qed.

  Lemma Choice2 : ((x:S)(sigS ? [y:S'](R' x y))) ->
                     (sigS ? [f:S->S'](z:S)(R' z (f z))).
  Proof.
    Intro H.
    Exists [z:S]Cases (H z) of (existS y _) => y end.
    Intro z; NewDestruct (H z); Trivial.
  Qed.

  Lemma bool_choice : 
    ((x:S)(sumbool (R1 x) (R2 x))) ->
    (sig ? [f:S->bool] (x:S)( ((f x)=true  /\ (R1 x)) 
                           \/ ((f x)=false /\ (R2 x)))).
  Proof.
    Intro H.
    Exists [z:S]Cases (H z) of (left _) => true | (right _) => false end.
    Intro z; NewDestruct (H z); Auto.
  Qed.

End Choice_lemmas.

 (** A result of type [(Exc A)] is either a normal value of type [A] or 
     an [error] :
     [Inductive Exc [A:Set] : Set := value : A->(Exc A) | error : (Exc A)]
     it is implemented using the option type. *) 

Definition Exc := option.
Definition value := Some.
Definition error := !None.

Implicits error [1].

Definition except := False_rec. (* for compatibility with previous versions *)

Implicits except [1].

V7only [
Notation Except := (!except ?) (only parsing).
Notation Error := (!error ?) (only parsing).
V7only [Implicits error [].].
V7only [Implicits except [].].
].
Theorem absurd_set : (A:Prop)(C:Set)A->(~A)->C.
Proof.
  Intros A C h1 h2.
  Apply False_rec.
  Apply (h2 h1).
Qed.

Hints Resolve left right inleft inright : core v62.

(** Sigma Type at Type level [sigT] *)

Inductive sigT [A:Type;P:A->Type] : Type
    := existT : (x:A)(P x) -> (sigT A P).

Section projections_sigT.

  Variable A:Type.
  Variable P:A->Type.

  Definition projT1 : (sigT A P) -> A
              := [H:(sigT A P)]Cases H of (existT x _) => x end.
   
  Definition projT2 : (x:(sigT A P))(P (projT1 x))
              := [H:(sigT A P)]<[H:(sigT A P)](P (projT1 H))> 
                     Cases H of (existT x h) => h end.

End projections_sigT.

V7only [
Notation ProjS1 := (projS1 ? ?).
Notation ProjS2 := (projS2 ? ?).
Notation Value := (value ?).
].
