# Idea Lenses

Use these lenses when recent notes are technical, fragmented, or overly local.
Do not force every lens. Pick the few that create the strongest questions.

## 1. Mismatch lenses

Look for two things that should align but do not:

- training loss versus downstream scientific quantity
- surrogate target versus true mechanism
- sampler behavior versus inference-time objective
- local metric improvement versus end-to-end utility
- structure quality versus thermodynamic consistency

Question pattern:

- What is being optimized locally that may be wrong globally?
- Can the mismatch itself be measured, bounded, or turned into a new objective?

## 2. Failure-mode lenses

Mine notes for recurring breakdowns:

- instability
- rare-event dependence
- overlap collapse
- calibration failure
- mode dropping
- hidden assumptions about geometry, symmetry, or data coverage

Question pattern:

- Can the failure mode become the object of study instead of a nuisance?
- What observable would tell us when the method is about to fail?

## 3. Transfer lenses

Bridge ideas across notes that currently live in different vocabularies:

- transport ideas into generative modeling
- estimator thinking into diffusion training
- free-energy intuition into docking or co-folding objectives
- geometric constraints into sampling diagnostics

Question pattern:

- Which concept in note A solves the bottleneck described in note B?
- Is the transfer exact, approximate, or only metaphorical?

## 4. Missing-measurement lenses

Look for quantities the notes care about but never compute directly:

- uncertainty
- overlap
- effective sample size
- path consistency
- calibration
- binding or stability proxies with no thermodynamic interpretation

Question pattern:

- What latent quantity is driving decisions without being measured?
- Can a cheap proxy be derived and checked before committing to a full method?

## 5. Boundary-condition lenses

Search for places where the method may only work in a narrow regime:

- small perturbations
- similar scaffolds
- fixed binding mode assumptions
- short denoising horizons
- equilibrium-like behavior

Question pattern:

- Where is the regime boundary?
- Can the boundary be detected or predicted from note-level signals?

## 6. Composition lenses

Many research problems are pipeline problems, not single-model problems.
Inspect how interfaces behave:

- generator to scorer
- docking to refinement
- fold prediction to free-energy estimation
- coarse proposal to expensive reranker

Question pattern:

- Which stage creates the most irreversible information loss?
- Can uncertainty from one stage be passed into the next instead of discarded?

## 7. Scientific-value lenses

Prefer questions that would matter even if the first implementation fails:

- clearer theory
- better diagnostics
- sharper benchmark definitions
- a principled negative result
- a reusable decomposition of the problem

Question pattern:

- If the main idea fails, what artifact still advances understanding?

## AI4Science prompts

Use these prompts when the notes are about molecular modeling, docking,
co-folding, or generative modeling:

- Which learned score is pretending to be a thermodynamic quantity?
- Where does a geometric success metric fail to predict scientific utility?
- Which uncertainty matters for triage but is not exposed by the current model?
- Can a transport or bridge view reduce variance in a downstream estimator?
- Where is the method relying on hidden alignment between train and deployment?
- Which benchmark slice would most likely falsify the current story?
