# Fanfrnoch listening prototype — what to listen to

Throwaway prototype `fanfrnoch_spike.cpp`: the research report's "prescribed slip clock"
(`../reports/Friction drum acoustics and playing.md`, "Recommendation for the engine").
Renders in `renders/` (48 kHz, 24 bit, mono, each file peak-normalised to −1 dBFS, so
loudness differs between files only by normalisation). Reference recordings (public, CC0 /
CC BY / CC BY-SA, for listening only, never shipped) in `renders/references/`.

Rebuild: `clang++ -std=c++17 -O2 fanfrnoch_spike.cpp -o fanfrnoch_spike && ./fanfrnoch_spike renders`

Checked without listening against the measured recordings (the research's own analysis tool):
the default stroke's harmonics H2 −9, H3 −14, H4 −20, H5 −22, H8 −30 dB (fanfrnoch take:
−7, −12, −21, −22, −29); HNR 12.4 dB (8–13 on the take's loud strokes); centroid 190 Hz
(155–182). The cuíca samba: HNR 20.9 dB (14–27 measured).

| Question (report §"Fourteen questions") | Files | Compare with |
|---|---|---|
| 1 Drum or synthesizer? | `01a` pulls, `01b` groove, `01c` group | `references/R1` |
| 2 How long is a pull? | `02_length_100/230/450ms`, `02d_keyup_stop` | |
| 3 How rough? | `03a` smooth, `03b` default, `03c` rough | `R1` |
| 4 How bright? | `04_stick_0.80/0.88/0.93`, `04d` no darkening, `04e` strong darkening | |
| 5 Does it need a pot? | `05_pot_500Hz_plus6dB` vs `01a` | `R2`, `R6` |
| 6 Drift | `06_drift_0` vs `01a` | |
| 7 Attack | `07_attack_15ms` vs `01b` | |
| 8 Release and ring | `08a_release_600dBps`, `08b_damp_50` vs `01b` | |
| 9 Two hands | `09a/b/c` (fast sixteenths) | |
| 10 The onset | `10_scrape_0/10/40` | |
| 11 Creak and split | `11a_creak_40`, `11b_split_50` | `R7` |
| 12 Cuíca | `12a` soft whoop, `12b` whoop, `12c` samba | `R3`, `R4` |
| 13 One drum | `13a` mono (phase carried) vs `13b` poly restarts | |
| 14 Range | `14_range_294Hz/62Hz_track0/100` | |
| Programs | `P01` Brummtopf … `P09` kit | `R2`, `R5`, `R6` |

Findings from the author's ear go into the engine design (`.planning/specs/`).
