# What thirty-odd public recordings of friction drums measure (this research's own analysis)

Everything in this file was **measured in this research** on 2026-11-23, on public recordings, with scripts written for the purpose. It is unpublished and unreviewed. **Nobody listened to the recordings**: the analysis ran without audio playback, so every statement about what a sound "is" rests on numbers, the file pages and the uploaders' descriptions. Most files are lossy (Ogg Vorbis, or the 128 kbps MP3 previews Freesound serves), microphones and distances are unknown for all but one series, several takes have room sound or background noise, and almost every instrument is represented by one player and one take. Treat every number as "one player, one microphone, one take". The work exists because the literature gives few of the numbers a friction-drum synthesizer needs: stroke envelopes, pitch movement inside a stroke, release times, stroke rates and how rough the tone is.

## 1. The recordings and the method

### Takeaway
Thirty-three files were analysed. After one duplicate is set aside, that is 32 different recordings from five sources: 6 on Wikimedia Commons, 26 on Freesound (CC0 or CC BY only), and 1 from museum-digital via Europeana. They cover the Czech **fanfrnoch** (one group take only), the Austrian/Styrian **Brummtopf** (stick, at a festival), a **string Brummtopf** (a theatre noise prop), the **cuíca** (18 takes: one samba player's 12-take series, a Pataxó cuíca, a manufacturer demo and others), the Neapolitan **putipù** (8 takes, one player), the Spanish **zambomba** (3 files, of which 2 are the same audio), and the Venezuelan **furruco** (1). No freely licensed recording of a rommelpot/Rummelpott, buhai/bugaj or burczybas was found.

### The files
Licence, author and description were read from each file page through the Commons API, the Freesound sound pages or the Europeana record. "Preview" means the Freesound HQ preview (MP3, 128 kbps) was analysed, not the original upload, because originals need a login.

| # | File | Instrument and context (from the file page) | Licence, author | Length, format |
|---|---|---|---|---|
| C1 | [Skupina famfrnochů.ogg](https://commons.wikimedia.org/wiki/File:Skupina_famfrnoch%C5%AF.ogg) | Czech fanfrnoch: "Hra na fanfrnochy ve skupině" (several fanfrnochs played together), 2013-01-16 | CC BY-SA 3.0, DlouhanJohny | 9.0 s, mono 44.1 kHz Vorbis ~96 kbps |
| C2 | [Friction drum in action.ogg](https://commons.wikimedia.org/wiki/File:Friction_drum_in_action.ogg) | "Ein Brummtopf bei einem steirischen Weinfest in Dornbirn (Vorarlberg)", 2018-09-15; festival background audible in the numbers | CC BY-SA 4.0, Asurnipal | 18.4 s, mono 44.1 kHz FLAC in Ogg |
| C3 | [Zambomba.ogg](https://commons.wikimedia.org/wiki/File:Zambomba.ogg) | "Sonido de la zambomba", 2013-02-22. **The first 2.9 s are one 1.19 s pattern repeated three times** (stroke onsets, levels, pitches and durations repeat exactly), so the file is an edited loop at its start | CC BY-SA 3.0, Poniol | 21.1 s, stereo 44.1 kHz Vorbis ~500 kbps |
| C4 | [Cuica.Cuica.wav](https://commons.wikimedia.org/wiki/File:Cuica.Cuica.wav) | "Cuica sound"; source given as a Pearl Drums YouTube video (NVOtE1qSymU). The licence claim (CC BY-SA 4.0) for a manufacturer's video excerpt is doubtful | CC BY-SA 4.0 as tagged, "Pearl Drums" | 7.7 s, stereo 48 kHz PCM; starts with digital silence |
| C5 | [Cuica01.ogg](https://commons.wikimedia.org/wiki/File:Cuica01.ogg) | "A sound of Cuica", uploaded 2005 by "っ", no other context; background noise only 17 dB under the strokes | CC BY-SA 3.0 | 6.6 s, mono 22 kHz Vorbis |
| C6 | [Cuica02.ogg](https://commons.wikimedia.org/wiki/File:Cuica02.ogg) | as C5 | CC BY-SA 3.0 | 6.1 s, mono 22 kHz Vorbis |
| R2–R13 | reinsamba, pack [Cuica](https://freesound.org/people/reinsamba/packs/1339/): [cuica (2)](https://freesound.org/people/reinsamba/sounds/21720/), [(3)](https://freesound.org/people/reinsamba/sounds/21721/), [(4)](https://freesound.org/people/reinsamba/sounds/21722/), [(5)](https://freesound.org/people/reinsamba/sounds/21723/), [(6)](https://freesound.org/people/reinsamba/sounds/21724/), [(7)](https://freesound.org/people/reinsamba/sounds/21725/), [(8)](https://freesound.org/people/reinsamba/sounds/21726/), [(9)](https://freesound.org/people/reinsamba/sounds/21727/), [(10)](https://freesound.org/people/reinsamba/sounds/21716/), [(11)](https://freesound.org/people/reinsamba/sounds/21717/), [(12)](https://freesound.org/people/reinsamba/sounds/21718/), [(13)](https://freesound.org/people/reinsamba/sounds/21719/) | "Different examples of a samba batucada instrument, making typical squeaking sounds. Marantz PMD 671, OKM binaural or Vivanco EM35." One cuíca player, 12 takes | CC BY 4.0, reinsamba | 2.0–19.1 s; previews (R9, R10, R11 previews at 32 kHz) |
| P1 | REVERBERA, [Cuica Pataxó – complex pitch impulse](https://freesound.org/people/REVERBERA/sounds/850981/) | "Peteleco do Gambito – Cuíca Pataxó – Energetic rhythm" (flicking); the numbers show free-ringing tones, not rubbed ones | CC0 | 11.1 s, preview |
| P2 | REVERBERA, [Cuica Itching – unpredictable variation impulse](https://freesound.org/people/REVERBERA/sounds/850940/) | "Som constante – Cuíca – Aflição" (constant sound) | CC0 | 10.0 s, preview |
| J1 | jackpatrick889, [Cuica 1](https://freesound.org/people/jackpatrick889/sounds/653555/) | "A cuica in an echoey stairwell" (strong reverb, see below) | CC0 | 21.0 s, preview |
| B1–B8 | bbmario, pack [Putipù](https://freesound.org/people/bbmario/packs/6855/): [puti33](https://freesound.org/people/bbmario/sounds/107920/), [putidietro1](https://freesound.org/people/bbmario/sounds/107922/), [putidietromni14](https://freesound.org/people/bbmario/sounds/107928/), [pfischi1](https://freesound.org/people/bbmario/sounds/107891/), [puti31](https://freesound.org/people/bbmario/sounds/107918/), [putidietro12](https://freesound.org/people/bbmario/sounds/107923/), [puti28](https://freesound.org/people/bbmario/sounds/107913/), [puti3](https://freesound.org/people/bbmario/sounds/107916/) | Neapolitan putipù ("caccavella"); the pack text describes a membrane over a resonating chamber with a stick | CC0, bbmario | 34.9, 33.6, 20.5, 11.3, 3.5, 3.7, 0.9, 1.2 s; previews |
| Z1 | ori2001, [zambombaibrasacatalana.wav](https://freesound.org/people/ori2001/sounds/14344/) | zambomba "recorded with minidisc in a popular mallorquí day commemoration in Plaça del Diamant, Barcelona. A blaze sound is audible" (a fire is heard) | CC BY 3.0 | 4.0 s, preview |
| Z2 | pepotx, [zambomba spanish instrument](https://freesound.org/people/pepotx/sounds/417343/) | **the same audio as part of C3**: its 5 ms level trace matches C3 from 7.6 s on, within 2.4 dB on average, against 11.5 dB at other offsets. Which upload is the original is unknown; Z2 is not counted as a separate recording | CC BY 4.0 | 8.9 s, preview |
| F1 | el.papa.montero, [furruco.mp3](https://freesound.org/people/el.papa.montero/sounds/510791/) | Venezuelan furruco: a wooden box with a skin and a rod fixed in its centre (the page text describes it) | CC0 | 13.2 s, preview |
| E1 | [Brummtopf (Inszenierung "Die Bremer Stadtmusikanten")](https://berlin.museum-digital.de/object/245237) ([Europeana](https://www.europeana.eu/item/1612/item_V7DZU6UG7JI44OZRQ7JFFJGKAGCBT4DS)) | a theatre noise prop of Theater Zinnober (in use 1986–2019, built by Günther Lindner): a tea tin covered with a drum skin; a fishing line fixed to a metal disc inside runs out through a hole in the skin and is tied into a groove of a wooden handle; turning the handle with the line taut makes "ein knarzendes Geräusch" (a creak), used for the turning mill wheel | CC BY 4.0 | 20.7 s, MP3 192 kbps |

The searches covered Commons categories "Friction drums" (with cord / with stick / whirling cord), Cuica, Putipù, Rommelpots, Zambombas, Buhay, Burczybas and Fanfrnoch, plus Commons full-text audio search; Freesound searches for cuica, cuíca, friction drum, rommelpot, rummelpott, brummtopf, waldteufel, zambomba, ximbomba, furruco, putipù, buhai, bugaj, kinfuiti, moltrommel, string drum, lion roar; Internet Archive and Europeana searches for the same names. The Commons categories for rommelpot, buhai and burczybas hold only images. The Internet Archive hits (Jerez zambomba songs, for example) carry no licence and are songs with voices, so they were not used. Excluded Freesound items: those under NC licences; a keyboard preset (karch, "sampled from a Yamaha PSR-500"); a sequencer sound and a beatbox sample named cuíca; and two full-ensemble samba or carnival recordings in which the cuíca cannot be separated.

### Method (so that it can be repeated)
- Tools: `afconvert` to 16-bit WAV (it decoded Ogg Vorbis, Ogg FLAC and MP3). A Swift program using Accelerate/vDSP did the signal work, and Python standard-library scripts did the statistics, all kept in the session's scratch folder. The files were analysed at their own sample rates.
- **Frames** every 5 ms: RMS level; f0 by a YIN-type method (30 ms window, 45–2500 Hz, threshold 0.2 on the cumulative-mean-normalised difference, parabolic refinement); **aperiodicity** = that difference value at the chosen lag (0 = perfectly periodic); **HNR** = 10·log10(r/(1−r)) from the normalised autocorrelation r at the chosen lag; spectral centroid above 50 Hz from a ~46 ms Hann FFT.
- **Strokes**: 5 ms RMS every 1 ms, smoothed over 11 ms. A stroke is a run above max(5th-percentile level + 10 dB, 99.5th percentile − 30 dB) that lasts at least 30 ms. Gaps under 20 ms are bridged, and a run is split at a dip of 6 dB or more below the maxima on both sides. This finds both separate strokes and strokes that run into each other with a dip at the reversal. It cannot separate overlapping instruments (C1).
- **Attack** = time from the last point 20 dB under the stroke's peak to the first point within 3 dB of it. **Sustain** = time spent within 6 dB of the peak. **Release** = straight-line fit of dB against time, from the stroke's last point within 6 dB of the peak until −35 dB, the noise floor + 6 dB, the next onset or 800 ms, whichever comes first; it is kept only if it spans at least 12 dB.
- **Pitch inside a stroke**: per-frame f0 with octave errors folded back towards the stroke median (frames 12 ± 1.2 or 24 ± 1.2 semitones off). "Glide" = median of the last quarter against the first quarter of the voiced frames. A **pitch template** = f0 at 5, 10, 20, 40, 60, 80, 100, 150, 200 ms after onset and before the end, in cents re the stroke median, median over strokes.
- **Spectra**: the middle 60 % of each of the 5 loudest voiced strokes, 4096-point Hann (8192/16384 for whole-file or long-stroke spectra). Levels at k·f0 (strongest bin within ±4 %) are given in dB re the strongest component.
- **Roughness**: frame-level jitter = SD of f0 around a 35 ms running median, in cents. This captures 5–35 ms wobble, not cycle-to-cycle jitter. Shimmer = SD of frame level around a 35 ms running median, in dB. **Subharmonic index** = mean level at 0.5, 1.5 and 2.5·f0 minus mean level at 1, 2 and 3·f0; −40 dB or lower means no subharmonic, above −15 dB means a strong one.

## 2. Fundamental, harmonicity, strongest partials, centroid, formant-like peaks

### Takeaway
Every **rubbed** stroke of every instrument sounds as **one harmonic series** whose partials lie within a few to about 20 cents of k·f0 wherever they can be resolved. No stroke showed a membrane-mode spectrum as its main sound. In most instruments the **fundamental is the strongest partial and the spectrum falls steeply** (cuíca: H2 6–28 dB down; fanfrnoch: about −7 dB at H2 and −21 dB at H4; zambomba similar). The **putipù** is the exception: its strongest partials are H5–H6 at about 440–520 Hz, with the fundamental (62–99 Hz) 5–10 dB down, which is a fixed body resonance acting like a formant. The Brummtopf of C2 shows a similar but weaker zone at about 480–570 Hz. Fixed peaks that are not on the series (inharmonic body or membrane modes) appear in the zambomba (306, 420 Hz) and the furruco, and they show up as **pitch jumps to another mode**.

### Cited Findings (measured)
| Rec. | Instrument | f0 of strokes, median [p10–p90] | Levels re strongest, H1 / H2 / H3 / H4 / H5 / H8 / H10 (median of 5 loudest strokes) | Centroid, median per stroke |
|---|---|---|---|---|
| C1 | fanfrnoch (group) | loud strokes 107–133 Hz (5 of 7 at 121–127); quieter strokes of other instruments at 226–313 Hz | 0 / −7 / −12 / −21 / −22 / −29 / −40 dB | 155–182 Hz on the loud strokes (306 Hz over all strokes) |
| C2 | Brummtopf (stick) | two registers: 127–149 Hz and 74–80 Hz (some at 88–118) | high strokes: 0 / −15 / −12 / −6 / −20 / −34 / −44; a low stroke at 77 Hz: 0 / −8 / −4 / −21 / −10 / −17 / – | 218 Hz [105–311] |
| C3 | zambomba | 223 Hz [211–227] | 0 / −16 / −20 / −18 / −39 / −43 / −47 | 260 Hz |
| Z1 | zambomba (Barcelona) | 94 Hz | −28 / 0 / −5 / −9 / −27 / −28 / −37 (strongest at H2–H4, 190–380 Hz) | 264 Hz |
| R2–R13 | cuíca | four registers by take: 329–368 Hz (R5, R6, R8, R9, R10, R13), 750–790 Hz (R2, R3, R4, R12), 850–855 Hz (R7, R11); R10 also has strokes at 640–750 Hz | H1 strongest in 11 of 12 takes; H2 −6 to −28, H3 −14 to −35, H5 −32 to −49, H10 −44 to −69. In R10's five loudest strokes 2·f0 is 6 dB above f0 (the take mixes strokes an octave apart, so this may be register changes inside strokes) | 1.02–1.24 × f0 in 10 takes (379–1058 Hz); 1.65 × f0 in R8 and 1.94 × f0 in R10 |
| C4 | cuíca (Pearl demo) | 491 Hz [282–557] | 0 / −11 / −22 / −33 / −34 / −59 / −58 | 553 Hz |
| C5, C6 | cuíca (2005 files) | 144 Hz, 130 Hz | −1 to −4 / 0 / −3 to −6 / −13 to −18 / −11 to −12 / −22 / −29 | 304, 318 Hz |
| B1 | putipù | 67 Hz [64–76] | −9 / −15 / −12 / −29 / −8 / −9 / −31, **H6 = 0** (≈ 440 Hz) | 248 Hz |
| B2 | putipù | 86 Hz [71–98] | −10 / −11 / 0 / −19 / 0 / −11 / −22 | 373 Hz |
| B3 | putipù | 84 Hz [76–93] | −5 / −10 / −3 / −14 / −5 / −20 / −30 | 313 Hz |
| F1 | furruco | 70 Hz [51–102], not one clean series | strongest peaks at 67–73 and 98–103 Hz, then 182 and 228 Hz | 117 Hz |
| E1 | string Brummtopf | no stable pitch (9 % of frames voiced) | long-term peaks at 107 and 319 Hz; each slip rings at 290–310 Hz | 514 Hz |

- **Harmonicity.** On long, steady strokes the peaks of an 8192-point spectrum lie on the k·f0 grid within ±13 cents for k = 2–10 on the fanfrnoch (C1, 3 strokes, f0 124–126 Hz), within −33 to +6 cents for k = 1–13 on the putipù (B1; most within ±10), within −17 to +11 cents on the Brummtopf (C2), and within about 6 cents on the steady cuíca strokes (R10). A 4096-point fit on the 5 loudest strokes of every file gives mean ratios f(k)/(k·f0) of 0.992, 0.996, 0.999 and 1.000 for k = 2, 3, 4, 5. The window cannot resolve partials closer than about 10 Hz to the grid, and peaks from strokes that glide during the window come out smeared (R2 especially).
- **Fixed off-series peaks.** Zambomba C3, whole-file spectrum (16384 points): besides the series on about 225 Hz there are peaks at 306 Hz (−13 dB re the strongest), 420 Hz (−12), 680, 910 and 1103 Hz. The same peaks are in Z2, which is the same audio. Furruco F1: 67–73, 98–103, 182, 228 and 256 Hz on one 0.4 s stroke. 228/99 = 2.30 is the ratio of the first two axisymmetric modes of an ideal membrane (2.295), but with this few peaks that is suggestive only.
- **Putipù "formant".** Whole-file spectrum of B1: peaks at 69 Hz (−4 dB), 141, 196, **439 Hz (0 dB)**, 513 Hz (−6). B2: 91 Hz (−5), **270 Hz (0)**, H5 at 463 Hz (−3), 1509 Hz (−25). The strongest region stays at 440–520 Hz while the fundamental moves between 62 and 99 Hz, so it belongs to the body, not the source.
- **Brummtopf resonance zone (C2).** Its high strokes (about 143 Hz) have H4 ≈ 570 Hz at −6 dB, above H2 and H3. Its low strokes (77 Hz) have H7 ≈ 540 Hz at −9 dB, and a peak at 564 Hz in one low stroke.

### Inferences (mine)
- The rubbed source locks to one period, as stick-slip friction does. A synth source can therefore be a **harmonic oscillator, pulse train or bowed-string-type loop**, and the membrane/body enters as filtering: one resonance to colour the steep spectrum (fanfrnoch, cuíca, zambomba) or one strong formant at about 450–550 Hz on a low fundamental (putipù, Brummtopf).
- The very steep spectra (cuíca H3 at −14 to −35 dB) are nearly sinusoidal. A plain sawtooth or pulse would be far too bright; something like a sine plus a few harmonics falling about 10–15 dB per octave matches better.

### Gaps
- No calibrated levels and no microphone data except R2–R13. Spectral tilt above about 2 kHz is uncertain on MP3 previews.
- Membrane modes could not be measured directly, because no recording has a struck, unrubbed friction drum except P1 (a flick).

## 3. Pitch movement inside a stroke and between strokes

### Takeaway
**Rhythmic strokes hold their pitch**: within ±0.2–0.5 semitone for fanfrnoch, Brummtopf, zambomba, putipù and the fast cuíca patterns. They often have a small rise of 0.2–0.5 semitone over the first 20–60 ms and a fall of 0.2–0.5 semitone in the last 10–30 ms. The cuíca's **"whoop" strokes rise 2–7 semitones from the onset and arrive within 60–150 ms**, then hold. The large pitch changes happen **between strokes**: registers about an octave apart in the cuíca (333 against 690 Hz) and nearly an octave in the Brummtopf (about 140 against 75 Hz, ≈ 11 semitones). The fanfrnoch's loud strokes drift down by about 0.5–1.5 semitones.

### Cited Findings (measured)
Pitch template (cents re the stroke median at the given ms after onset; "end" = at the end of the stroke):

| Rec. | 5 ms | 10 | 20 | 40 | 60 | 80 | 100 | 150 | end (last 10 ms) | Strokes |
|---|---|---|---|---|---|---|---|---|---|---|
| R2 cuíca 773 Hz | −641 | −599 | −474 | −175 | −69 | −3 | +34 | +35 | +39 | 9 |
| R13 cuíca 362 Hz | −338 | −329 | −281 | −242 | −194 | −136 | −38 | +15 | +6 | 9 |
| R9 cuíca 368 Hz | −263 | −260 | −254 | −226 | −160 | −129 | −33 | +41 | +36 | 8 |
| R5 cuíca 354 Hz | −198 | −200 | −188 | −145 | −89 | −27 | +11 | +37 | +28 | 25 |
| R6 cuíca 354 Hz | – | – | – | −208 | −164 | −88 | −36 | +25 | +16 | 10 |
| R12 cuíca 768 Hz | −125 | −111 | −88 | −44 | −2 | +20 | +33 | +22 | −27 | 17 |
| R10 cuíca (fast) | −10 | −8 | −1 | +9 | +13 | +9 | −8 | −36 | −33 | 133 |
| R8 cuíca (fast) | −10 | −7 | +7 | +1 | +5 | +3 | −2 | −15 | −26 | 52 |
| R11 cuíca 850 Hz | −44 | −41 | −25 | −6 | 0 | +4 | +12 | – | −18 | 10 |
| C3 zambomba | +10 | −2 | +1 | −12 | −11 | +6 | +11 | −28 | −14 | 101 |
| C2 Brummtopf | 0 | 0 | −12 | −26 | −6 | +4 | +11 | +11 | +10 | 54 |
| C1 fanfrnoch | −23 | −10 | +7 | −5 | −17 | +5 | +15 | +2 | +4 | 34 |
| B1 putipù | +48 | +35 | +1 | 0 | +16 | +12 | +7 | −35 | 0 | 42 |

- **Cuíca glide size and speed** (median glide from the first to the last quarter of the voiced frames): +6.6 semitones in R2 (from about 540 to 795 Hz; every one of its 9 strokes is +5.6 to +7.2), +2.9 (R13, R9), +2.3 (R5), +2.2 (R6). Most of the rise happens in the first 40–100 ms: R2 rises about 5.7 semitones between 5 and 60 ms after the onset, roughly 100 semitones per second.
- **Fanfrnoch loud strokes (C1)**: from 132 to 127 Hz, 134 to 121, 130 to 125, 132 to 127, 146 to 127 Hz (start to end quarter), so −0.6 to −2.4 semitones, median about −0.8. The first stroke of the take rose instead (81 to 107 Hz).
- **Between strokes, cuíca R10**: strokes at 326–340 Hz and 636–751 Hz. A 94 ms stretch of a high stroke has its strongest peak at 694 Hz and nothing at 352 Hz (−49 dB), so these are real register changes, not octave errors of the tracker. Ratio 1.9–2.2.
- **Between strokes, Brummtopf C2**: f0 of the 37 strokes within 6 dB of the loudest: 118, 75, 133, 95, 100, 75, 144, 76, 140, 129, 105, 69, 134, 74, 136, 74, 137, 78, 140, 94, 77, 112, 78, 145, 80, 143, 143, 149, 74, 140, 75, 127, 89, 76, 88, 75, 144 Hz. Successive strokes differ by a median of 9.1 semitones, every-other strokes by 2.9: a high-low alternation. Spectra confirm separate series on 131 Hz and on 77 Hz, each with its own fundamental strongest.
- **Zambomba mode jump (C3)**: in about one stroke in five the pitch moves from 201–219 Hz to 289–305 Hz in the last part of the stroke (+5.3 to +7.2 semitones; ratio about 1.40). 289–305 Hz matches the fixed 306 Hz peak of the whole-file spectrum.
- **Flicked cuíca (P1)**: the free ring sits at 300–310 Hz. In the second half of the decay the tracker drops to 152 Hz, and a spectrum of that part has 149 Hz at −9 dB beside 304 Hz at 0 dB: a subharmonic appears as the ring dies (section 6). In the first half 149 Hz is at −19 dB.

### Inferences (mine)
- For a one-note-per-stroke instrument, **pitch per note can be fixed**, with an optional per-note "scoop" (start 2–7 semitones low, arrive in 60–150 ms) as the cuíca voice and a small terminal drop (0.2–0.5 semitone in the last 10–30 ms). Register changes belong to different MIDI notes, not to an envelope.
- The fanfrnoch's slight downward drift suits a slowly falling tension or speed during a pull.

### Gaps
- Only one fanfrnoch take, and it is a group: other instruments sound in the gaps, so the loud strokes' pitch is clean but nothing quieter is.
- The 5 ms frame and 30 ms window blur glides faster than about 20 ms.

## 4. Stroke envelopes: attack, sustain, release, durations, gaps

### Takeaway
Rubbed strokes **reach full level in about 12–40 ms** (cuíca, zambomba, Brummtopf), about 40–90 ms on the fanfrnoch, and **slowly on the putipù (70–230 ms, peak 150–300 ms after onset)**. They **stop fast when the rubbing stops**: 200–730 dB/s (20 dB in 24–76 ms) for the cuíca, zambomba and Brummtopf, about 200 dB/s for the fanfrnoch. Only the putipù tails off slowly (28–56 dB/s, possibly room sound). A cuíca **flicked rather than rubbed** rings at about 120 dB/s (T60 ≈ 0.5 s). Rhythmic strokes last 0.11–0.24 s, fanfrnoch loud strokes 0.34–0.58 s, putipù strokes 0.5–0.9 s.

### Cited Findings (measured)
| Rec. | Strokes | Duration, median [p10–p90] | Within 6 dB of peak | Attack −20 → −3 dB, median [p10–p90] | Release fit, median [p10–p90] → T60; time to fall 20 dB |
|---|---|---|---|---|---|
| C1 fanfrnoch | 34 (7 loud) | all 0.17 s [0.06–0.43]; loud 0.34–0.58 s | loud 0.20–0.27 s | 42 ms [21–88] | −197 dB/s [−536, −64] → 0.30 s; 117 ms |
| C2 Brummtopf | 54 | 0.113 s [0.068–0.134] | 0.080 s | 24 ms [13–52] | −715 [−1157, −448] → 0.08 s; 26 ms |
| C3 zambomba | 101 | 0.145 s [0.071–0.179] | 0.097 s | 31 ms [25–262] | −441 [−593, −111] → 0.14 s; 42 ms |
| Z1 zambomba | 7 | 0.205 s | 0.067 s | 46 ms | −189 → 0.32 s; 69 ms |
| R10 cuíca | 133 | 0.127 s [0.076–0.154] | 0.086 s | 21 ms [14–126] | −678 [−875, −476] → 0.09 s |
| R8 cuíca | 52 | 0.145 s | 0.090 s | 13 ms [11–19] | −586 → 0.10 s; 32 ms |
| R11 cuíca | 10 | 0.147 s | 0.106 s | 21 ms | −725 → 0.08 s; 24 ms |
| R4 cuíca | 17 | 0.164 s | 0.058 s | 12 ms | −495 → 0.12 s; 76 ms |
| R12 cuíca | 17 | 0.178 s | 0.055 s | 14 ms | −210 → 0.29 s; 69 ms |
| R5 cuíca | 25 | 0.189 s [0.167–0.207] | 0.143 s | 29 ms | −458 → 0.13 s; 61 ms |
| R6 cuíca | 10 | 0.188 s | 0.104 s | 27 ms | −325 → 0.18 s; 61 ms |
| R9 cuíca | 8 | 0.240 s | 0.149 s | 28 ms | −320 → 0.19 s; 59 ms |
| R13 cuíca | 9 | 0.237 s | 0.123 s | 36 ms | −267 → 0.23 s; 75 ms |
| R2 cuíca | 9 | 0.158 s | 0.031 s | 20 ms | −196 → 0.31 s; 76 ms |
| C4 cuíca | 25 | 0.173 s | 0.082 s | 20 ms | −225 → 0.27 s; 68 ms |
| P1 flicked cuíca | 35 | 0.157 s | 0.020 s | **8 ms** [7–16] | −119 [−615, −104] → 0.50 s; 73 ms |
| B1 putipù | 42 | 0.51 s [0.05–0.93] | 0.144 s | 173 ms [117–302] | −38 [−58, −24] → 1.6 s; 155 ms |
| B2 putipù | 55 | 0.49 s | 0.128 s | 83 ms | −36 → 1.7 s; 271 ms |
| B3 putipù | 20 | 0.86 s | 0.217 s | 204 ms | −37 → 1.6 s; 232 ms |
| F1 furruco | 51 | 0.19 s | 0.099 s | 71 ms | −110 → 0.54 s |
| E1 string Brummtopf | 219 slips | 0.066 s | 0.013 s | 9 ms | −462 → 0.13 s; 37 ms |
| J1 cuíca, stairwell | 60 | 0.27 s | 0.145 s | – | −47 dB/s (the room's reverb) |

- **Level template** (dB re the stroke peak at ms after onset; median): cuíca R10 −11 (5 ms), −8 (10), −3 (20), −1 (40–60), −4 (100), −13 (150). Zambomba C3: −17, −16, −15, −8, −2 (60), −1 (80–100), −5 (150). Brummtopf C2: −26, −25, −19, −8, −4, −2 (80–100). Putipù B1: −26, −25, −24, −21 (40), −16 (60), −14 (100), −11 (150), −10 (200), −6 (300), −12 (500).
- **Before the end** (dB re peak, ms before the stroke's end): cuíca R10 −2 (50 ms), −3 (30), −5 (20), −10 (10), −18 (0). Brummtopf C2 −3 (50) to −3 (0), then the 26 dB drop happens within the next 40 ms. Zambomba −1 (50), −4 (20), −8 (0).
- **Gaps** (end of one stroke to the next onset, median): R10 27 ms, R8 1 ms (strokes run into each other with a dip), R4 1 ms, C3 34 ms, C1 1 ms (overlap), C2 148 ms, B1 363 ms, R2 541 ms.

### Inferences (mine)
- A friction stroke is **gated by the rubbing**: a quick rise, a plateau while the stick or hand moves, and a fast fall when it stops, without the long free ring of a struck drum. A model for "one MIDI note = one stroke" can use an attack of about 10–40 ms (up to 200 ms for a putipù voice), a hold of 0.05–0.25 s that sets the stroke length, and a release of about 20 dB per 25–75 ms (T60 0.08–0.3 s). The membrane's own ring after the stick stops is short. The only free-ring measurement, the flicked cuíca, gives T60 ≈ 0.5 s, so a little residual ring after the gate closes is plausible.
- The putipù's slow, swelling stroke and long tail is a distinct envelope class.

### Gaps
- The putipù's 1.6 s T60 may be room sound (the recording room is not described). The stairwell take J1 shows how a room drags release down to about 47 dB/s.
- Attack resolution is about 5 ms (window length). The first stroke after silence and strokes in a run were not separated.

## 5. Tempo, accents, push vs pull

### Takeaway
Stroke rates run from **about 1 per second (putipù, fanfrnoch loud strokes) to 7.4 per second (cuíca samba patterns)**, with intervals as short as 85–90 ms. Several takes show a **two-stroke alternation**: in level (cuíca R12, R4: successive strokes ±6 dB, signs alternating), in pitch register (Brummtopf C2: high/low about 11 semitones apart, 0.45 s apart), or a **four-stroke low-low-high-high cycle** (cuíca R10). Push and pull of the stick or hand plausibly cause the two-stroke patterns, but which stroke is which direction cannot be read from the audio.

### Cited Findings (measured)
| Rec. | Onset interval, median [p10–p90] | Rate | Pattern |
|---|---|---|---|
| C1 fanfrnoch | loud strokes 0.932 s [0.862–0.956]; all 0.184 s | 1.07 loud strokes/s | a loud low stroke every 0.93 s with 2–4 quieter higher strokes (226–313 Hz, −5 to −12 dB) between, probably other players |
| C2 Brummtopf | strong strokes 0.454 s [0.194–0.789]; all 0.287 s | 2.2 /s | high/low register alternation (section 3); the high strokes are −1.8 to +1.3 dB, the low ones −1.4 to −5.3 dB (re the take's 99.5th-percentile level); quiet 64–71 Hz strokes (−8 to −22 dB) in the gaps |
| C3 zambomba | 0.169 s [0.104–0.328]; strong 0.293 s | 5.9 /s | first 2.9 s a repeated 1.19 s pattern (edited) |
| R10 cuíca | 0.136 s [0.089–0.192] | 7.35 /s | low-low-high-high cycles: 331 334 337 339 326 340 636 328 336 689 644 … Hz; within a low pair the first stroke is often 2–4 dB louder and 20–40 cents lower, but not consistently (the signs of successive level differences are irregular over the whole take) |
| R8 cuíca | 0.147 s [0.125–0.201] | 6.8 /s | steady pitch, no regular alternation (signs of successive level differences irregular) |
| R4 cuíca | 0.141 s [0.085–0.195] | 7.1 /s | successive level differences −+−+−+…, median size 6.1 dB |
| R12 cuíca | 0.216 s | 4.6 /s | −+−+−+…, median size 6.5 dB |
| R5 cuíca | 0.233 s [0.213–0.254] | 4.3 /s | very regular (interval p10–p90 within ±20 ms), every stroke a +2.3 semitone scoop |
| R2 cuíca | 0.707 s | 1.4 /s | one scoop every 0.7 s |
| P1 flicked cuíca | strong 0.498 s | 2.0 /s | – |
| B1 / B2 / B3 putipù | 0.82 / 0.62 / 0.97 s | 1.0–1.6 /s | – |
| F1 furruco | 0.214 s; strong 0.277 s | 4.7 /s | the tracker's f0 alternates about 50–56 and 100–105 Hz (ambiguous, section 6) |
| E1 string Brummtopf | 0.072 s [0.045–0.165] | 13.9 slips/s | creak, not strokes (section 6) |

### Inferences (mine)
- A rhythm-oriented synth should expect **note rates up to about 7–11 per second** (intervals down to 90 ms) with the release finished before the next note. Given the fast releases measured, retriggering need not crossfade a long tail.
- An "alternate" mode (velocity- or note-paired) that gives every other stroke −3 to −6 dB and a slightly different pitch or brightness would mimic the push/pull pairs. That is a design suggestion, not a measured fact about direction.

### Gaps
- No recording names the stroke direction, and no recording has a single player alone on a fanfrnoch, so the fanfrnoch's own pull/release pattern is unknown.

## 6. Roughness: jitter, shimmer, subharmonics, noise

### Takeaway
Cuíca strokes are the cleanest: **HNR 14–27 dB, frame jitter 3–16 cents**, no subharmonics. Zambomba and Brummtopf are mid (HNR 10–14 dB). Putipù, furruco, the fanfrnoch group and the flicked cuíca are rough (HNR 5–9 dB). **Subharmonics are absent in almost all rubbed strokes** (index −20 to −55 dB). They appear strongly only in the **furruco** (index −2 to −7 dB) and in the **dying ring of the flicked cuíca** (f0/2 at −9 dB). The string Brummtopf shows the other kind of roughness: **slips too slow to fuse into a pitch** (14 per second, each ringing a 300 Hz mode for 30–40 ms), i.e. a creak.

### Cited Findings (measured)
| Rec. | HNR, median [p10–p90] | Aperiodicity, median | Frame jitter, median | Shimmer, median | Subharmonic index, 5 loudest strokes |
|---|---|---|---|---|---|
| R2–R13 cuíca | 13.7–27.0 dB (per take) | 0.00–0.05 | 3–16 cents | 0.6–1.3 dB | −15 to −59 (mostly ≤ −30) |
| C4 cuíca | 14.4 [7.2–20.2] | 0.05 | 24 c | 0.76 | −15 to −52 |
| C5/C6 cuíca | 14.5 / 10.9 | 0.08 / 0.15 | 9 / 9 c | 0.71 / 0.53 | −16 to −24 |
| C3 zambomba | 14.0 [8.2–18.8] | 0.10 | 32 c (includes the mode jumps) | 0.81 | −44 to −46 |
| C2 Brummtopf | 9.9 [7.0–13.8] | 0.24 | 12 c | 0.91 | −22 to −27 |
| C1 fanfrnoch | 5.9 [3.5–8.6] all; 8–13 on loud strokes | 0.33 | 20 c | 0.71 | −15 to −25 |
| B1–B3 putipù | 5.9–8.7 | 0.18–0.38 | 5–11 c | 0.44–0.51 | −6 to −30 |
| F1 furruco | 5.0 [3.3–7.0] | 0.38 | 46 c | 0.76 | **−2 to −7** |
| P1 flicked cuíca | 6.0 [4.0–8.4] | 0.28 | – (pitch halves) | 1.01 | −4 to −16 |
| P2 cuíca "constant" | 9.9 | 0.15 | 8 c | 0.34 | −7 to −17 |
| E1 string Brummtopf | 4.4 | 0.47 | – | 1.83 | – |

- **String Brummtopf slip train (E1)**, a 0.6 s stretch at 5.0–5.6 s: level jumps of about +20 dB at 5.05, 5.10, 5.14, 5.20, 5.27, 5.32, 5.44, 5.48, 5.51 and 5.59 s (40–120 ms apart). After each jump the tracker finds 288–308 Hz (and 150–159 Hz) while the level falls 10–16 dB over 30–50 ms (release fit over all slips −462 dB/s). Between slips the centroid is 450–550 Hz and the aperiodicity 0.5–0.7.
- **Flicked cuíca (P1)**, stroke at 0.73 s: a noisy onset of about 20 ms (centroid 700 Hz, aperiodicity about 0.5), then a clean 301–310 Hz tone (aperiodicity 0.04–0.08) falling from −4 to −18 dB in 0.11 s. From 0.87 s the period doubles (152 Hz, aperiodicity 0.11–0.26) while the level goes on falling.
- **Background levels** (5th-percentile level re the 99.5th): C2 −33 dB (festival), C3 −30 dB, J1 −26 dB (reverb), C5/C6 −17 dB (noise), reinsamba takes −52 to −62 dB (clean) except R10 and R5 (−30 dB, the rhythm runs throughout).

### Inferences (mine)
- A clean friction voice (cuíca) needs almost no added noise. HNR around 15–25 dB corresponds to a noise floor some 15–25 dB under the tone. A rough voice (fanfrnoch, putipù, furruco) sits at 5–9 dB HNR, which a model could get from rubbing noise mixed in at about −6 to −10 dB re the tone, plus a few tens of cents of slow pitch wobble.
- The creak of E1 and the period doubling in P1 suggest a **friction model with a slip rate that can fall below about 20–40 Hz** (giving a crackle that rings the body) or **bifurcate to f0/2** at low drive. These are two "roughness" behaviours a physical friction model produces by itself. A source-filter model would need them added.

### Gaps
- The jitter is frame-level (5–35 ms scale). Cycle-to-cycle jitter was not measured.
- The fanfrnoch's low HNR is partly the overlap of several instruments.

## 7. What holds across the recordings, and what to listen to

### Takeaway
Across 32 recordings of seven kinds of friction drum: **(1)** a rubbed stroke is a **steady harmonic tone**, usually fundamental-dominant, sometimes with a body formant at about 450–550 Hz. **(2)** The **envelope is gated by the rubbing**: a 10–40 ms attack (70–230 ms on the putipù), a plateau, and a 20 dB fall in 25–75 ms. **(3)** Pitch is held within a stroke except for **cuíca scoops of 2–7 semitones arriving in 60–150 ms** and **register changes between strokes of up to about an octave**. **(4)** Rates run up to about **7 strokes per second**, often in alternating pairs. **(5)** Roughness ranges from nearly pure (cuíca) to an HNR of 5 dB, and subharmonics and creak appear only at low drive or with slow slips.

### Cited Findings (measured; see sections 2–6 for per-file numbers)
- f0 ranges by instrument: fanfrnoch loud voice 107–133 Hz (C1); stick Brummtopf 66–149 Hz (C2); putipù 62–99 Hz (B1–B8); zambomba 94 Hz (Z1) and 203–228 Hz (C3); furruco about 50–105 Hz (F1, ambiguous); cuíca 130–145, 270–370, 640–860 Hz (C4–C6, R2–R13, P1).
- Centroid relative to f0: cuíca 1.02–1.24 × f0 in 10 of 12 reinsamba takes; fanfrnoch loud strokes 1.25–1.45 × f0; zambomba 1.15 × f0; putipù 3.7–4.3 × f0 (because of the formant).

### Listening list (the best references for the author; all URLs above)
1. **[Skupina famfrnochů.ogg](https://commons.wikimedia.org/wiki/File:Skupina_famfrnoch%C5%AF.ogg)**, the only freely licensed fanfrnoch: loud 0.34–0.58 s strokes at about 124–127 Hz every 0.93 s, falling about 1 semitone, plus higher instruments in between.
2. **[Friction drum in action.ogg](https://commons.wikimedia.org/wiki/File:Friction_drum_in_action.ogg)**, a Brummtopf played rhythmically: short (0.11 s) strokes with very abrupt ends, alternating about 140 Hz and about 75 Hz.
3. **[reinsamba cuica (2)](https://freesound.org/people/reinsamba/sounds/21720/)**, the clearest cuíca scoop: +6.6 semitones in about 80 ms, one stroke every 0.7 s.
4. **[reinsamba cuica (5)](https://freesound.org/people/reinsamba/sounds/21723/)** and **[(9)](https://freesound.org/people/reinsamba/sounds/21727/)**: regular strokes at about 354/368 Hz, each with a +2.3 to +2.9 semitone scoop.
5. **[reinsamba cuica (10)](https://freesound.org/people/reinsamba/sounds/21716/)**: 19 s of fast samba cuíca at 7.4 strokes/s, low and high registers an octave apart.
6. **[reinsamba cuica (4)](https://freesound.org/people/reinsamba/sounds/21722/)** or **[(12)](https://freesound.org/people/reinsamba/sounds/21718/)**: loud/soft alternation of about 6 dB on successive strokes.
7. **[bbmario puti33](https://freesound.org/people/bbmario/sounds/107920/)** and **[putidietro1](https://freesound.org/people/bbmario/sounds/107922/)**: the putipù's slow, swelling strokes, low fundamental and 440–520 Hz formant.
8. **[Zambomba.ogg](https://commons.wikimedia.org/wiki/File:Zambomba.ogg)**: a 223 Hz zambomba with jumps to about 300 Hz at some stroke ends (the start is an edited loop).
9. **[REVERBERA Cuica Pataxó](https://freesound.org/people/REVERBERA/sounds/850981/)**: a flicked cuíca, the free ring (about 300 Hz, T60 about 0.5 s) and period doubling as it dies.
10. **[museum-digital Brummtopf](https://berlin.museum-digital.de/object/245237)**: the creak of a string friction drum, slips too slow to make a pitch.

### Inferences (mine)
- One engine with a few per-voice parameters covers all of these: f0; spectral tilt or formant (fundamental-dominant against a 450–550 Hz formant); attack 10–200 ms; hold; release 25–75 ms per 20 dB; optional onset scoop (depth 0–7 semitones, time 60–150 ms); terminal drop (0.2–0.5 semitone); noise mix (HNR 5–25 dB); and a "low drive" mode giving period doubling or creak.

### Gaps
- No rommelpot/Rummelpott, buhai/bugaj or burczybas recordings with a free licence were found. The fanfrnoch is represented by one 9 s group take at 96 kbps. A dedicated solo recording would be the most valuable addition.
- No recording is calibrated. Push against pull is inferred only from alternation patterns.
