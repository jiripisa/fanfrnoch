# Synthesis methods and prior art for friction drums (cuíca, rommelpot, fanfrnoch, lion's roar) and friction-excited sounds

Evidence labels used throughout: **[measured]** = reported measurement or observed output; **[authors]** = authors' interpretation or judgement; **[claimed]** = vendor/marketing or unverified claim; **[derived]** = my own calculation or reasoning from the cited material. Reading depth: **(full)** = full text or source code read; **(code)** = source code read directly from a cloned repository; **(abstract)** / **(snippet)** = only abstract, search-result text, or a page summary.

Source repositories cloned and read on 2026-11-23: SDT `SkAT-VG/SDT` branch `main` @0509de4; STK `thestk/stk` `master` @6aacd35; Faust libraries `grame-cncm/faustlibraries` `master` @cd7555d; Mutable Instruments `pichenettes/eurorack` `master` @f4cfa76.

---

## Q1. Physical models of friction and how a friction exciter couples to membrane modes and a cavity; published friction-drum / cuíca models

### Takeaway
There is exactly one published physical model of a friction drum that I could find: Onofrei, Willemsen & Serafin (DAFx20in21). It couples an FDTD membrane and an FDTD 1-D tube and bows the membrane with a Dupont-style elasto-plastic friction model solved by Newton–Raphson. It runs in real time as a single sustained "bowed" voice, but it costs one to two orders of magnitude more than the per-voice budget, and its informal evaluation did not show that listeners recognise a friction drum. The cheaper building blocks are well documented and open source: the SDT elasto-plastic interactor driving a modal resonator (GPL), and STK, Elements and Faust bow tables or friction curves driving banded waveguides or modes (MIT-style or LGPL with an exception). A friction-drum model would have to assemble these itself; nobody has published one built this way.

### Cited Findings

