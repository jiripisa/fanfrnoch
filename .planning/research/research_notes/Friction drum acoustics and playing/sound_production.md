# Friction drum acoustics: how the sound is made (mechanisms and numbers for synthesis)

Evidence labels used throughout: **[measured]** published measurement; **[interpretation]** authors' interpretation or model; **[described]** player/maker description; **[claimed]** vendor/encyclopedia/aggregator; **[derived]** my own arithmetic or reasoning from standard physics (not found stated in a source this session).

Reading depth: **[full]** = I read the relevant sections of the full text; **[snippet]** = abstract or search-engine snippet only.

---

## Q1. What literature exists, and how much of it gives numbers?

### Takeaway
There is almost no published *measurement* of friction drums. The sources I could read are a tutorial that explains the cuíca by analogy with the bowed string (Akay 2002), one physical-modelling thesis and paper with simulation parameters (Onofrei/Willemsen/Serafin 2021), and general drum and bowed-string acoustics (Rossing; Woodhouse). The only cuíca-specific acoustic study I found (JASA 2002 abstract) is available as a snippet only. Most numbers below are therefore **derived** from membrane, cavity and stick-slip physics. They are not measured on real instruments.

### Cited Findings
- Akay, "Acoustics of friction", *J. Acoust. Soc. Am.* 111(4), April 2002, pp. 1525–1548 (tutorial). It has a short cuíca section with no numbers. **[full: cuíca and mode-lock-in sections]** — [Akay 2002](https://www.imperial.ac.uk/media/imperial-college/research-centres-and-groups/dynamics/Akay-Acoustics-of-friction.pdf)
- Onofrei, *Real-Time Implementation of Bowed Instruments Using Static and Dynamic Friction Models*, MSc thesis, Aalborg University, 2021. Chapter 5 models a friction drum as "a bowed membrane connected to an acoustic tube" and gives a full parameter table. Appendix B contains the DAFx paper. **[full: ch. 1.2, 5, 6.2]** — [Onofrei thesis 2021](https://projekter.aau.dk/projekter/files/410480603/Real_Time_Implementation_Of_Bowed_Instruments.pdf)
- Onofrei, Willemsen, Serafin, "Real-Time Implementation of a Friction Drum Inspired Instrument Using Finite Difference Schemes", DAFx20in21. **[snippet; the PDF servers returned a maintenance page or a bot check, so its content came through the thesis]** — [DAFx archive entry](https://dafx.de/paper-archive/details/GptcVBFRK_o3NkyG_Uj57A)
- "An acoustic study of the Brazilian cuica", *JASA* 112(5) Suppl., p. 2266 (2002; meeting abstract; ADS bibcode 2002ASAJ..112.2266W). According to the snippet, it studied waveforms, spectra and time envelopes of a gourd-bodied folk cuíca and found that "the body of the cuica contributes little to the sound". **[snippet only; I could not fetch the full abstract text, the authors or any numbers]** — [JASA](https://pubs.aip.org/asa/jasa/article/112/5_Supplement/2266/548495/An-acoustic-study-of-the-Brazilian-cuica); [ADS](https://ui.adsabs.harvard.edu/abs/2002ASAJ..112.2266W/abstract)
- Donescu et al.(?), "On the Acoustics of the Stick-Slip Phenomenon", *Rev. Roum. Sci. Tech. – Méc. Appl.* 56(2), 2011, pp. 105–111. According to the snippet, it includes a friction drum example in which the player "rubs a stick with a piece of moist cloth, thereby exciting the membrane at its center". This wording echoes Akay. **[snippet only; site served a bot wall]** — [Rev. Roum. 2011](https://academiaromana.ro/sectii2002/RomanianJournalTS/rev2011-2/RJTS-AM_2011_2_a1_Donescu.pdf)
- *Phys. Rev. E* 47, 820 (1993), "Spatiotemporal dynamics due to stick-slip friction in an elastic-membrane system". It studied a stretched latex membrane in contact with a translating glass rod. Per the snippet, "the frictional force increases with velocity and an instability is due to waves of detachment". This is a physics lab setup, not an instrument. **[snippet only]** — [PRE 1993](https://journals.aps.org/pre/abstract/10.1103/PhysRevE.47.820)
- Clarindo Nunes, Wanderley, Lopes, "Hypercuíca", NIME 2026. It describes cuíca playing technique and gives no acoustic measurements. **[full: sections 1–3]** — [NIME 2026](https://nime.org/proceedings/2026/nime2026_81.pdf)
- Rossing, "Acoustics of drums", *Physics Today*, March 1992, pp. 40–47. Ideal-membrane mode ratios, air loading and kettle volume effects. **[full]** — [Rossing 1992](https://aip.brightspotcdn.com/PTO.v45.i3.40_1.online.pdf)
- Woodhouse & Galluzzo, "Why is the violin so hard to play?", *Plus* magazine, Sept 2004. Covers Helmholtz motion, double slip, raucous motion, the Schelleng limits and transients. **[full]** — [Woodhouse & Galluzzo 2004](https://plus.maths.org/old-files/issue31/features/woodhouse/2pdf/index.html/op.pdf)
- Galante, *Da cupópia da cuíca…*, MSc dissertation, USP 2015. This is ethno-historical work, and the search results show no acoustics in it. **[not read]** — [USP](https://teses.usp.br/teses/disponiveis/8/8138/tde-02062015-175712/en.php)

### Inferences
- The JASA 2002 cuíca study is the most likely place for real cuíca spectra and envelopes. It is worth obtaining through a library (JASA supplement, ASA meeting abstract).
- I did not find Fletcher & Rossing's *Physics of Musical Instruments* or Rossing's *Science of Percussion Instruments* treating friction drums quantitatively. Search snippets show no friction-drum section, but I did not check the books themselves.

### Gaps
- I found no measured spectra, pitch ranges, decay times or onset times for any friction drum type (cuíca, rommelpot, zambomba, buhai, putipù, fanfrnoch, lion's roar).
- No paper by Woodhouse, Avanzini or Serafin specifically on *real* friction drums turned up. The Serafin-group paper is a simulation.
- Spanish/Portuguese/German/Czech searches turned up organology only, with no acoustics.

---

## Q2. What is the stick-slip mechanism, what is the slip rate relative to the pitch, and when does the sound lock, chatter or turn noisy?

### Takeaway
In the authors' interpretation, a friction drum is a "bowed" system. The wet or rosined hand or cloth is the bow, and the rod or cord plus the membrane centre is the vibrating element. When the motion locks to a mode, there is **one slip per period**, so the pitch is the locked mode's frequency, not something set by the rubbing speed. The system can also produce double slip (a different timbre at the same pitch), raucous or aperiodic noise when pressed too hard, and transient scratch before it locks.

### Cited Findings
- Cuíca mechanism: "a thin bamboo stick suspends from the center of the membrane where one end of the stick is tied with a knot. The player continuously strokes the stick with a piece of moist cloth, thereby exciting the membrane at its center with the resulting stick–slip motion. The player produces music by controlling the radiation response by judiciously placing a finger on various spots on the membrane." **[interpretation, full]** — [Akay 2002](https://www.imperial.ac.uk/media/imperial-college/research-centres-and-groups/dynamics/Akay-Acoustics-of-friction.pdf)
- "Mechanically, the operation of the cuica has similarities to that of a bowed string instrument… the bamboo stick vibrates the membrane as a bow does with a string, and the player's finger on the membrane selects the mode of vibration as does placing a finger on the string." **[interpretation]** — [Akay 2002](https://www.imperial.ac.uk/media/imperial-college/research-centres-and-groups/dynamics/Akay-Acoustics-of-friction.pdf)
- Mode lock-in: under strong friction contact, "instabilities develop and frequently lead to a condition called mode lock-in, where the coupled system responds at one of its fundamental frequencies and its harmonics. Development of mode lock-in and the selection of the mode at which the system responds depends on the normal load, sliding velocity, and the contact geometry." **[interpretation/demonstration]** — [Akay 2002](https://www.imperial.ac.uk/media/imperial-college/research-centres-and-groups/dynamics/Akay-Acoustics-of-friction.pdf)
- In Akay's bowed-beam and wineglass demonstrations, "only infrequently does more than one natural frequency appear simultaneously. Mostly, the bow and beam lock into a particular mode and oscillate in a rather stable manner." A finger imposing a nodal point makes higher modes lock instead. **[measured demonstration, Figs. 2–3]** — [Akay 2002](https://www.imperial.ac.uk/media/imperial-college/research-centres-and-groups/dynamics/Akay-Acoustics-of-friction.pdf)
- Impedance rule: when the two contacting parts have very different impedances, "response of the system is closer to the component with 'weaker' impedance". When the impedances are comparable, the response differs from that of either part. **[interpretation]** — [Akay 2002](https://www.imperial.ac.uk/media/imperial-college/research-centres-and-groups/dynamics/Akay-Acoustics-of-friction.pdf)
- Light rubbing on a rough or corrugated surface instead gives "roughness noise" and impulses at a "corrugation frequency" (speed ÷ ridge spacing, the "picket fence" effect). These impulses excite the natural frequencies. **[interpretation]** — [Akay 2002](https://www.imperial.ac.uk/media/imperial-college/research-centres-and-groups/dynamics/Akay-Acoustics-of-friction.pdf)
- In the friction-drum simulation, "the Helmholtz motion can be seen in the transverse displacements u at the bowing point on the membrane, which shows a triangular shape… Looking at the relative velocity v_rel, the by now familiar stick-slip motion can be observed. A hysteresis loop is observed… [in] friction force f_B with changing relative velocity". A static (velocity-only) friction curve gave "a more noisy sound" than the elasto-plastic model. **[interpretation/simulation, full]** — [Onofrei thesis 2021](https://projekter.aau.dk/projekter/files/410480603/Real_Time_Implementation_Of_Bowed_Instruments.pdf)
- Bowed-string regimes:
  - Helmholtz motion has "a single episode of sticking and of slipping… in every cycle".
  - Too little force gives "double slipping motion… two episodes of slipping per cycle… a note at the same pitch… but with a different waveform", called "surface sound".
  - Too much force gives "a raucous 'graunch' noise… no longer regular, but switches to a chaotic pattern".
  - There is "usually a transient period of non-regular motion… which may make the start of the note sound scratchy".

  **[interpretation, full]** — [Woodhouse & Galluzzo 2004](https://plus.maths.org/old-files/issue31/features/woodhouse/2pdf/index.html/op.pdf)
- Schelleng limits on log–log axes: the maximum force line has slope −1 (∝ 1/β), the minimum has slope −2 (∝ 1/β²), and both scale with bow speed. **[interpretation; snippet]** — [McGill course notes](https://caml.music.mcgill.ca/~gary/618/week11/node3.html)
- Rosin is "a glassy material, with a glass transition temperature near room temperature—its mechanical properties vary rapidly with temperature". **[snippet]** — [Acta Acustica 2026](https://acta-acustica.edpsciences.org/articles/aacus/pdf/2026/01/aacus260048.pdf)

### Inferences
- **[derived] Pitch vs. rubbing speed.** In a locked (Helmholtz-like) regime, the period is set by the resonator. Rubbing speed v and normal force N set *amplitude* (and brightness), not pitch. Synth implication: make pitch a resonator parameter and let "stroke speed" drive level.
- **[derived] Where the friction drum differs from a violin.** A violin string has many near-harmonic modes that support a sharp travelling corner. A centre-driven membrane offers essentially one strong low mode, whose higher axisymmetric partners are inharmonic (Q3). Its behaviour is therefore closer to a **single-degree-of-freedom mass–spring on a moving belt**. Standard 1-DOF stick-slip theory gives two regimes:
  - At low sliding speed and high force, long stick phases (a slow ramp) alternate with fast slips. The period *grows* as speed drops, roughly T_stick ≈ (μs−μk)·N / (k·v). The sound becomes discrete creaks or chatter: each slip is an impulse that rings the membrane mode, at a repetition rate below the mode frequency.
  - At higher speed, the motion becomes quasi-sinusoidal at the natural frequency (locked).
  This explains the "grunt / rummel / creak" sound of slow, heavy strokes and the tonal "voice" of fast, light strokes. It is not verified on an instrument.
- **[derived] Squeal.** With a heavy, stiff rod (cuíca bamboo, putipù cane), the rod's own longitudinal modes lie at several kHz (Q3). A dry or over-rosined contact at high speed can lock onto those instead. That would give a high squeal, analogous to Akay's lock-in at a higher mode.
- **[derived] Rough or scratchy noise.** The wet cloth or fingers never give a perfectly clean slip. A noise term proportional to N (as Onofrei uses, see Q6) plus occasional double slip and aperiodic episodes produces the characteristic rasp. In a synth, roughness should rise with N/v (the Schelleng-upper-limit side).

### Gaps
- I found no measurement of slip rate vs. sounding pitch on any real friction drum, and no high-speed or video study of the cloth–stick contact.
- I found no study of when a cuíca locks vs. chatters. Akay's statement is qualitative.

---

## Q3. Which membrane modes sound, at what frequency ratios, and how do the rod, air loading and damping change them?

### Takeaway
The rod or cord is attached at the membrane **centre**, where every mode with nodal diameters (m ≥ 1) has a node. A centre drive therefore excites essentially only the axisymmetric modes (0,1), (0,2), (0,3)… (ideal ratios 1 : 2.296 : 3.600 : 4.903). In practice the sounding "mode" is a coupled rod-mass + membrane-stiffness + enclosed-air-stiffness oscillator. Because it is driven by stick-slip, the sound is a harmonic series locked to that mode, coloured by the higher (0,n) resonances and the cavity. An off-centre finger breaks the symmetry and can bring in or select other modes (Akay).

### Cited Findings
- Ideal circular membrane: f_mn = (j_mn / 2πa)·√(T/σ). The relative frequencies of the first 14 modes are:

  | Modes | (0,1) | (1,1) | (2,1) | (0,2) | (3,1) | (1,2) | (4,1) | (2,2) | (0,3) | (5,1) | (3,2) | (6,1) |
  |---|---|---|---|---|---|---|---|---|---|---|---|---|
  | Ratio | 1.000 | 1.594 | 2.136 | 2.296 | 2.653 | 2.916 | 3.156 | 3.501 | 3.600 | 3.652 | 4.060 | 4.154 |

  **[theory, full]** — [Rossing 1992](https://aip.brightspotcdn.com/PTO.v45.i3.40_1.online.pdf)
- Air loading: "the mass of this air sloshing back and forth lowers the frequencies of the principal modes". "The stiffness (or pressure) of the air enclosed in the kettle raises the frequencies of the axially symmetric modes, especially the (0,1) mode". "Reducing the kettle volume raises the frequency of the axially symmetric (0,1), (0,2) and (0,3) modes (by increasing the effective stiffness of the enclosed air), but lowers the frequency of the… (1,1), (2,1), (3,1)… modes". "Changing the kettle shape has little or no effect". **[measured + Green-function computation, timpani]** — [Rossing 1992](https://aip.brightspotcdn.com/PTO.v45.i3.40_1.online.pdf)
- Timpani example of how strongly air and cavity reshape ratios: the measured (1,1):(2,1):(3,1) are ≈ 1 : 1.5 : 2 (ideal 1 : 1.34 : 1.66), and (4,1), (5,1) are at 2.44 and 2.90. **[measured]** — [Rossing 1992](https://aip.brightspotcdn.com/PTO.v45.i3.40_1.online.pdf)
- Snare drum example of a cavity-coupled membrane: (0,1) at 183 Hz; (1,1) splits into 275 Hz (heads in antiphase, air sloshing, so the mass loading lowers it) and 344 Hz. **[measured]** — [Rossing 1992](https://aip.brightspotcdn.com/PTO.v45.i3.40_1.online.pdf)
- Players' and simulation listeners' remarks about inharmonicity: listeners to the FDTD friction drum mostly referred to a "metallic" sound, which "perhaps hints at inharmonicity or perhaps was a reaction to playing the instrument with very low damping". **[interpretation]** — [Onofrei thesis 2021](https://projekter.aau.dk/projekter/files/410480603/Real_Time_Implementation_Of_Bowed_Instruments.pdf)
- Friction-drum simulation losses: membrane loss σ0 ∈ [0, 6] s⁻¹ and σ1 ∈ [0, 0.0026] m²/s. The table labels are swapped relative to their units: σ0 [s⁻¹] is the frequency-independent term. The tube's radiation boundary means "even with zero damping, there will still be decay present". **[model parameters, not measured]** — [Onofrei thesis 2021](https://projekter.aau.dk/projekter/files/410480603/Real_Time_Implementation_Of_Bowed_Instruments.pdf)

### Inferences
- **[derived] Axisymmetric partials.** Ideal (0,n) ratios from Bessel zeros 2.405, 5.520, 8.654, 11.79 are 1 : 2.295 : 3.599 : 4.903. The table's 2.296 and 3.600 confirm the first two. These, not the 1.59/2.14 set, are the membrane resonances a centre drive "sees".
- **[derived] The rod or cord mass dominates the moving mass and pulls the pitch down.**
  - Modal mass of the (0,1) mode: M = σ·πa²·J1(2.405)² ≈ 0.27·σπa². For a goat-skin head with an *assumed* σ ≈ 0.3 kg/m² and a = 8 cm, that is **≈ 1.6 g**.
  - A bamboo stick of 5–25 g (assumed) is 3–15× heavier.
  - Membrane stiffness under a small central load of radius b: k ≈ 2πT / ln(a/b). With T = 3000 N/m, a = 10 cm and b = 5 mm, k ≈ 6.3 kN/m.
  - The stick alone then resonates at f ≈ (1/2π)√(k/m): **≈ 180 Hz for 5 g, 100 Hz for 15 g, 80 Hz for 25 g**.
  - The same membrane without the stick would give (0,1) ≈ 380 Hz.

  The stick-loaded centre also makes the "mode" approximately a single-DOF oscillator. This supports the 1-DOF stick-slip picture in Q2. A light horsehair bundle (fanfrnoch, buhai, lion's roar cord) adds little mass, so those instruments are closer to the bare (0,1) + cavity, but the cord's compliance enters in series.
- **[derived] The rod is rigid in the musical range.** Bamboo with an *assumed* E ≈ 15 GPa and ρ ≈ 700 kg/m³ gives c ≈ 4.6 km/s. A 0.30 m rod's first longitudinal mode is then ≈ 3.9 kHz (fixed–free) or ≈ 7.7 kHz (free–free). It acts as a rigid mass below ~1 kHz and could be a squeal or high-resonance source. A horsehair cord under hand tension also has longitudinal and transverse modes. I found no data on them.
- **[derived] Ideal-membrane (0,1) range for cuíca-sized heads.** With an *assumed* σ = 0.3 kg/m² and T = 1000–5000 N/m:
  - a = 7.6 cm (6″ head): **≈ 290–650 Hz**
  - a = 10 cm: ≈ 220–490 Hz
  - a = 12.7 cm (10″ head): ≈ 175–390 Hz

  These are upper bounds before stick-mass loading.
- **[derived] Synth model.** The sound is a locked harmonic series n·f0. Each harmonic is weighted by how close it falls to the (0,2)/(0,3) membrane resonances (≈ 2.3·f0m, 3.6·f0m, where f0m is the stick-free (0,1)) and to cavity or tube resonances. This yields moving formant-like peaks as pitch is bent. A good structure is a self-oscillating 1-DOF exciter (or a pitched pulse train) feeding a small bank of fixed resonators.

### Gaps
- I found no measured mode frequencies, Q values or T60s for any friction-drum membrane, wet or dry, with or without the rod.
- I found no measured skin areal densities or tensions for friction drums. The σ and T used above are assumptions for illustration only.
- I found no measurements of how strongly the wet, heavily damped skin (animal bladder, goat skin) damps modes.

---

## Q4. What do the pot or cavity (Helmholtz resonance, closed volume, open tube) and radiation contribute?

### Takeaway
There are three body types, and they behave differently:
- **Closed vessels** (rommelpot, fanfrnoch pitcher, köcsögduda jug, clay zambomba or caccavella): the air is an extra spring that raises the (0,1) pitch, more so the smaller the pot. This fits the maker statement "the larger the pitcher, the deeper the sound".
- **Open-ended tubes** (cuíca, buhai tub open at both ends): the air column adds quarter-wave resonances that colour the timbre. One snippet-level study says the cuíca body "contributes little".
- **True Helmholtz resonance** applies only if the vessel has a separate opening or neck. I found no measurements for any of these.

### Cited Findings
- Fanfrnoch: "a clay or metal container (often a pitcher) which is covered with a stretched bladder… with a bundle of horsehair passing through the middle… The larger the pitcher, the deeper the instrument's sound. The instrument is played by pulling the horsehair, and tones may be sounded by rubbing the hair with moistened fingers." **[claimed, unreferenced Wikipedia]** — [Wikipedia: Fanfrnoch](https://en.wikipedia.org/wiki/Fanfrnoch)
- Body types **[claimed]** — [Wikipedia: Friction drum](https://en.wikipedia.org/wiki/Friction_drum):
  - cuíca: "open-ended cylinder"
  - buhai: "wooden tub or bucket open at both ends… horsehair 'ox tail'… rubbed with a wet hand… reproduces the sound of oxen mooing"
  - Slovenian lončeni bas: "clay pot, generally between 20 and 40 cm tall… resin-coated hardwood stick of similar length"
  - köcsögduda: "large terracotta or wooden jug… a reed or length of horsehair… rubbed with a wet hand"
- Cuíca heads are "normally 6 to 10 in" in diameter, and the body is metal, gourd or synthetic **[claimed]** — [Wikipedia: Cuíca](https://en.wikipedia.org/wiki/Cu%C3%ADca). The instrument used in Hypercuíca is a "TAKTO… 8 cm × 30 cm, stainless steel, featuring an open body without a closed resonating shell" (dimensions as printed; "8" is probably the head size, likely in inches) **[described]** — [NIME 2026](https://nime.org/proceedings/2026/nime2026_81.pdf)
- JASA 2002 (snippet): for a gourd-bodied cuíca, "the body of the cuica contributes little to the sound". **[measured?, snippet only]** — [JASA 2002](https://pubs.aip.org/asa/jasa/article/112/5_Supplement/2266/548495/An-acoustic-study-of-the-Brazilian-cuica)
- Simulation choice: "For the sizes of typical friction drum tubes, this 1-D wave approximation does not hold… Using the wave speed c_t based on… air would result in a tube tuned to a fundamental frequency that is above what is expected for a typical 'drum' sound." The model therefore uses c_t = 30 m/s (not 343) with L = 0.4 m, area 0.0707 m² and radiation constants α1 = 0.008 s/m, α2 = 4.348 m⁻¹. Sound is taken at the tube's open end, and a listener said the sound "feels like it is coming from 'inside' the instrument". **[interpretation, full]** — [Onofrei thesis 2021](https://projekter.aau.dk/projekter/files/410480603/Real_Time_Implementation_Of_Bowed_Instruments.pdf)
- Kettle shape matters little; kettle *volume* matters (raises axisymmetric modes). **[measured, timpani]** — [Rossing 1992](https://aip.brightspotcdn.com/PTO.v45.i3.40_1.online.pdf)

### Inferences
- **[derived] Closed-pot air spring.** k_air = ρc²·A_eff²/V, with A_eff ≈ 1.356a² for the (0,1) shape (∫J0 over the disc). For a = 8 cm:
  - V = 1 L → ≈ 10.6 kN/m
  - 2 L → 5.3 kN/m
  - 4 L → 2.7 kN/m
  - 8 L → 1.3 kN/m

  These are the same order as the membrane's point stiffness (≈ 6 kN/m above). The pot size therefore really does move the pitch. Quadrupling the volume from 1 to 4 L lowers the total stiffness from ~17 to ~9 kN/m, so f falls by ≈ √(9/17) ≈ 0.73, about −5.5 semitones, with the same head and stick. This matches "larger pitcher = deeper".
- **[derived] Open tube (cuíca).** The membrane end is approximately closed and the far end open, giving a quarter-wave column: f1 ≈ c/4(L + 0.6r). For L = 0.30 m and r = 0.10 m, f1 ≈ 240 Hz, with odd multiples near 715 and 1190 Hz. These act as fixed formant-like bumps under a moving pitch. Onofrei's virtual tube (c_t = 30 m/s, L = 0.4 m) is a deliberate non-physical retuning (quarter-wave ≈ 19 Hz).
- **[derived] Radiation.** At 200 Hz with a = 8 cm, ka ≈ 0.29, so the membrane is a small radiator. A closed pot radiates as a monopole with efficiency ∝ (ka)², which favours higher harmonics: a bright, nasal "buzz" even when f0 is low. For an open tube, the membrane's outer face and the tube mouth radiate in roughly opposite phase at low frequency, which weakens the fundamental further.
- **[derived] Helmholtz resonance proper**, f_H = (c/2π)·√(A_neck/(V·L_eff)), applies only to vessels with a separate open neck (e.g. a pitcher whose spout stays open). I found no source saying whether the fanfrnoch pitcher's spout is open or covered.

### Gaps
- I found no measured cavity resonances, Helmholtz frequencies or radiated spectra for any friction-drum vessel.
- I could not verify whether the fanfrnoch, rommelpot or zambomba vessels are sealed or vented, which decides spring vs. Helmholtz behaviour.
- The German claim (school or university handout snippets) that players choose vessel size and even partly fill it with water to set pitch is unverified; I could not identify the exact source page.

---

## Q5. What controls pitch, loudness, timbre and roughness (tension, finger pressure, wetness, rosin, speed, force)? How does a cuíca player bend pitch?

### Takeaway
- **Pitch** is set by membrane tension, the moving mass (rod or cord) and cavity stiffness. On the cuíca it is bent continuously over **an octave or more** by pressing the head from outside near the rod.
- **Loudness** follows rubbing speed and force (within the locked regime).
- **Timbre and roughness** follow force-to-speed balance, the contact (wet cloth, wet fingers, rosin) and where the head is pressed.

There are no published numbers apart from the simulation's parameter ranges.

### Cited Findings
- The cuíca membrane "can be tensioned by the other hand to control pitch… the cuíca can produce distinct melodic lines spanning an octave or more, depending on finger pressure on the membrane, although producing the desired pitch demands a precise and sensitive connection with the instrument." It is rubbed with "a wet piece of cloth (often a grosgrain ribbon, as preferred by experienced players)". **[described, full]** — [NIME 2026](https://nime.org/proceedings/2026/nime2026_81.pdf)
- "Changing the pressure on the head of the drum from the outside produces the different pitches and timbres." The stick is "rosined and rubbed with a cloth". Timbre: "high-pitched squeaky", a "laughing gourd". **[claimed]** — [Wikipedia: Cuíca](https://en.wikipedia.org/wiki/Cu%C3%ADca)
- Akay: the finger on the membrane "selects the mode of vibration". **[interpretation]** — [Akay 2002](https://www.imperial.ac.uk/media/imperial-college/research-centres-and-groups/dynamics/Akay-Acoustics-of-friction.pdf)
- Generic friction drum: "The membrane may be depressed with the thumb while playing to vary the pitch". Friction comes from a stick or cord "rubbed or moved with a hand, sponge or cloth, generally wet". The Dutch foekepot and Russian gusachok are "rubbed with a rosined stick". **[claimed]** — [Wikipedia: Friction drum](https://en.wikipedia.org/wiki/Friction_drum)
- Lion's roar: "cord is resined and rubbed with coarse fabric or a glove". Traditionally "one hand held the cord taut, the other gripped and slid up the cord". **[claimed]** — [Wikipedia: Lion's roar](https://en.wikipedia.org/wiki/Lion%27s_roar_(instrument)). A maker recommends violin rosin (beeswax as a substitute) and advises against high head tension because "a lower tuning gives a deeper and more complex sound". **[described, snippet]** — [Instructables](https://www.instructables.com/Creating-a-Lions-Roar/)
- Simulation parameter ranges (friction drum, elasto-plastic model) **[model, full]** — [Onofrei thesis 2021](https://projekter.aau.dk/projekter/files/410480603/Real_Time_Implementation_Of_Bowed_Instruments.pdf):
  - **Friction:** Coulomb μC = 0.3; static μS = 0.8; Stribeck velocity v_S = 0.1 m/s.
  - **Contact:** bristle stiffness s0 = 10⁵ N/m; bristle damping s1 = 0.001·√s0; viscous s2 = 4 kg/s.
  - **Noise:** coefficient s3 ∈ [0, 0.04]·f_N, i.e. "white noise to the friction force proportional to the normal force".
  - **Player input:** normal force f_N ∈ [0, 20] N; bow velocity v_B ∈ [0, 0.2] m/s. The snapshot run used f_N = 12 N and v_B = 0.1 m/s.
  - **Membrane:** 0.3 × 0.3 m; ρ = 1400 kg/m³; H = 7 mm; wave speed c_m ∈ [15, 150] m/s ("Tuning").
  - **Vibrato option:** modulates c_m by ±3 m/s at 0–10 Hz.
- Bowed-string analogue: the Schelleng force window narrows as the contact approaches a boundary. Below the minimum force the sound goes to double slip, above the maximum to raucous noise. **[interpretation]** — [Woodhouse & Galluzzo 2004](https://plus.maths.org/old-files/issue31/features/woodhouse/2pdf/index.html/op.pdf)

### Inferences
- **[derived] Pitch bend mechanism (cuíca).** Pressing the head near the rod locally stretches the skin, raising T. Pitch goes as √T, so an octave needs about 4× effective tension. Pressing also shortens the free vibrating radius, which raises f in inverse proportion to the effective a. Fingertip contact adds damping and a nodal constraint (Akay's "selects the mode"), so pressing should brighten and slightly dull the tone at the same time. For synthesis: a bend of 0 to +12…+15 semitones driven by a continuous "press" control, with resonator damping rising with press depth.
- **[derived] Simulation tuning range.** For Onofrei's 0.3 m square membrane, the (1,1)-square fundamental f = c_m·√2/(2L) gives **≈ 35–354 Hz** over c_m = 15–150 m/s. That is about a 10:1 (3.3 octave) virtual tuning range.
- **[derived] Wetness vs. rosin.** Water lubricates skin or cloth and, as in Akay's moist-finger wineglass, gives a clean stick-slip with a modest μS−μk drop. Rosin gives high μS and a steep velocity-weakening drop, so the motion is stronger and noisier, and more temperature-sensitive (rosin's glass transition is near room temperature). A synth "contact" parameter could interpolate μS−μk, the Stribeck velocity and the noise coefficient: wet ≈ small drop and low noise; rosin ≈ large drop and higher noise.
- **[derived] Loudness and speed.** In a locked regime, the oscillation velocity amplitude at the contact scales roughly with rubbing speed v. The force window scales with v (Schelleng), so faster strokes allow harder pressure without raucousness. Slow, heavy strokes cross into the creak/chatter regime (Q2).

### Gaps
- I found no measured cuíca pitch range in Hz (only "an octave or more"), no measured tension, and no data on how press position maps to pitch.
- I found no measurements of the friction coefficients of wet cloth on bamboo, wet fingers on horsehair or reed, or rosin on cord.

---

## Q6. What are the typical sounding pitch ranges, spectra, formant-like resonances and noise components of the different types?

### Takeaway
I found no published pitch ranges in Hz for any type. Descriptions point to:
- **cuíca:** high, squeaky, "laughing", the highest pitched
- **rommelpot, fanfrnoch, buhai, zambomba, putipù:** low grunting or "mooing"
- **lion's roar:** a deep, noisy "roar"

All spectra are harmonic when locked, with a noise floor from the contact.

### Cited Findings
- Cuíca: "high-pitched squeaky timbre… a 'laughing gourd'". The General MIDI kit maps cuíca sounds to the notes F♯5 and G5. These are trigger keys (GM notes 78/79, Mute/Open Cuíca), not sounding pitches. **[claimed]** — [Wikipedia: Cuíca](https://en.wikipedia.org/wiki/Cu%C3%ADca)
- Buhai "reproduces the sound of oxen mooing". Putipù is nicknamed "pernacchiatore" ("raspberry blower") on account of its sound. **[claimed]** — [Wikipedia: Friction drum](https://en.wikipedia.org/wiki/Friction_drum); [Wikipedia: Putipù](https://en.wikipedia.org/wiki/Putip%C3%B9)
- An aggregator states that friction drums concentrate energy below about 200 Hz and produce inharmonic overtones from irregular friction-induced vibrations. **[claimed, unsourced aggregator: low reliability]** — [Grokipedia](https://grokipedia.com/page/Friction_drum)
- Simulation listeners heard the sound as "a low frequency saw", "a cymbal drum contact miced and bowed", "a chair being dragged across the floor", and "metallic". **[described, informal, full]** — [Onofrei thesis 2021](https://projekter.aau.dk/projekter/files/410480603/Real_Time_Implementation_Of_Bowed_Instruments.pdf)

### Inferences
- **[derived] Rough f0 ranges for a synth, from the Q3–Q4 arithmetic. These are not measurements.**
  - **Cuíca** (6–10″ head, open tube, light bamboo stick, high tension): rest pitch roughly 150–500 Hz, bent up an octave or more. Overtones are prominent because of small-radiator filtering.
  - **Closed pot with heavy stick** (rommelpot, putipù, zambomba, lončeni bas): roughly 60–200 Hz.
  - **Large tub, horsehair** (buhai), lion's roar: possibly lower still, with a much noisier spectrum because cord and glove produce irregular slip.
- **[derived] Spectral recipe.**
  1. Harmonic series of f0 with a sawtooth- or pulse-like source, since the stick-slip velocity waveform is asymmetric: a long stick ramp and a short slip.
  2. Multiply by membrane (0,2)/(0,3) peaks, cavity or tube peaks, and a radiation high-pass of about +6…+12 dB/oct below ka ≈ 1, which is ≈ 700 Hz for a = 8 cm.
  3. Add broadband contact noise proportional to normal force, plus random period jitter (aperiodic slips).

### Gaps
- I found no measured f0 ranges, spectra, spectral centroids or harmonic-to-noise ratios for any friction drum type. This is the biggest gap. Analysing recordings, e.g. the Wikipedia Zambomba.ogg and Cuica.wav files linked from those pages, would be the fastest way to fill it.

---

## Q7. Onset and release: how fast does a stroke reach full level, how does it end, and how do pull and push strokes differ?

### Takeaway
I found no measurements. Bowed-string theory predicts an irregular, scratchy onset transient before lock-in, with length set by how force and speed ramp up (the "Guettler diagram"). After the hand stops, the membrane, rod and cavity ring down freely. On a wet skin with a heavy rod that should be short, but I found no decay data.

### Cited Findings
- Bowed string: there is "usually a transient period of non-regular motion of the string which may make the start of the note sound scratchy. A good bow gesture will minimise the length of this transient period, and establish Helmholtz motion quickly". **[interpretation]** — [Woodhouse & Galluzzo 2004](https://plus.maths.org/old-files/issue31/features/woodhouse/2pdf/index.html/op.pdf)
- Guettler proposed the plane of bow force against bow acceleration (the "Guettler diagram") to study which starting gestures give clean attacks. **[interpretation; snippet]** — [Galluzzo PhD thesis, Cambridge 2004](https://www.repository.cam.ac.uk/bitstream/1810/244810/1/Galluzzo%20thesis_root_singleSided3Apr04.pdf)
- JASA 2002 cuíca study examined "time envelopes", but I could not retrieve its results. **[snippet]** — [JASA 2002](https://pubs.aip.org/asa/jasa/article/112/5_Supplement/2266/548495/An-acoustic-study-of-the-Brazilian-cuica)
- In the FDTD friction drum, radiation at the tube end produces decay even with zero membrane damping. The demo had a "long decay of the sound" when damping was minimised. The author's view: "if one focuses on small percussive friction excitations without allowing the membrane to resonate, the app can sound like some of the friction drums in online videos". **[interpretation, full]** — [Onofrei thesis 2021](https://projekter.aau.dk/projekter/files/410480603/Real_Time_Implementation_Of_Bowed_Instruments.pdf)
- Lion's roar is played by sliding a gripping hand along a taut cord ("one hand held the cord taut, the other gripped and slid up the cord"). Fanfrnoch is played "by pulling the horsehair". These are pull strokes, so sound comes mainly during the pull. **[claimed]** — [Wikipedia: Lion's roar](https://en.wikipedia.org/wiki/Lion%27s_roar_(instrument)); [Wikipedia: Fanfrnoch](https://en.wikipedia.org/wiki/Fanfrnoch)

### Inferences
- **[derived] Ring-down.** The Onofrei loss range σ0 ≤ 6 s⁻¹ corresponds to T60 = 6.91/σ0 ≥ 1.15 s from membrane loss alone. That is a model choice, and the author himself found "percussive" settings sounded more realistic. A real wet skin loaded with a hand-held rod or cloth should decay much faster: the hand on the stick damps it at once when the stroke ends. A short synthetic T60 (tens to a few hundred ms) is a reasonable *design guess*, not a measured value.
- **[derived] Onset.** The tone appears once sliding speed exceeds the regime boundary. At stroke start and at each reversal the velocity passes through zero, so every reversal produces a short creak/chatter segment and a brief level dip. This is the source of the instrument's rhythmic "rum-pum" articulation on back-and-forth strokes, which matters for a rhythm instrument.
- **[derived] Push vs. pull asymmetry.**
  - With a cord (fanfrnoch, buhai, lion's roar), only a pull keeps the cord taut and in contact, so sound comes mainly on the pull.
  - With a rigid rod (cuíca, rommelpot, putipù), both directions work. The mean friction force μN deflects the membrane centre statically by about μN/k: for N = 5–20 N, μ ≈ 0.3–0.8 and k ≈ 6 kN/m, that is ≈ 0.25–2.7 mm. In a closed pot, a push stroke compresses the enclosed air and a pull rarefies it. A small pitch and timbre difference between strokes is therefore plausible but unverified.

### Gaps
- I found no measured attack times, decay times or envelope shapes for any friction drum, and no study of push vs. pull differences.

---

## Q8. Which numbers can a synthesizer designer take forward, and how firm is each?

### Takeaway
Only the stick-slip framework (Akay; Woodhouse), membrane and cavity physics (Rossing) and one simulation parameter set (Onofrei) are sourced. Every instrument-specific number is derived or a gap. A practical synth architecture follows directly from these: a self-oscillating friction exciter, or an equivalent pulse/saw source with jitter and noise, at a resonator-set pitch, feeding axisymmetric-mode and cavity resonators, then a radiation filter.

### Cited Findings
- Friction model parameters usable as starting values: μS = 0.8, μC = 0.3, v_S = 0.1 m/s, f_N 0–20 N, v_B 0–0.2 m/s, noise ≤ 0.04·f_N, membrane loss σ0 ≤ 6 s⁻¹, vibrato ±3 m/s at ≤ 10 Hz. **[model]** — [Onofrei thesis 2021](https://projekter.aau.dk/projekter/files/410480603/Real_Time_Implementation_Of_Bowed_Instruments.pdf)
- Membrane mode ratios and the direction of air and volume effects. **[measured/theory]** — [Rossing 1992](https://aip.brightspotcdn.com/PTO.v45.i3.40_1.online.pdf)
- Mode lock-in to one mode plus its harmonics; finger placement selects the mode. **[interpretation]** — [Akay 2002](https://www.imperial.ac.uk/media/imperial-college/research-centres-and-groups/dynamics/Akay-Acoustics-of-friction.pdf)

### Inferences
**[derived] Cheat sheet. Every row below is my arithmetic or assumption, not a measurement.**

| Quantity | Value or rule | Basis |
|---|---|---|
| Sounding pitch | Locked to the (0,1)-like rod + membrane + air mode; harmonics n·f0 | Akay lock-in + centre drive |
| Membrane partners seen by a centre drive | (0,2) ≈ 2.30×, (0,3) ≈ 3.60×, (0,4) ≈ 4.90× the stick-free (0,1) | Bessel zeros |
| Off-centre press | Adds the (1,1) family (1.59, 2.14…), raises pitch, adds damping | Akay qualitative + derived |
| Rod mass effect | f ≈ (1/2π)·√((k_mem + k_air)/(m_rod + ~0.27·σπa²)); a 5–25 g rod gives ~80–180 Hz on a 10 cm, 3 kN/m head (no cavity) | derived |
| Closed-pot stiffness | k_air ≈ ρc²(1.356a²)²/V: ≈ 10.6/5.3/2.7/1.3 kN/m for 1/2/4/8 L at a = 8 cm | derived |
| Open tube (cuíca 30 cm) | Quarter-wave peaks ≈ 240, 715, 1190 Hz | derived |
| Rod longitudinal modes | ≈ 4–8 kHz for a 30 cm bamboo rod (possible squeal) | derived |
| Radiation | ka < 1 below ≈ 700 Hz (a = 8 cm), so the fundamental is weak and the spectrum bright | derived |
| Regimes vs. (v, N) | Low v / high N gives creak/chatter, slip rate below f0; mid gives locked tone; very high N gives raucous noise; low N gives double slip, the same pitch with a thinner tone | Woodhouse + 1-DOF stick-slip |
| Pitch bend (cuíca) | ≥ +12 semitones via press; about 4× tension per octave | NIME 2026 (range) + derived (√T) |

### Gaps
- Every row of the cheat sheet needs checking against recordings. I found no published instrument data to calibrate any of them.
