(This is a stream of consciousness working toward an idea of what "mediary" rules for a weak omega-category would be like.)

---

The Kan filler rules for opetopic weak omega-categories can be broken up like this:

1. Given all the source cells, get at least one target cell.

2. Given all the source cells and proofs that they're universal, get proofs that all the target cells made from them are universal.

3. Given all the source cells, get at least one pair of a filler cell and a proof that it's universal.

4. Given the target cell, all but one source cell, and proofs that the given source cells are universal, get at least one compatible source cell.

5. Given the target cell, all but one source cell, and proofs that all the given cells are universal, get proofs that all the compatible source cells made from them are universal.

6. Given the target cell, all but one source cell, and proofs that the given source cells are universal, get at least one pair of a filler cell and a proof that it's universal.

---

We can coalesce rules 1, 2, 4, and 5 again into a single rule:

7. Given a filler cell, a proof that it's universal, and proofs that all but one of its source and target cells are universal, get a proof that its remaining source or target cell is universal.

---

This leaves rules 3, 6, and 7. Rule 3 lets us form compositions, rule 6 lets us have units for that composition (and know that the composition rules are themselves units), and rule 7 lets units preserve units.

In Lathe Morphisms, we're coining the term "mediary" to refer to systems that are like the systems the calculus of structures literature refers to as "local," but with the atomic rules excluded. A mediary system doesn't necessarily have composition units for every atom (like the ability to derive a formula from itself, or the introduction or cut rule for a formula); instead, when we discuss an atom, we usually assume that atom comes with instances of the atomic rules.

What would a "mediary" opetopic omega-category look like?

I'm thinking it would treat rule 6 as something not all atoms have. In the case of rule 6, the "atom" is both the given target cell and the obtained source cell.

Hmm, we might also be able to localize rule 7. How about this breakdown:

Mediary (a system consisting of one rule): Given all the source cells, get at least one collection of a filler cell, a proof that it's universal and well-behaved, and a proof that the target cell is well-behaved if the source cells are well-behaved.

Atomic (a definition): A cell A is well-behaved if, given A as a target cell, given all but one source cell, and given proofs that the given source cells are universal, we get at least one collection of a filler cell, a proof that it's universal, and a proof that its inferred source cell is universal if and only if A is universal. (Do we also need a proof that the inferred source cell is well-behaved?)

Hmm, suppose in these rules, "cell" really means "maximal set of mutually isomorphic cells." Then compositions are unique (which might be a way to approach Simpson's conjecture?) and we can define that a cell is "universal" if it's "equal to the composition of its source cells." Then we have:

Mediary (a system consisting of one rule): Given all the source cells, get a filler cell (called their composition witness), a proof that it's well-behaved, and a proof that its target cell (called their composition) is well-behaved if the source cells are well-behaved.

Atomic (a definition): A cell A is well-behaved if, given A as a target cell and given a composition witnesses in all but one source cell, we get a composition witness as a filler and a proof that its inferred source cell is a composition witness if and only if A is a composition witness. (Do we also need a proof that the inferred source cell is well-behaved?)

Hmm, we can settle the question "Do we also need a proof that the inferred source cell is well-behaved?" pretty decisively if we make another change to how we interpret these rules: Instead of a cell just being a maximal set of isomorphic cells *of a single opetopic shape*, it's a maximal set of isomorphic cells *of various opetopic shapes*. Then we have:

Mediary (a system of rules): The identity is a well-behaved cell. Given a region with a complete set of source cell fillers, there's a target cell filler (called their composition) such that the identity fills the region. A composition is well-behaved if the source cells are well-behaved (TODO: Is this a theorem?). (NOTE: Any composition of zero source cells is the identity, so we could define the identity that way rather than introducing it explicitly.)

Atomic (a definition): A cell A is well-behaved if, given a region with A filling a target cell and the identity filling all but one source cell, A fills the remaining source cell, and the identity fills the overall region.

And we have that if the identity fills a region where at least all but one of the source cells are filled by the identity, then whatever fills the target cell is equal to whatever fills the remaining source cell. (TODO: Is this enough to define equality on cells?)

If all the cells we deal with are well-behaved, then I think we can show they all fill globular (rather than merely opetopic) regions by repeatedly factoring out the opetopic shapes using the "well-behaved" definition (an argument that amounts to the same thing as the argument described in "an illustrated guide" for opetopic bicategories). If it's possible they're not all well-behaved, then we can still work with them in the generality of opetopic cells. In this case we'll tend to postulate rules that make the cells continue to be interesting in some other way.

---

## Opetopic (omega + 1)-categories?

It seems this formulation of opetopic omega-category can bring us to a concept for an opetopic (omega + 1)-category: We're dealing with equalities again (between maximal sets of isomorphic cells), and the only thing in the core system that constructs the things we're stating equalities between (those sets) is a composition function. So instead of relying on these equalities to be strict, we can potentially express them like opetopes all over again.

Hmm, but we're also dealing with another relation: Filling. In the statement "A fills the region B," A is a cell (or more precisely a maximal set of mutually isomorphic cells), and B is a bunch of source cells and a target cell. (The idea that B is a region does not implicitly state that its source cells and target cell are all compatible. We could do that and make A just another cell to call compatible with the rest, but then filling would be a statement of the form "A is a recursively labeled opetope where every pair of labels that must be compatible are equal, and every face locally fills the region bounding it," but then this notion of "locally fills" would be what we're talking about right now.)