**The only published friction-drum physical model: Onofrei, Willemsen, Serafin, "Real-time implementation of a friction drum inspired instrument using finite difference schemes", DAFx20in21 (full text read)** — [DAFx archive PDF](https://www.dafx.de/paper-archive/2021/proceedings/papers/DAFx20in21_paper_32.pdf); also [IEEE Xplore](https://ieeexplore.ieee.org/document/9768291/)
- Structure: "models such an instrument as a bowed membrane connected to an acoustic tube ... using finite-difference time-domain (FDTD) methods in which the excitation, whose position is free to change in real-time, is modelled by a highly non-linear elasto-plastic friction model." **[authors]**
- Simplification relevant to us: "we consider the stick as an infinitely long bow that excites the membrane directly via frictional interaction. This allows for an output sound sustained indefinitely. Therefore our virtual instrument does not necessarily sound identical 'out of the box' compared to either of the real friction drums." The authors also note that real friction drums, because "the stick is of limited length", "are typically used for percussive sounds, characterised by a sharp attack". **[authors]**
- Membrane PDE: ∂²u/∂t² = c²Δu − 2σ0 ∂u/∂t + 2σ1 Δ∂u/∂t (+ connection force and bow force terms), with Dirichlet boundary conditions. The circle is "sculpted" from a square grid with a staircase approximation. **[authors]**
- Tube: 1-D wave equation, Neumann boundary at the membrane end and a radiating boundary at the open end (∂χζ = −α1 ∂tζ − α2 ζ). The authors admit: "This 1D wave approximation ... will actually not produce the desired 'drum' type sound for the wave speed γ resulting from the bulk modulus and density of air. However, this value can be tuned". They set γ = 30 m/s instead of about 343 m/s. **[authors]**
- Membrane–tube coupling: a rigid connection. The membrane displacement is weighted by "a 2D Hann distribution over 72.25% of the area of the grid ... centered at the middle", justified by "the boundary layer effect". On the tube side the weighting is a half-Hann window over 4% of the tube length, which "dampen[s] out some of the high frequencies". **[authors]**
- Friction force: f_B = s0·z + s1·ż + s2·v + s3·w, with ż = v(1 − α(v,z)·z/z_ss(v)) and z_ss(v) = sgn(v)[F_C + (F_S − F_C)e^{−(v/v_S)²}]/s0. The adhesion map α is a raised sine between z_ba and z_ss, and w is a noise term "as per [Serafin thesis]". **[authors]**
- Solver: the unknowns v, z and f_c are found per sample by a 3×3 multivariate Newton–Raphson. "The threshold for convergence is set at 10⁻⁷, with a maximum number of iterations of 99." **[authors]**
- Parameters (Table 1) **[authors]**:
  - Membrane: 0.3 × 0.3 m, ρm = 1400 kg/m³, H = 0.007 m, c = 15–150 m/s ("Tuning" slider), σ0 = 0–6 s⁻¹, σ1 = 0–0.0026 m²/s, grid spacing hm = 0.0167 m.
  - Tube: L = 0.4 m, A = 0.0707 m², γ = 30 m/s, α1 = 0.008, α2 = 4.348, ht = 0.0011 m.
  - Bowing: µC = 0.3, µS = 0.8, fN = 0–20 N, vB = 0–0.2 m/s, vS = 0.1 m/s, s0 = 10⁵ N/m, s1 = 0.001·√s0, s2 = 4, s3 = 0–0.04·fN ("Noise" slider), z_ba = 0.7·F_C/s0.
  - Sample rate 44.1 kHz.
- Cost: "The number of grid intervals in the discretization of both elements is limited as compared to the stability condition in order for the model to be able to run in real-time without audio dropouts." The paper reports no CPU figures. **[authors]**
- Output and behaviour: they "observe Helmholtz motion" at the bow point and a "hysteresis loop in the force vs. relative velocity plane", in line with Smith & Woodhouse. **[measured, in simulation]**
- Controller: a Sensel Morph. Pressure is mapped "to the bowing force and velocity, linearly coupled", and x/y to the bow position. A vibrato LFO modulates c ("Variation" 0–3 m/s, "Rate" 0–10 Hz). **[authors]**
- Realism evaluation: an informal Zoom demo for 17 students. Asked "which instrument it was, the answers were varied ... Theremin, ... gong, hand drum, metallic drum, bowed bar, low frequency saw, a cymbal that is 'contact-miced' and bowed or even 'a chair being dragged across the floor'". "An important addition to the evaluation would be an objective comparison with the sound produced by various real friction drums." No such comparison was made. **[measured (informal) + authors]**
- Code: implemented in C++/JUCE, with a demo video at https://www.youtube.com/watch?v=3UEUyYc6PF0. I found no public code repository. **[authors]**
- Paper licence: CC BY 3.0. **[authors]**

**Elasto-plastic friction lineage (SDT / Avanzini, Serafin, Rocchesso)**
- DAFx 2002, "Modeling Interactions between Rubbed Dry Surfaces Using an Elasto-Plastic Friction Model": the paper "reviews a number of static and dynamic friction models, and discusses numerical techniques for the accurate and efficient numerical implementation of a dynamic elasto-plastic model" **(abstract)** — [DAFx archive](https://dafx.de/paper-archive/details/WJyFGe3ntpjR8BhNqTYFLA)
- Avanzini, Serafin, Rocchesso, IEEE Trans. Speech & Audio Proc. 13(5), 2005, "Interactive simulation of rigid body interaction with friction-induced sound generation". It combines an elasto-plastic friction model with modal synthesis and reports the model "is successful in reproducing several salient everyday sound phenomena, such as rubbing, braking, and squeaky doors" **(snippet, [authors])** — [typeset.io copy](https://typeset.io/pdf/interactive-simulation-of-rigid-body-interaction-with-3k3oo568e2.pdf)
- Serafin, Avanzini, Rocchesso, SMAC 2003, "Bowed string simulation using an elasto-plastic friction model". It applies the model to a digital-waveguide bowed string and addresses the drift problem of the LuGre model **(abstract/snippet)** — [unimi repository](https://air.unimi.it/retrieve/dfa8b99e-e58d-748b-e053-3a05fe0a3a96/serafin_smac03.pdf); [academia.edu](https://www.academia.edu/749820/Bowed_string_simulation_using_an_elasto_plastic_friction_model). My direct download returned an HTML page, not the PDF.
- Willemsen, Bilbao, Serafin, DAFx 2019: a real-time elasto-plastic bowed stiff string with FDTD **(snippet)** — [AAU PDF](https://vbn.aau.dk/files/310482246/DAFx2019Willemsen.pdf)
- Serafin et al. (co-authors not verified), NIME 2004, "Toward a generalized friction controller". It covers case studies of "the musical saw, Tibetan singing bow, glass harmonica, and bowed cymbal", which "produce sound by rubbing a hard object" on the instrument, and proposes a "generalized friction controller". It does not mention friction drums. **(abstract)** — [NIME](https://nime.org/proc/nime2004_serafin/), [PDF](https://nime.org/proceedings/2004/nime2004_108.pdf)

**SDT source code: what the current friction model actually computes (code)** — [SDTInteractors.c](https://github.com/SkAT-VG/SDT/blob/main/src/SDT/SDTInteractors.c), [SDTResonators.c](https://github.com/SkAT-VG/SDT/blob/main/src/SDT/SDTResonators.c)
- State is `fn, vs, ks, kd, kba, s0, s1, s2, s3, fs, fc, z`. Defaults: vs = 0.1, ks = 0.8, kd = 0.2, kba = 0.1, s0 = 1000, s1 = 10, s2 = 10, s3 = 0.5. **(code)**
- `SDTFriction_ElastoPlastic()` computes:
  - the relative velocity v of the two resonators at their contact points;
  - z_ss = sgn(v)(fc + (fs − fc)·exp(−(v/vs)²))/s0 and z_ba = sgn(v)·kba·fc/s0;
  - α = 0 when sgn(v) ≠ sgn(z) or |z| < |z_ba|, the raised sine 0.5 + 0.5·sin(π(z − ½(zss + zba))/(zss − zba)) in the transition band, and 1 above it;
  - dz = v(1 − α·z/zss);
  - noise w = whiteNoise·√(|v|·fn);
  - f = s0·z + s1·dz + s2·v + s3·w, then z += dz·Δt.

  This is an explicit, single-pass, non-iterative update: one `exp`, at most one `sin`, one `sqrt` and one noise sample per sample. **(code)**
- Coupling: `SDTInteractor_dsp()` applies the force f to object 0 and −f to object 1 at their contact points, then steps both resonators. Each output pickup is a modal position. **(code)**
- The modal resonator is an exact-discretised mass–spring–damper per mode:
  - coefficients b1 = r·sinc(ωT)·T²/m, a1 = −2r·cos(ωT), a2 = r², with r = exp(−2T/decay);
  - per sample: p = b1·f − a1·p0 − a2·p1, then v = b0v·p + b1v·p0;
  - the input force is split over modes in proportion to per-pickup gains.

  The model is double precision. Each mode has frequency, decay and "weight" (inverse modal mass), and a "fragmentSize" parameter scales them all together. **(code)**
- Note: the earlier papers (2002–2005) describe a K-method / Newton-type implicit solution. The current SDT `main` branch computes friction explicitly from the previous-step velocities (**[derived]** from the code). I did not verify when this changed.
- SDT licence: "GNU General Public License ... version 3 ... or (at your option) any later version" **(code, LICENSE.txt)**. That rules out copying it into a closed-source AUv2 **[derived]**.

**Bow tables and friction curves in STK, Faust and Mutable Instruments Elements (code)**
- STK `BowTable::tick()`: sample = (input + offset)·slope; out = (|sample| + 0.75)^−4, clamped to [0.01, 0.98]. Defaults are offset 0, slope 0.1. The input "represents differential string vs. bow velocity" **(code)** — [BowTable.h](https://github.com/thestk/stk/blob/master/include/BowTable.h)
- STK `BandedWG` (Essl & Cook banded waveguides): each mode is a bandpass filter in a delay-line loop, and the bowed input is `input * bowTable_.tick(input)` with bow-table slope 3.0. Presets are "Uniform Bar", "Tuned Bar", "Glass Harmonica" (5 modes) and "Tibetan Prayer Bowl (ICMC'02)" (12 modes). The bowl ratios start 0.996, 1.004, 2.979, 2.993, 5.704 …, i.e. split doublets. Bow pressure maps to slope = 10 − 9·value **(code)** — [BandedWG.cpp](https://github.com/thestk/stk/blob/master/src/BandedWG.cpp)
- Faust `fds.lib` `bow(coeff,alpha,k,vb)` is a "nonlinear friction based interaction model that induces Helmholtz motion (see Stefan Bilbao's book, Numerical Sound Synthesis)". It computes φ(u) = 1.41·α·Δv·exp(−α·Δv² + 0.5), with Δv = (x − x′)/k − vb. It is a memoryless exponential friction curve meant to be coupled to an FD mesh **(code)** — [fds.lib](https://github.com/grame-cncm/faustlibraries/blob/master/fds.lib)
- Faust `mi.lib` `nlBow`: "non-linear friction based interaction that allows for stick-slip bowing", with a piecewise-linear profile or the smooth 0.63·z·Δv·exp(−4(Δv/scale)² + ½), for mass-interaction models **(code)** — [mi.lib](https://github.com/grame-cncm/faustlibraries/blob/master/mi.lib)
- Faust `physmodels.lib` `bowTable(offset,slope)` = pow(abs(sample) + 0.75, −4) : min(1), the same shape as STK, plus `violinBowTable` and `bowInteraction` for waveguide strings **(code)** — [physmodels.lib](https://github.com/grame-cncm/faustlibraries/blob/master/physmodels.lib)
- Mutable Instruments Elements resonator:
  - 64 modes (`kMaxModes = 64`), of which the first 8 (`kMaxBowedModes = 8`) are "bowed modes";
  - each bowed mode is a delay line of length 1/partial_frequency plus a normalised bandpass SVF with Q = 1 + f·1500;
  - their summed output passes through `BowTable(x, velocity)`, where x = 0.13·velocity − x and bow = 0.25/(|6x| + 0.75)⁴, floored at 0.0025, and is fed back. This is a banded-waveguide bow on a modal bank;
  - "Update the first 24 modes every time (2kHz). The higher modes are refreshed as a slowest rate" (coefficient updates are control-rate and split across blocks).

  **(code)** — [resonator.cc](https://github.com/pichenettes/eurorack/blob/master/elements/dsp/resonator.cc), [resonator.h](https://github.com/pichenettes/eurorack/blob/master/elements/dsp/resonator.h). Licence: MIT ("Permission is hereby granted, free of charge ..."; "See http://creativecommons.org/licenses/MIT/") **(code)**.

**Physical-basis notes relevant to coupling (snippets only)**
- The cuíca sound "comes from stick-slip friction on a rod attached to the head", and "the body of the Cuíca contributes little to the sound" **(snippet of a Tokyo Geidai collection page; not read in full)** — [Geidai Koizumi collection No.196](https://www.geidai.ac.jp/labs/koizumi/gcat0/english/html-text/196.html). Flagged for the acoustics researcher to confirm.
- The lion's roar is described as a membranophone that "can also be a friction drum", with a cord or horsehair through the head **(snippet)** — [Wikipedia: Lion's roar](https://en.wikipedia.org/wiki/Lion's_roar_(instrument))

### Inferences
- **[derived]** The cuíca and fanfrnoch excite the membrane at its centre through the stick or cord; the friction contact is hand/cloth on stick, not bow on membrane. A centre-applied force only excites the axisymmetric modes (0,n), because modes with m ≥ 1 have a nodal line through the centre. A modal model therefore needs only a few (0,n) modes for the friction-driven part, plus perhaps a few (1,n)/(2,n) modes at low gain for asymmetry. This contradicts the Onofrei model, which lets the bow wander over the head and so excites modes 2 and 3 (their Fig. 6). That wandering is one plausible reason listeners heard "gong / bowed bar / cymbal".
- **[derived]** The SDT-style architecture is the right shape for a "mechanism-based but cheap" engine:
  - an inertial "hand" object driven by a stroke velocity envelope;
  - one elasto-plastic or Stribeck-curve contact;
  - a modal resonator of 4–12 (0,n) modes, plus stick mass added to the centre.

  It mirrors the sibling jaw-harp choice. The explicit, non-iterative SDT update shows that this can run without Newton iterations, at the cost of stability limits on s0 and Δt, which would need testing at 44.1/48 kHz.
- **[derived]** The cavity can be a few extra modes or one or two biquad formants in series with the membrane output, rather than a coupled FDTD tube. The Onofrei authors themselves had to detune the tube (γ = 30 m/s) to get a "drum" sound, so the 1-D physics did not buy realism.
- **[derived]** Onofrei FDTD cost. The membrane has about 0.3/0.0167 ≈ 18 intervals per side, so about 17² = 289 interior points, about 227 inside the circle. Each point needs a 5-point Laplacian of uⁿ and of uⁿ⁻¹ (for the σ1 term), about 15–20 flops, giving about 4k flops. The tube has 0.4/0.0011 ≈ 364 points at about 5 flops, giving about 1.8k flops. A 3×3 Newton solve adds up to 99 iterations. Total: about 6k–10k flops per sample per voice, roughly 20–100× the stated per-voice budget, and it is still band-limited. The stability limit with c = 150 m/s and k = 1/44100 is h_min = √(2c²k² + 8σ1k) ≈ 4.9 mm; they ran at 16.7 mm.

### Gaps
- I found no published cuíca-specific, rommelpot, fanfrnoch or lion's-roar physical model other than Onofrei et al. A search for ICMC/SMC/NIME friction-drum papers turned up nothing; this is negative evidence from limited searching.
- I found no listening test comparing any synthetic friction drum with recordings.
- The SDT friction model's numerical stability limits (maximum s0 versus sample rate for the explicit scheme) are not documented in what I read.
- The Serafin PhD thesis ("The sound of friction", Stanford/CCRMA), the main source for the noise term and playability, was not read.
- The Perry Cook PhISEM/STK set has no friction-drum or cuíca instrument. I checked `Shakers.cpp`, which lists a Guiro (see Q2) but no cuíca.

---

## Q2. Cheaper source–filter approaches: pulse trains or noise bursts through modal/formant filters; imitating stick-slip roughness and jitter

### Takeaway
Source–filter friction synthesis is an established sound-design technique: a jittered impulse train standing for the stick-slip events, sent through formant or modal filters (Farnell's creaking door, PhISEM's stochastic guiro). It is the cheapest option and gives direct pitch control. I found no published evaluation of how believable it is for a friction drum. Tribology results support modelling the squeak pitch as a pulse repetition rate rather than random events.

### Cited Findings
- Farnell, *Designing Sound*, "Creaking door" (SuperCollider adaptation on Wikibooks). It has sections on "formants for a wooden door" and on stick-slip, combined into a door "you can push". The stick-slip code "uses Impulse to generate a frequency, but we add some noise to its frequency so the motion doesn't become too regular" **(snippet/summary; page not read in full)** — [Wikibooks](https://en.wikibooks.org/wiki/Designing_Sound_in_SuperCollider/Creaking_door). The Pure Data original is Practical 9 in the MIT Press companion files — [MIT Press](https://mitp-content-server.mit.edu/books/content/sectbyfn/books_pres_0/8375/designing_sound.zip/practical09.html)
- JASS creaking door demo (van den Doel, UBC): another real-time creaking-door implementation **(not read)** — [UBC JASS](https://www.cs.ubc.ca/~kvdoel/jass/creaking/creaking.html)
- STK PhISEM `Shakers` includes a "Guiro" (instrument 19), a scraped and therefore friction-like idiophone. It is modelled stochastically with `GUIRO_NUM_PARTS = 128`, `GUIRO_SOUND_DECAY = 0.95`, `GUIRO_GAIN = 0.4`, two resonances at 2500 and 4000 Hz with pole radius 0.97 **(code)** — [Shakers.cpp](https://github.com/thestk/stk/blob/master/src/Shakers.cpp)
- Tribology: the University of Nottingham reports that "the audible squeak is not produced by random stick-slip events. Rather, the squeaking sound frequency is set by the repetition rate of these propagating pulses" **(snippet, press release, [authors])** — [Nottingham news](https://www.nottingham.ac.uk/news/stop-the-squeak-new-research-could-end-squeaking-trainers-or-screeching-chalk). Purdue reports stick-slip "arises from propagation of three distinct types of jerky motion" **(snippet)** — [Purdue](https://www.purdue.edu/newsroom/archive/releases/2016/Q2/pesky-squeaks-and-squeals-caused-by-3-types-of-stick-slip-behavior.html)
- Bart Hopkin's practical notes: "a key to managing friction sounds is imposing some discipline on the stick-slip and its frequency" **(snippet, [authors])** — [Adventures in Friction](https://barthopkin.com/adventures-in-friction/)
- The physical models' noise terms are an analogue of "roughness". In SDT the force noise is s3·w·√(|v|·fn) (white noise scaled by √(|v|·normal force)) **(code)**; Onofrei uses s3 ∈ [0, 0.04·fN]·w (**full**). Both inject roughness as velocity- or force-scaled white noise added to the friction force, not as period jitter **[derived from the cited code and paper]**.
- A related cheap mechanism in Elements: a memoryless bow table on the summed output of 8 delay+bandpass "bowed modes". It self-oscillates at the mode periods, so it is something between source–filter and physical **(code)** — [resonator.cc](https://github.com/pichenettes/eurorack/blob/master/elements/dsp/resonator.cc)

### Inferences
- **[derived]** A source–filter cuíca voice would have:
  - a band-limited pulse or glottal-like train at f0 (each pulse is a slip event), with period jitter of a few percent and per-pulse amplitude noise;
  - a short noise burst at onset and offset (cloth scrape), with noise amplitude following |stroke velocity|;
  - a bank of 4–8 (0,n) membrane modes (see Q3) plus one or two cavity formants;
  - a pitch envelope per stroke: rise or fall over the stroke, plus "pressure" bend.

  It would cost about 50–150 flops per sample. The pitch range is unlimited and the pitch is exactly controllable for keyboard mode.
- **[derived]** The weakness compared with a self-oscillating friction model: onset behaviour does not emerge. In a real stick-slip system the first strokes are irregular before the oscillation locks (pitch "catch", subharmonics, squeal). A source–filter voice has to script these explicitly, for example by starting with high jitter or period-doubling and settling. A hybrid would have a pulse-train "slip clock" whose period is pulled toward the lowest membrane mode, or a friction-curve exciter on a few modes (Q1).

### Gaps
- I found no paper or product that evaluates a source–filter cuíca or friction-drum synthesis for realism.
- I did not get Farnell's exact formant frequencies or filter design.
- The DAFx 2017 "Simulating the friction sounds ..." paper (Waseda University) could not be parsed; only its outline was visible — [PDF](https://www.dafx17.eca.ed.ac.uk/papers/DAFx17_paper_58.pdf)
- The mammalian vocalisation synthesis paper (FM + LPC waveguide; "lion's roar" refers to the animal, not the instrument) was seen only as a snippet and is not a friction-drum model — [academia.edu](https://www.academia.edu/31085323/A_SYNTHESIS_MODEL_FOR_MAMMALIAN_VOCALISATION_SOUND_EFFECTS)

---

## Q3. Modal membrane synthesis: mode frequencies (Bessel zeros), air loading, damping, cavity coupling; efficient implementation

### Takeaway
Ideal circular-membrane modes follow the Bessel zeros (f_mn ∝ α_mn). Air loading shifts these frequencies (lowering the low modes and "spreading" the ratios) and adds damping; published work treats this as per-mode detuning and decay corrections inside a modal engine, not as a separate simulation. Efficient implementation is a bank of second-order resonators (SDT, Elements and STK all do this), with control-rate coefficient updates for pitch bends.

### Cited Findings
- Ideal membrane: ω_mn = α_mn·c/a, with α_mn the Bessel zeros. The page gives α01 = 2.40483, α02 = 5.52008, α03 = 8.65373, α11 = 3.83171, α12 = 7.01559, α13 = 10.1735, α21 = 5.13562, α22 = 8.41724, α23 = 11.6198 **(page read via summary)** — [Wikipedia: Vibrations of a circular membrane](https://en.wikipedia.org/wiki/Vibrations_of_a_circular_membrane). Ratios to (0,1) **[derived]**:
  - (1,1) 1.593, (2,1) 2.136, (0,2) 2.295, (1,2) 2.917, (2,2) 3.500, (0,3) 3.598, (1,3) 4.231, (2,3) 4.832;
  - axisymmetric series only: (0,1) 1.000, (0,2) 2.295, (0,3) 3.598.
- Air loading as a modal correction: Marogna & Avanzini (DAFx 2009) analysed recorded drum sounds "to extract the most relevant parameters, especially the effects of air loading, detuning and increased dissipation" **(snippet)** — [marogna_dafx09.pdf](https://avanzini.di.unimi.it/downloads/publications/marogna_dafx09.pdf). The same group's IEEE TASLP 2010 paper proposes "models for coupling between two membranes through enclosed air in two-headed percussions" within modal synthesis **(snippet)** — [avanzini_taslp10.pdf](https://avanzini.di.unimi.it/downloads/publications/avanzini_taslp10.pdf). They also have a tension-modulation (pitch glide) paper **(not read)** — [Marogna, Avanzini, Bank](https://people.ece.cornell.edu/land/courses/ece5760/LABS/s2016/MarognaAvanziniBank_tension_modulation.pdf)
- Timpani evidence that air mass loading dominates the shift: Mills (NIU thesis, advised by Rossing, 1980) found measured timpani mode frequencies spread out compared with the ideal membrane. The thesis rules out membrane stiffness at these frequencies and "concludes that the air's effective mass loading is the dominant cause of the frequency shifts" **(snippet)** — [NIU](https://huskiecommons.lib.niu.edu/allgraduate-thesesdissertations/6350). Davis (Purdue dissertation, advisor Tubis) fits experimental modal data with Green's-function / boundary-integral models of air loading and kettle shape **(snippet)** — [Purdue](https://docs.lib.purdue.edu/dissertations/AAI8825522). An Emory thesis notes that ideal-membrane predictions came out higher than measured frequencies and attributes the gap to the air loading the model left out **(snippet)** — [Emory](https://etd.library.emory.edu/concern/etds/kw52j9322)
- Modal-domain efficiency: a Forum Acusticum 2023 paper argues that solving in the modal domain is convenient for real time and that modal-domain losses give frequency-dependent damping "at little extra cost" **(snippet)** — [FA2023 paper](https://dael.euracoustics.org/confs/fa2023/data/articles/000995.pdf)
- Implementation patterns in code:
  - SDT: exact-discretised mass–spring per mode, three multiplies per mode for position plus two for velocity. Coefficients are recomputed per mode on parameter change with `cos`/`sin`/`exp`. "fragmentSize" scales all frequencies and decays together (a global size/tension control) **(code)** — [SDTResonators.c](https://github.com/SkAT-VG/SDT/blob/main/src/SDT/SDTResonators.c)
  - Elements: 64 SVF modes with `set_f_q<FREQUENCY_FAST>` (fast tan approximation) and Q rising with frequency (1 + f·q). The first 24 modes are updated every block and the higher modes alternately, to save CPU **(code)** — [resonator.cc](https://github.com/pichenettes/eurorack/blob/master/elements/dsp/resonator.cc)
  - The Onofrei FDTD membrane uses σ0 (frequency-independent) and σ1 (frequency-dependent) loss, the standard two-parameter damping law, with σ0 up to 6 s⁻¹ and σ1 up to 0.0026 m²/s **(full)** — [DAFx20in21](https://www.dafx.de/paper-archive/2021/proceedings/papers/DAFx20in21_paper_32.pdf). **(Wording note:** the paper's own text calls σ0 "frequency-dependent" and σ1 "frequency-independent", which is the reverse of the usual convention: in this PDE σ0 is the frequency-independent term and σ1 the frequency-dependent one. **[derived]**)

### Inferences
- **[derived]** Per-mode cost is about 5–8 flops per sample for a two-pole resonator, with velocity output if friction coupling needs it. Eight (0,n)-dominant modes plus four asymmetric modes plus two cavity resonances is 14 resonators, about 100 flops. This leaves room for the friction exciter within "tens to a few hundred ops/voice".
- **[derived]** Pressing the head (pitch bend) raises tension, and c ∝ √T scales all ideal-membrane modes together. Air loading lowers the low modes most, so the ratios are not fixed. A cheap approximation: scale all modes by one factor per control block and keep a fixed, hand-tuned "air-loaded" ratio table (lower (0,1) relative to the others). Real measured cuíca ratios should come from the acoustics notes.
- **[derived]** Damping per mode can follow σ0 + σ1·ω²-like laws (decay rate rising with frequency), giving one "damping" and one "brightness" parameter, as in the Onofrei GUI's merged "Damping" slider.
- **[derived]** The stick (cuíca) or cord-and-wax mass at the centre adds mass mainly to the (0,n) modes and lowers them. In a modal model this is another per-mode frequency offset, not new structure.

### Gaps
- I found no numerical air-loading shift values for small drums (cuíca, 6–10 inch). The timpani numbers in Christian et al. (1984, JASA) were not retrieved.
- I found no published modal parameter set (frequencies, decays, gains) measured from a cuíca or other friction drum.
- I did not verify how cavity coupling (the open-ended shell acting as a tube) should be modelled cheaply. The literature I found (two-headed drums) concerns closed cavities.

---

## Q4. Commercial and free products: sample libraries, drum and physical-modelling synths with friction or cuíca models; reviews on realism

### Takeaway
Every dedicated cuíca product I found is sample-based (Kontakt libraries, ethnic-percussion ROMplers). Physical-modelling instruments with a bow or friction exciter exist (Logic Sculpture, Ableton Tension, AAS String Studio-type tools, Mutable Elements and its VCV port, SDT for Max/Pd), but none ships a friction-drum model or preset that I could find. The percussion modellers (Chromaphone, Collision) offer only mallet and noise exciters. This supports the gap the project targets, though the evidence is negative and based on limited searching.

### Cited Findings
**Sample libraries (cuíca)**
- Sonokinetic *Cuica*: a Kontakt instrument with "two sampled cuicas, a soprano at 6 inches and a bass at 10 inches", three microphone positions, and "950+ samples in 44.1kHz, 24-bit NCW". It was listed at €0.00, but a blog says the free offer expired, and it needs full Kontakt **(snippet, [claimed])** — [Sonokinetic](https://www.sonokinetic.net/products/ethnic/cuica/), [manual PDF](https://www.sonokinetic.net/manual/cuica/Cuica-Reference-Manual.pdf), [Bedroom Producers Blog](https://bedroomproducersblog.com/?p=25599)
- Muletone Audio *Cuíca* / *Cuíca 2*: Kontakt, "various articulations and dynamics", single hits plus Samba/Maracatu/Timbalada loops. Cuíca 2 costs $17.99 and needs Kontakt 5.5+ full **(snippet, [claimed])** — [pulse.audio](https://pulse.audio/product/cuica/)
- Sonokinetic *Percussão do Brasil* (a broader Brazilian set) — [Sonokinetic](https://www.sonokinetic.net/products/ethnic/percussao-do-brasil/). Cinesamples *Rio Grooves* has a Sound On Sound review **(not read)** — [SOS](https://www.soundonsound.com/reviews/cinesamples-rio-grooves)
- Syntheway *Drumwavy* (VST/VST3/AU) includes a "Brazilian Cuica Drum (C2-B2)", sample-based **(snippet, [claimed])** — [Syntheway](https://www.syntheway.net/Drumwavy.htm)
- Loopmasters *Traditional Brazilian Percussion* includes "2 Cuica Loops" **(snippet)** — [Loopmasters](https://www.loopmasters.com/genres/146-South-American/products/5702-Traditional-Brazilian-Percussion)
- I found no formal magazine review that assesses cuíca library realism; the search turned up only product pages and short user comments **(search result)**.

**Physical-modelling instruments with a friction or bow exciter**
- Apple Logic *Sculpture*: its exciter types include "Bow" and "Bow Wide". Bow Wide gives "a mellower tone", and the variations are most striking when the bow moves along the string **(snippet of Apple help)** — [Apple: Sculpture objects](https://help.apple.com/logicpro/mac/9.1.6/en/logicpro/instruments/chapter_14_section_5.html), [Sculpture overview](https://help.apple.com/logicpro/mac/10.4/en.lproj/lgsia12ea31.html). I found no friction-drum or cuíca preset.
- Ableton *Tension*: its Excitator offers "Plectrum, Bow ..., and two Hammer models" **([claimed], vendor)** — [Ableton Tension](https://www.ableton.com/packs/tension/). On realism and controllability, a forum user reports the Bow excitator gives "distorted noise". An Ableton staffer replies that, as with a real violin, "it is easy to get noise and hard to get a nice sound", and suggests starting from a preset **(snippet, [authors])** — [Ableton forum](https://forum.ableton.com/viewtopic.php?p=862329)
- Ableton *Collision*: the exciter is a mallet (stiffness, noise) plus a filtered, enveloped noise source; there is no bow or friction exciter **([claimed], vendor)** — [Ableton Collision](https://www.ableton.com/packs/collision/)
- AAS *Chromaphone 2/3*: mallet and noise exciters driving paired resonators. A drumhead resonator "modeled on how a real drumhead vibrates" was added in v2. There is no friction exciter **(snippets, [claimed])** — [Synthtopia on Chromaphone 2](https://www.synthtopia.com/content/2016/03/15/aas-intros-chromaphone-2-acoustic-object-synthesizer/), [rekkerd review](https://rekkerd.org/review-applied-acoustics-systems-chromaphone/), [SOS review](https://www.soundonsound.com/reviews/aas-chromaphone)
- Mutable Instruments *Elements*: open-source hardware with a bow exciter on a 64-mode resonator (8 bowed modes) under the MIT licence **(code)** — [eurorack repo](https://github.com/pichenettes/eurorack/tree/master/elements)
- Sound Design Toolkit: Max and Pure Data externals including `friction` (elasto-plastic) and modal resonators, GPLv3 **(code; repo has `MaxPackage/` and `Pd/` folders)** — [SDT GitHub](https://github.com/SkAT-VG/SDT)
- Research prototype: Onofrei et al.'s JUCE friction-drum app (Sensel Morph), video only — [YouTube demo](https://www.youtube.com/watch?v=3UEUyYc6PF0)

### Inferences
- **[derived]** No shipping product synthesises a friction drum as a playable rhythm instrument that I could find. The closest are generic bow exciters (Sculpture, Tension, Elements), whose sustained-bow design and parameter sensitivity ("easy to get noise, hard to get a nice sound") argue for a dedicated, pre-tuned stroke model with few controls.
- **[derived]** Sample libraries cover realism for fixed articulations (multi-sampled strokes and loops). A synthesised engine would win on pitch continuity (keyboard mode, glides) and stroke-to-stroke variation, which is where the design should put its effort.

### Gaps
- I found no reviews that judge any synthesised friction or bow model's realism for drum-like sounds.
- I did not check Native Instruments (Kontakt factory "World", *Cuba* includes Latin percussion but cuíca unknown), Spitfire, u-he, Madrona Labs (Kaivo / Aalto), VCV Rack third-party modules, or Pure Data community patches specifically for cuíca. The searches were too generic, so whether they contain a cuíca is unverified. I believe the VCV "Audible Instruments Modal Synthesizer" is a port of Elements, but I did not verify this here.
- I did not verify that General MIDI percussion includes "Mute Cuica" and "Open Cuica" notes, though it is widely assumed. This matters for default note mapping and should be checked against the MIDI Association GM spec.

---

## Q5. Code available (licence), parameter sets, CPU costs

### Takeaway
Reusable code exists at every tier: MIT (STK, Elements), LGPL with a static-compile exception (Faust libraries), and GPLv3 (SDT; usable only as reference for a closed product). Usable parameter sets exist for the elasto-plastic model (Onofrei Table 1; SDT defaults) and for bow tables (STK, Elements). No source gives CPU figures. My operation counts put an SDT-style explicit friction exciter on 8–16 modes at about 100–250 flops per sample, and the published FDTD friction drum at about 6k–10k.

### Cited Findings
- **Licences (code read):**
  - STK: MIT-style permission notice, plus a non-binding request to send modifications upstream ("This is, however, not a binding provision of this license") — [STK LICENSE](https://github.com/thestk/stk/blob/master/LICENSE)
  - Faust libraries `fds.lib`, `physmodels.lib`: LGPL with "EXCEPTION TO THE LGPL LICENSE ... grants you the right to freely choose the license for the resulting" compiled code, "for example ... a commercial or closed source license"; `mi.lib` is © GRAME / GIPSA-Lab — [faustlibraries](https://github.com/grame-cncm/faustlibraries)
  - Mutable Instruments Elements: MIT — [eurorack](https://github.com/pichenettes/eurorack)
  - SDT: GPLv3-or-later — [SDT LICENSE](https://github.com/SkAT-VG/SDT/blob/main/LICENSE.txt)
  - The Onofrei et al. paper is CC BY 3.0; I found no code.
- **Parameter sets:**
  - Onofrei et al. Table 1 (listed in full under Q1): µC 0.3, µS 0.8, vS 0.1 m/s, s0 1e5 N/m, s1 0.001·√s0, s2 4, s3 ≤ 0.04·fN, z_ba = 0.7·F_C/s0, fN 0–20 N, vB 0–0.2 m/s — [paper](https://www.dafx.de/paper-archive/2021/proceedings/papers/DAFx20in21_paper_32.pdf)
  - SDT friction defaults: vs 0.1, ks (static) 0.8, kd (dynamic) 0.2, kba 0.1, s0 1000, s1 10, s2 10, s3 0.5 — [SDTInteractors.c](https://github.com/SkAT-VG/SDT/blob/main/src/SDT/SDTInteractors.c)
  - STK BowTable: offset 0, slope 0.1 by default, clamp [0.01, 0.98]; BandedWG bow slope 3.0, pressure → slope 10 − 9p; Tibetan bowl 12-mode ratios — [STK](https://github.com/thestk/stk)
  - Elements bow table: x = 0.13·v − x, 0.25/(|6x| + 0.75)⁴, floor 0.0025; bowed-mode bandpass Q = 1 + f·1500 — [resonator.h](https://github.com/pichenettes/eurorack/blob/master/elements/dsp/resonator.h)
  - STK Guiro: 128 parts, decay 0.95, resonances 2500/4000 Hz, radius 0.97 — [Shakers.cpp](https://github.com/thestk/stk/blob/master/src/Shakers.cpp)
- **CPU:** none of the sources reports CPU percentages or cycles. Onofrei et al. only say that the grids were coarsened to avoid dropouts **(full)**.

### Inferences
- **[derived]** Approximate per-voice operation counts:

  | Approach | Ops per sample per voice | Notes |
  |---|---|---|
  | Source–filter: pulse train, 8–14 modes, 1–2 formants, noise | ≈ 60–150 flops | 16–40 voices fit easily |
  | SDT-style elasto-plastic contact on 8–16 modes | ≈ 40–60 (friction) + 8–10 per mode ≈ 120–220 | Friction: 1 exp, 1 sin in the transition, 1 sqrt, 1 noise. Modes: position, velocity and force share. Within budget at 16–40 voices. Explicit stability must be checked; float may need care with s0 large |
  | Banded-waveguide bow (Elements/STK) on 4–8 modes | ≈ 60–100 | Per mode: delay plus SVF |
  | Onofrei FDTD | ≈ 6k–10k plus Newton | Out of budget |

  Note that the voices are short strokes, so voice stealing at 16 is plausible.
- **[derived]** No allocation on the audio thread: SDT allocates with `malloc` in `SDTResonator_new` / `SDTFriction_new` and in `setNModes` (which reallocates). A reimplementation should use fixed-size per-voice arrays (as Elements does with `kMaxModes`) and preallocate. Elements' control-rate coefficient updates (alternating higher modes) are a pattern to copy for per-block pitch glides.
- **[derived]** Licensing: for a closed-source AUv2, STK, Elements and Faust-generated code can be used directly. SDT should be treated as a reference algorithm only; its equations are published and can be reimplemented from the papers.

### Gaps
- I found no measured CPU benchmarks for SDT friction, Elements' bow mode, or Faust's `fd.bow` on desktop CPUs; the figures above are hand counts.
- I did not determine the stability bound of the explicit elasto-plastic plus modal coupling at 44.1/48 kHz in single precision (SDT uses double).
- I found no cuíca- or friction-drum-specific parameter set from measurements; all available parameter sets come from bowed strings or are hand-tuned.