We can state the filling relation in a way that relies on source and target maps and the fact that we're actually dealing with maximal sets of mutually isomorphic cells: "A fills the region B" could mean "there exists an x in A such that the target cell of x is in the target cell-set of B, etc." or even "there exists an x in A such that the target cell of x is equal to the target cell of B, etc." However, treating the filling relation as something foundational seems more likely to bring us to a relatively simple concept of (omega + 1)-category.

Ah... how about this: From a cell-set A, we can get its region-set (essentially mapping over it and taking all the targets and sources and discarding the interiors). Then we can turn around "A fills the region B" into "B is in the region-set of A" or even "B is a subset of the region-set of A." It seems region-sets are probably constructible by composition as well, such that "the region set of the composition of ..." can always be rephrased as "the composition of the region-sets of ...," but that's not the only way they're constructed: They're also constructed by restricting the target cell(-set) of another region-set.

Hmm. Even if we could figure out laws for "restricting the target cell(-set) of a region-set," the fact we're stating subset relations between region-sets instead of equality relations means we may have to witness these relations using computads rather than opetopes. (Could we witness them with pairs of opetopes where one is monomorphic, like the way anafunctors are represented?)

Seems we haven't really arrived at a particular concept of (omega + 1)-category, huh?

Well, if we give up on expressing the filling relation in terms of higher-dimensional cells, we can at least eliminate the equality relation by expressing "A equals B" as "the identity fills the region with target A and a single source B." (Hmm, unless we don't know what shape to make that region, like what lower-dimensional cells it should have.)

On the other hand, in "A fills the region B," we don't have to allow any of the cell-sets (A or the target or sources of B) to be compositions if we have opetopic composition-equality relations. So maybe all the higher-dimensional witnesses ((omega + 1)-opetopes) we need are the equality witnesses for every existing dimension (finite-dimensional opetopes), as well as filling witnesses for every existing dimension of region (which are also shaped nearly like finite-dimensional opetopes). This suggests we might care about multiple "ways" a cell fills a region, and that these "ways" should be compatible with the "ways" the sources and target of a composition-shaped cell interact when they're not just being composed.

Hmm, those filling-shaped cells can compose with each other like this: Given a composition-shaped cell and several filling-shaped cells of the appropriate shapes at its source cells, such that their regions' source and target cells are equal with each other at the boundaries, we get another where the region is replaced with the exterior of the original regions and the instance of that region is replaced with a cell that's equal to the given composition-shaped cell composed with all the filling-shaped cells' instance cells. Could this composition law exemplify one of the possible new shapes of an (omega + 2)-opetope? And then of course we can say a filling-shaped cell is well-behaved if it factors out into a composition like this where all the source filling-shaped cells are filled by the identity.

This suggests the identity can fill a *filling-shaped region*. Seems like the witness of that filling is another (omega + 2)-opetope.

Ooh, we can take advantage of the interpretation of "A equals B" as "the identity fills the region with target A and a single source B" to express all the composition-shaped cells as filling-shaped cells. Wait, but they still need to be fillings of composition-shaped regions to do that, so we will want composition-shaped cells in the first place to begin the process.

[BEGIN final system considered in this file]

Mediary (a system of rules): The identity is a well-behaved cell. Given a composition-shaped region with a complete set of source cell fillers, there's a target cell filler (called the source cells' composition) such that the identity fills the region. A composition is well-behaved if the source cells are well-behaved (TODO: Is this a theorem?). A cell fills a region of boundary cells if and only if the identity fills a filling-shaped region made up of that instance cell and boundary cells. (NOTE: Any composition of zero source cells is the identity, so we could define the identity that way rather than introducing it explicitly.)

Atomic (a definition): A cell A is well-behaved if, given a composition-shaped region with A filling a target cell and the identity filling all but one source cell, A fills the remaining source cell, and the identity fills the overall region.

[END final system considered in this file]

A composition-shaped cell can be a composition of composition-shaped cells or a composition of a single composition-shaped cell with several filling-shaped cells. A filling-shaped cell can be a filling of a composition-shaped region or a filling-shaped region. There's little reason to ascribe these to a particular linear sequence of dimension numbers; the first omega dimensions could be compositions, or we could put fillings of dimension-0 compositions at dimension 1 and so on.

But suppose we do put every shape of cell at the first dimension it makes sense for it to exist at. *Then* do we get a notion of (omega + 1)-category? Seems like we might! An (omega + 1)-dimensional composition-shaped cell could be a composition of (... (compositions of (compositions of (fillings of (compositions of (fillings of (fillings of (dimension-0 compositions)))))))), for an omega-sized (and possibly irrational) sequence of "compositions of" and "fillings of," with omega's potential infinity occurring at the *beginning* (right after the first "composition of" that marks the dimension (omega + 1)). Likewise, an (omega + 1)-dimensional filling-shaped cell would be a filling of (...).

But does it really make sense to have this potential infinity at the beginning? The laws we've expressed let us find a composition of one or more (N + 1)-cells if their N-cells are compatible, so nonzero compositions are only well defined at successor ordinals; we don't really have omega-compositions to speak of.

At least limit ordinal filler-shaped cells make sense: We can represent an ordinal-sized sequence of "filler of" simply by having an ordinal-sized sequence of instance cells. And a composition of these makes sense, because it only has to operate on the *innermost* instance cells.

But wait... If nothing ever composes instance cells of dimension greater than omega, then it doesn't make sense to keep track of them. So we really don't have a use for (omega + 1)-cells after all.

We seem to have generalized from the standard opetopic omega-categories, which have an "X is a universal cell" predicate, to a notion of category with only one predicate, "A fills the region B," that is itself equivalent to "the identity cell fills the filler-shaped region with instance cell A and region cells B." Every predicate is equivalent to the existence of a witnessing cell (in fact, always the identity cell), and the generalization is that we can now have some filling-shaped cells that are not the identity (and moreover some that are not even well-behaved).

From here... we could demand that the classical logic formulas "P and Q," "not P," and "forall x. P" are also equivalent to the existence of witnessing cells built up out of the witnessing cells of P and Q. If we manage that, we won't necessarily stop using classical logic, but the fact that we use classical logic will not add to the expressiveness of the foundation.

But, eh, classical logic is pretty well justified. It's a logic that lets us find no-go theorems. Our foundation should probably be:

* Constructive reasoning (and especially ultrafinitary reasoning) as a way to building things like runnable computer programs and utterable proofs of theorems. Rather than always having to formalizing what "ultrafinitary" means, it's all right if we let it vary based on the practical capabilities of the host programming language and the patience of the people using it.

* Classical logic as a way of expressing no-go theorems. (Note that by using a formalization of the ultrafinitary reasoning level, we can use classical logic to express no-go theorems about the ultrafinitary level which will be informative to anyone working at that level who's willing to believe the formalization is correct.)

* Weak omega-category theory as a facilitating tool for transporting results between different formal theories and studying the transportation processes' properties. Theories can be expressed by postulating the existence of opetopic cells, like a 1-cell for each type of formula or expression; a 2-cell for each logical connective, predicate, or function; and a 3-cell for each inference rule. (This will often be useful for translating general results to be in or about the particular kind of ultrafinitary reasoning that's most applicable to the work at hand.)

---

Takeaway:

Let's build basic tools for constructive and classical reasoning, and on top of that, let's build the system expressed in between "[BEGIN final system considered in this file]" and "[END final system considered in this file]".
