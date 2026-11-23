# The wet hand switches a locked tone on and off; the drum decides its pitch

A friction drum is a bowed instrument in disguise. A wet hand, a wet cloth or a rosined glove slides along a stick or a bundle of horsehair fixed to the centre of a skin, and the stick–slip contact locks onto one vibration of the loaded skin and repeats once per period. The pitch therefore belongs to the drum: the tension of the head, the mass hung at its centre and the air in the pot set it. The hand sets only how loud, how bright and how rough the tone is, and how long it lasts ([Akay 2002](https://www.imperial.ac.uk/media/imperial-college/research-centres-and-groups/dynamics/Akay-Acoustics-of-friction.pdf); [Woodhouse and Galluzzo 2004](https://plus.maths.org/old-files/issue31/features/woodhouse/2pdf/index.html/op.pdf); [sound notes](../research_notes/Friction%20drum%20acoustics%20and%20playing/sound_production.md)). The Czech fanfrnoch (famfrnoch, bručák, brumbál, bukač) is the cord type of the family. It is a clay or tin jug covered with bladder or leather, with usually two bundles of horsehair threaded through its centre. The player holds it between the knees and pulls the bundles alternately with both wet hands. It is a "rhythmic, accompanying instrument" of New Year and Christmas carolling from Chodsko ([cs.wikipedia](https://cs.wikipedia.org/wiki/Fanfrnoch); [Nesladkář](https://nesladkar.cz/blog-post/vyrob-si-fanfrnoch/)). Its relatives fall into three groups. A western zone has stick pots: the Brummtopf/Rummelpott, the rommelpot, the zambomba and the putipù. An eastern zone has large, often bottomless horsehair barrels that "bellow like a bull": the buhai, the buhay and the burczybas. The third is the Brazilian cuíca, the one member played melodically: the second hand presses the head to bend the pitch by an octave or more ([instruments notes](../research_notes/Friction%20drum%20acoustics%20and%20playing/instruments_and_construction.md)). No published measurement gives the pitch, spectrum or envelope of any friction drum, so this research measured 32 public recordings itself ([recordings notes](../research_notes/Friction%20drum%20acoustics%20and%20playing/recordings_measured.md)). It found the following. Every rubbed stroke is one harmonic series, true to about ±13 cents; usually the fundamental is the strongest partial and the harmonics fall 12–20 dB per octave. The rubbing gates the sound: a stroke reaches full level in 12–40 ms (42 ms on the only fanfrnoch recording, a group take at about 125 Hz) and falls 20 dB in 25–120 ms once the hand stops (the putipù swells and fades more slowly). Strokes hold their pitch, except for cuíca scoops of 2–7 semitones that arrive within 60–150 ms. Fast playing reaches 7.4 strokes per second, often in alternating pairs. Written rhythms barely exist: samba tempi of 80–130 bpm (sixteenths of 115–190 ms) are the only numbers, and the folk drums mark the beat of processional songs. The one published physical model, an FDTD bowed membrane on a tube, costs about 6,000–10,000 operations per sample, and its listeners did not recognise it as a friction drum; every commercial cuíca is a sample library ([synthesis notes](../research_notes/Friction%20drum%20acoustics%20and%20playing/synthesis_and_prior_art.md)). This report recommends a **prescribed slip clock**:

- a phase oscillator at the MIDI pitch, its cosine warped so that each period is a slow stick and a fast slip (a stick fraction of 0.88 matches the fanfrnoch's harmonics within 2.2 dB rms, 0.73 the cuíca's within 3.5 dB);
- a stroke envelope that switches it on and off, whose rise and fall behave like one resonator in 12 of 19 takes;
- roughness written into the model: jitter, rub noise, period halving and creak;
- two fixed body resonances for colour.

It costs about 50 operations per voice and sample. Nobody has measured a solo fanfrnoch, the difference between push and pull, a rommelpot, a buhai or a burczybas. Those, and whether the model sounds like a drum rather than a synthesizer, are left to the author's ear.

*Evidence labels used throughout.* **Measured** is a published measurement: a museum catalogue's dimensions or a dataset's annotations are named as such. **Measured here** is this research's own analysis of 32 public recordings from Wikimedia Commons, Freesound and museum-digital, made on 2026-11-23 with scripts written for the purpose. Nobody listened to the recordings during the analysis. The work is unpublished and unreviewed; most files are lossy; almost every instrument is one player and one take; and the only fanfrnoch is a 9-second group take. **Authors' interpretation** is a published researcher's own model or explanation, including simulation results. **Observed** is an ethnomusicologist's field description. **Described** is a player's, teacher's or maker's own account, or a museum or ethnographic description of construction and use. **Claimed** is a statement by a vendor, an encyclopedia or an aggregator, without a stated basis. **Derived in the notes** is arithmetic or reasoning done by this project's research notes from standard physics or from cited numbers; most of it rests on assumed skin densities and tensions, and none has been checked against an instrument. **Derived here** is this report's own arithmetic on the notes' numbers. **Proposal** is this report's own design suggestion; none of it has been heard. "Snippet" marks a claim taken from a search-result excerpt, "abstract" a paper of which only the abstract was read. Translations from Czech, German, Dutch, Hungarian, Romanian, Polish, Spanish, Italian and Portuguese are the notes'. No source was re-read for this report. Reading depth is as the notes record it, and where a note "read in full" through a fetch tool that returns a summary with short verbatim quotes, the quotations are as the notes give them.

## The instruments: one mechanism, three things to rub, two kinds of body

### Hornbostel–Sachs splits stick, cord and hand drums, and the fanfrnoch is a cord drum

**Described (classification).** Class 23 of the Hornbostel–Sachs system has three branches:

- **Stick drums (231):** a stick goes through the membrane (231.1) or is tied upright to it (231.2). In 231.11 the stick is fixed and is itself rubbed: the rommelpot and the cuíca.
- **Cord drums (232):** a cord attached to the membrane is rubbed. In 232.1 the drum stays still while played (232.11 with one membrane, for example the buhay). In 232.2 it is whirled on its cord around a notched, rosined stick: the Waldteufel type.
- **Hand friction drums (233):** the membrane itself is rubbed, as in a tambourine thumb roll.

This is from a Wikipedia transcription of the classification, which also lists the cuíca under 232.11 by mistake ([H–S list](https://en.wikipedia.org/wiki/List_of_membranophones_by_Hornbostel%E2%80%93Sachs_number); [Wikipedia: Friction drum](https://en.wikipedia.org/wiki/Friction_drum)). The primary text of the classification was not reached.

**Derived in the notes.** Three axes matter for sound: what is rubbed, what rubs it, and what body it sits on. A rigid rod couples the friction straight into the centre of the skin and has its own longitudinal modes; on a 30 cm bamboo rod they lie at about 4–8 kHz, a possible squeal. A horsehair bundle is a flexible link that works only in tension, made of many hairs that each catch and slip at their own moment. That should give a noisier, more granular excitation, and it means sound comes mainly on the pull ([instruments notes](../research_notes/Friction%20drum%20acoustics%20and%20playing/instruments_and_construction.md); [sound notes](../research_notes/Friction%20drum%20acoustics%20and%20playing/sound_production.md)). The words the sources use follow this split. Rod drums "hum" (*brummend*), make a "frroep" or sound "like a double bass". Horsehair drums "bellow", "low like a bull" or "growl".

### The fanfrnoch: a jug, a bladder and two bundles of horsehair, pulled by wet hands

**Described.** The Czech Wikipedia article calls the fanfrnoch an old Czech folk rhythmic instrument from Chodsko, a membranophone of "neurčitá výška tónu" (indefinite pitch). Its parts:

- **Body:** a clay or tin vessel (*hliněná nebo plechová nádoba*), typically a jug.
- **Membrane:** animal bladder or skin (*měchýř / kůže*) stretched over the mouth.
- **Friction element:** a bundle of horsehair (*svazek žíní*), usually two, threaded through the middle of the membrane.

The player wets the fingers and pulls them along the hair, usually holding the instrument between the knees and playing alternately with the left and right hand. Two-person play is also known: one person holds the vessel and the other plays, which suits walking. Traditionally only boys and men played it. It accompanied carolling at New Year and Christmas, and the article remarks on the comic character of the performance ([cs.wikipedia: Fanfrnoch](https://cs.wikipedia.org/wiki/Fanfrnoch), which cites Vykoukal 1901, Modr 1981 and Baar and Lužík 1976).

A maker's blog adds more:

- **Body:** "an old jug, a pot, or even a small barrel".
- **Assembly:** the neck is covered with a leather membrane, a hole is made in its middle, and bundles of hair are threaded through it.
- **Playing:** both hands alternately, "which the player must first dip in water or wet with saliva". Vinegar was once used for a better sound.
- **Tuning:** by "changing the length of the horsehair or the tension of the membrane".
- **Role:** "only a rhythmic, accompanying instrument" that cannot play melodies.

([Nesladkář: Vyrob si fanfrnoch!](https://nesladkar.cz/blog-post/vyrob-si-fanfrnoch/)). A South Bohemian Museum notice about a maker's demonstration agrees: a jug or a tin or wooden vessel, a membrane "much like a small drum", horsehair pulled to make the sound, held between the knees, played left and right alternately ([Jihočeské muzeum](https://www.jcted.cz/vite-co-je-fanfrnoch-ve-ctvrtek-muzete-videt-jak-se-vyrabi/?liveMode=1)). Dictionary entries place it in Bohemia, Moravia and Silesia; *brumbál* and *bručák* come from *brumlat* and *bručet*, to drone or grumble (snippet: [Hudební scéna](https://www.hudebni-scena.cz/slovnik-hudebnich-pojmu/famfrnoch-fanfrnoch-99); [cs.wikipedia: Brumbál](https://cs.wikipedia.org/wiki/Brumb%C3%A1l)).

**Claimed.** "The larger the pitcher, the deeper the instrument's sound" ([Wikipedia: Fanfrnoch](https://en.wikipedia.org/wiki/Fanfrnoch), unreferenced); the Czech article says a larger vessel gives a "deeper, stronger" tone.

**Not found.** No Czech source gives a dimension, a pitch, a sound description beyond "deeper, stronger" against "higher", or any rhythm. No museum record of a fanfrnoch with measurements was found (an eSbírky search returned nothing relevant), and no source mentions a stick or rosin on the Czech instrument. A New Year carol with fanfrnoch exists as an audio podcast; nobody has listened to it ([iFolklor](https://www.ifolklor.cz/audio-podcasty/ifolklorni-zpevnik/novorocni-koleda-s-fanfrnochem/), snippet).

**Derived in the notes.** The fanfrnoch puts the eastern excitation, horsehair, on the western body, a closed pot. That may be why Czech sources call it smaller and higher than the bull-roaring Romanian and Kashubian barrels; no source compares them directly. In synth terms it is **a two-strand horsehair drum played alternately**: each pull is one burst, and two hands make a natural "grunt–grunt" pulse.

### Central Europe splits into western stick pots and eastern horsehair barrels

**Described.** The stick pots:

- **German and Austrian Brummtopf** (Rummelpott, Fukkepott, Büllhäfen; Waldteufel in Prussia and Berlin): a one-headed pot of clay or wood, some "partly filled with water". A notched stick is set into a tied-off spot at the centre of the skin, and rubbing it by hand or with a damp cloth makes a "brummendes Geräusch". Different pots are used for different pitches ([de.wikipedia: Brummtopf](https://de.wikipedia.org/wiki/Brummtopf)).
- **Dutch and Flemish rommelpot:** an earthenware pot under a pig's bladder, with a stick "coated with resin to make it grip", set vibrating "with a rubbing motion". It is "not very melodious", a "frroep" sound like an asthmatic wheeze, and serves as rhythmic accompaniment to solo song ([nl.wikipedia: Rommelpot](https://nl.wikipedia.org/wiki/Rommelpot_(muziekinstrument))).
- **Hungarian köcsögduda:** has both forms, "a reed about a span long, or a horsehair bundle a few spans long". Pulled with a wet finger or hand, it "hops, rumbles, or gives a sound like a bull's bellow" and stands in for the double bass ([Magyar Múzeum](https://magyarmuzeum.org/neprajz/magyar-nepi-hangszerek/kocsogduda/kocsogduda/)).

The eastern horsehair drums:

- **Romanian buhai:** in the Horniman Museum, a staved shell **open at the base**, **315 × 287 mm**, with rabbit skin with the fur left on and a hank of horsehair **670 mm** long. The player pulls wet hands alternately along it, and its name, "bull", is "the bellowing of this animal that the instrument is thought to resemble" (measured, catalogue; [Horniman M90-1983](https://horniman.ac.uk/object/M90-1983)).
- **Kashubian burczybas:** a museum specimen measures **435 × 390 mm**; one person holds it while another rubs the hair with wet hands, which "produces a low sound" (measured, catalogue; [Szydłowiec museum](https://artsandculture.google.com/asset/friction-drum-with-a-cord-walkusz-jerzy/8QGCxqcK_q7sSQ?hl=en)). Polish sources add a glove rubbed with rosin, and an ensemble practice with one holder, one person pouring water and one puller (snippet, [pl.wikipedia](https://pl.wikipedia.org/wiki/Burczybas)).
- **Ukrainian buhay:** a conical barrel or bucket under sheep membrane. "You pull up, and then the membrane returns into position", and "the pitch of sound changes depending on where your hand stops on the bunch" ([Ukrainer](https://ukrainer.net/bugay-en/)).

**Derived in the notes.** The eastern drums are big and often bottomless. An open barrel has no sealed air behind the skin to stiffen it; it has tube resonances instead. That makes two body types: a **closed vessel** (jug, pot, tin, the fanfrnoch among them) and an **open tube or barrel** (buhai, burczybas, cuíca). The 0.5–0.7 m hair also means long pulls, which the hands chop into rhythm.

### In the south the reed pots hum like a double bass; in Brazil the cuíca sings

**Described.**

- **Andalusian zambomba:** a clay friction drum with a skin or bladder head and a cane fixed at its centre, "grave, ronco y de altura indeterminada" (low, hoarse, of indefinite pitch). A specimen from Hinojosa del Duque is an earthenware jug about 44.5 cm high with a mouth of about 9 cm, under pig bladder (snippet; the full page failed; [CDMA](https://www.centrodedocumentacionmusicaldeandalucia.es/membranofonos/membranofonos-de-friccion/zambomba-cantaro)).
- **Neapolitan putipù** (caccavella): a pot, tub or tin under goat, sheep or rabbit skin, with a bamboo or marsh-reed cane rubbed "from top to bottom" with a wet hand, likened to a double bass (snippet, [Napoligrafia](https://www.napoligrafia.it/musica/strumenti/caccavella-putipu.htm)).
- **Portuguese sarronca** is similar (snippet, [Wikipedia: Sarronca](https://en.wikipedia.org/wiki/Sarronca)).
- **Venezuelan furro or furruco:** "takes the bass position" in gaita zuliana (snippet, [Wikipedia: Gaita zuliana](https://en.wikipedia.org/wiki/Gaita_zuliana)).

**Described (cuíca).** The cuíca is the outlier: "a Brazilian friction drum with a stick—usually made of bamboo—fixed inside its cylindrical body". "Sound is produced by rubbing a wet piece of cloth (often a grosgrain ribbon, as preferred by experienced players) along the internal friction stick". The head "can be tensioned by the other hand to control pitch", giving "distinct melodic lines spanning an octave or more" ([Trovato et al., Hypercuíca, NIME 2026](https://nime.org/proceedings/2026/nime2026_81.pdf)). Common heads are 8, 9½ and 10 inches on open metal shells about 26–30 cm long. "The larger the cuíca, the greater the variety of notes", and what most decides the sound is "the skin and the gambito" (the stick) ([Cuiqueiros](http://cuiqueiros.blogspot.com/2013/01/as-medidas.html)). A retail LP3408 is 8 in by 10.5 in in brass with a goatskin head (claimed, snippet; [Presto](https://www.prestomusic.com/instruments-accessories/products/8887748--latin-percussion-cuica-brazilian-brass-8-brass)). Its Central African ancestors with internal sticks are "extremely low-pitched" and associated with "the voice of big cats ... the voice of the dead" ([NIME 2026](https://nime.org/proceedings/2026/nime2026_81.pdf)).

### A handful of specimens have dimensions, and none has a pitch

| Instrument | Specimen | Body | Friction element | Basis |
|---|---|---|---|---|
| Buhai | Horniman M90-1983 | 315 × 287 mm, staved, open base, rabbit skin | horsehair 670 mm | measured, catalogue ([Horniman](https://horniman.ac.uk/object/M90-1983)) |
| Burczybas | Szydłowiec, Hopowo 1970s | 435 × 390 mm, leather | horsehair | measured, catalogue ([Google A&C](https://artsandculture.google.com/asset/friction-drum-with-a-cord-walkusz-jerzy/8QGCxqcK_q7sSQ?hl=en)) |
| Buhai (Moldavian) | Música Para Ver | 41 × 30.5 cm | horsehair | snippet ([musicaparaver](https://musicaparaver.org/instruments/type/friction-drum/buhai)) |
| Zambomba-cántaro | CDMA, Hinojosa del Duque | about 44.5 cm high, mouth about 9 cm, pig bladder | cane | snippet ([CDMA](https://www.centrodedocumentacionmusicaldeandalucia.es/membranofonos/membranofonos-de-friccion/zambomba-cantaro)) |
| Lončeni bas | Wikipedia table | clay pot 20–40 cm tall | resined hardwood stick | claimed ([Wikipedia](https://en.wikipedia.org/wiki/Friction_drum)) |
| Cuíca | common sizes | 8–10 in head (6–12 exist), 26–30 cm long, open metal shell | bamboo stick inside | claimed ([Cuiqueiros](http://cuiqueiros.blogspot.com/2013/01/as-medidas.html); [Gope](https://loja.gope.net/cuica/10/cuica-alum-30cmx10-10-afin-aro-largo-preto-e-preto-bal3010cpp)) |
| Waldteufel (whirled) | GNM MIR651 | 6.1 cm high, 6.3 cm across, sheet iron, bladder | plastic thread to a beech grip | measured, catalogue ([GNM](https://objektkatalog.gnm.de/wisski/navigate/49536/view)) |
| Giligilipī (whirled toy) | Koizumi 198, India | 3.0 cm deep, 4.4 cm across, clay, paper head | string to a stick; "a squeaky sound" | measured, catalogue ([Koizumi](https://geidai.ac.jp/labs/koizumi/gcat0/english/html-text/198.html)) |

**Not found.** No source gives a sounding pitch in hertz or as a note name for any traditional friction drum, the cuíca included, and no source gives a vessel volume. The only quantitative pitch statements are relative: a bigger vessel sounds lower; tension, the length of the reed or hair and the depth of the binding all tune; the cuíca has a range of "an octave or more" ([instruments notes](../research_notes/Friction%20drum%20acoustics%20and%20playing/instruments_and_construction.md)).

**Derived in the notes.** Size and wording line up across the survey. Whirled toys of 4–6 cm squeak. Pots and jugs of 20–45 cm hum or are hoarse. Big barrels and the African internal-stick drums bellow or roar. The orchestral lion's roar, a large drum with a rosined cord ([Wikipedia: Lion's roar](https://en.wikipedia.org/wiki/Lion%27s_roar_(instrument))), stands at the roaring end. The notes propose program names from the source vocabulary: Bull (buhai), Growl (burczybas), Brumm (Brummtopf), Frroep (rommelpot), Hoarse (zambomba), Double-bass (putipù), Laugh (cuíca), Squeak (Waldteufel), Roar (lion's roar).

## The sound: stick–slip locks to one mode and slips once per period

### The literature is one tutorial, one simulation and one cuíca abstract nobody could read

**Found, and not found.** These are the sources that treat friction drums at all:

- **Akay's tutorial** on the acoustics of friction has a short cuíca section with no numbers ([Akay 2002](https://www.imperial.ac.uk/media/imperial-college/research-centres-and-groups/dynamics/Akay-Acoustics-of-friction.pdf)).
- **One simulation:** a thesis and a DAFx paper model "a friction drum inspired instrument" by finite differences ([Onofrei thesis 2021](https://projekter.aau.dk/projekter/files/410480603/Real_Time_Implementation_Of_Bowed_Instruments.pdf); [Onofrei, Willemsen and Serafin, DAFx20in21](https://www.dafx.de/paper-archive/2021/proceedings/papers/DAFx20in21_paper_32.pdf)).
- **One cuíca study:** a 2002 ASA meeting abstract, "An acoustic study of the Brazilian cuica", examined waveforms, spectra and time envelopes of a gourd-bodied folk cuíca. Its full text, authors and numbers could not be retrieved. A snippet says that "the body of the cuica contributes little to the sound" ([JASA 112, 2266](https://pubs.aip.org/asa/jasa/article/112/5_Supplement/2266/548495/An-acoustic-study-of-the-Brazilian-cuica), snippet). A Tokyo collection page says the same, also as a snippet ([Koizumi 196](https://www.geidai.ac.jp/labs/koizumi/gcat0/english/html-text/196.html)).

Everything else is general drum acoustics ([Rossing 1992](https://aip.brightspotcdn.com/PTO.v45.i3.40_1.online.pdf)) and bowed-string acoustics ([Woodhouse and Galluzzo 2004](https://plus.maths.org/old-files/issue31/features/woodhouse/2pdf/index.html/op.pdf)). Searches in Spanish, Portuguese, German and Czech found organology only ([sound notes](../research_notes/Friction%20drum%20acoustics%20and%20playing/sound_production.md)).

### Friction locks to one mode; force and speed set level and roughness, not pitch

**Authors' interpretation.** Akay describes the mechanism in two sentences. On the cuíca, "the player continuously strokes the stick with a piece of moist cloth, thereby exciting the membrane at its center with the resulting stick–slip motion". "The bamboo stick vibrates the membrane as a bow does with a string, and the player's finger on the membrane selects the mode of vibration as does placing a finger on the string." Under strong contact, friction systems fall into "mode lock-in, where the coupled system responds at one of its fundamental frequencies and its harmonics", and which mode they choose "depends on the normal load, sliding velocity, and the contact geometry". In his bowed demonstrations "only infrequently does more than one natural frequency appear simultaneously" ([Akay 2002](https://www.imperial.ac.uk/media/imperial-college/research-centres-and-groups/dynamics/Akay-Acoustics-of-friction.pdf)).

The bowed string gives a map of regimes:

- **Helmholtz motion**, the normal note: "a single episode of sticking and of slipping ... in every cycle".
- **Too little force:** "double slipping ... a note at the same pitch ... but with a different waveform".
- **Too much force:** a "raucous 'graunch'" that turns chaotic.
- **The start of a note:** "usually a transient period of non-regular motion ... which may make the start of the note sound scratchy".

([Woodhouse and Galluzzo 2004](https://plus.maths.org/old-files/issue31/features/woodhouse/2pdf/index.html/op.pdf)). The allowed force window scales with bow speed (Schelleng; snippet, [McGill notes](https://caml.music.mcgill.ca/~gary/618/week11/node3.html)).

**Authors' interpretation (simulation).** In the friction-drum simulation "the Helmholtz motion can be seen ... [as] a triangular shape" at the bowing point, with a hysteresis loop in force against relative velocity. A friction law that depends only on velocity gave "a more noisy sound" than the elasto-plastic one ([Onofrei thesis](https://projekter.aau.dk/projekter/files/410480603/Real_Time_Implementation_Of_Bowed_Instruments.pdf)).

**Derived in the notes.** In the locked regime the period belongs to the resonator; rubbing speed and pressure set amplitude and brightness. A skin driven at its centre has essentially one strong low mode, so the system behaves more like a single mass on a spring riding a moving belt than like a string. Standard theory for that system gives two regimes:

- **Slow, heavy strokes:** long stick phases alternate with fast slips at a rate below the mode frequency, and each slip rings the mode. That is a creak or chatter, the "grunt" of a heavy pull.
- **Faster strokes:** the motion turns quasi-sinusoidal at the natural frequency, the tonal "voice".

The notes add three predictions. A dry or over-rosined rod could lock onto its own kilohertz modes and squeal. Roughness should rise with force relative to speed. Every reversal of the hand passes through zero velocity, so it should bring a short creak and a dip in level ([sound notes](../research_notes/Friction%20drum%20acoustics%20and%20playing/sound_production.md)).

### A centre drive sees only the axisymmetric modes, and the rod's mass pulls the pitch down

**Textbook.** An ideal circular membrane has modes at 1 : 1.594 : 2.136 : 2.296 : 2.653 : 2.916 : 3.156 : 3.501 : 3.600 … times the (0,1) mode ([Rossing 1992](https://aip.brightspotcdn.com/PTO.v45.i3.40_1.online.pdf)). Every mode with nodal diameters has a node at the centre, so a stick or cord fixed there drives only the axisymmetric modes (0,1), (0,2) and (0,3), at 1 : 2.295 : 3.598 (Bessel zeros, [Wikipedia: Vibrations of a circular membrane](https://en.wikipedia.org/wiki/Vibrations_of_a_circular_membrane)). Air loading lowers the low modes. The stiffness of enclosed air raises the axisymmetric ones, and a smaller kettle raises them more, while "changing the kettle shape has little or no effect" (measured, timpani; [Rossing 1992](https://aip.brightspotcdn.com/PTO.v45.i3.40_1.online.pdf)).

**Derived in the notes (from assumed skin data).** These figures assume an areal density of 0.3 kg/m² and tensions of 1,000–5,000 N/m, none of them measured on a friction drum:

- **Bare head:** a cuíca-sized head would sound its (0,1) at roughly 175–650 Hz.
- **With a stick:** the stick dominates the moving mass. A bamboo stick of 5–25 g on a head whose (0,1) modal mass is about 1.6 g brings the mode down to about 80–180 Hz.
- **Closed pot:** the air adds a spring of the same order as the skin's own stiffness, about 10.6 kN/m at 1 L and 2.7 kN/m at 4 L for an 8 cm head. Quadrupling the volume then lowers the pitch by about 5.5 semitones, which matches "the larger the pitcher, the deeper".
- **Open tube:** a 30 cm cuíca shell has quarter-wave resonances near 240, 715 and 1,190 Hz.
- **Horsehair:** a light bundle adds little mass, so a horsehair drum should sit closer to the bare (0,1) mode stiffened by its cavity.

([sound notes](../research_notes/Friction%20drum%20acoustics%20and%20playing/sound_production.md)).

**Derived in the notes (controls).** Pressing the cuíca's head near the stick raises the local tension, and an octave needs about four times the tension. The finger also damps the head and imposes a node, which is Akay's "selects the mode". Water lubricates and gives a clean stick–slip with a modest drop from static to sliding friction. Rosin grips harder, slips more violently and is noisier, and it is sensitive to temperature, since its glass transition lies near room temperature (snippet, [Acta Acustica 2026](https://acta-acustica.edpsciences.org/articles/aacus/pdf/2026/01/aacus260048.pdf)). A synthesizer's "contact" control could therefore move between wet (small drop, little noise) and rosin (large drop, more noise).

### Where the derivations and the recordings disagree

The derived physics and the recordings measured below agree on the mechanism and part company on four details. Each matters for the model.

1. **The radiation argument fails.** The notes derive that a head of 8 cm radius radiates poorly below about 700 Hz, which should leave the fundamental weak and the spectrum bright. In the recordings the fundamental is the strongest partial in most instruments and the spectra fall steeply. Only the putipù and one zambomba have a weak fundamental, and there a body resonance explains it. The model should therefore not apply a radiation high-pass by default.
2. **The fanfrnoch is lower than the derivation says.** A light horsehair bundle on a bare head stiffened by a small jug should sound several hundred hertz. The only fanfrnoch recording sounds at about 125 Hz. A large or slack bladder, wet and heavy hair, or the hand's own mass could explain it; nothing measured settles which. The derived numbers rest on assumed densities and tensions.
3. **"Inharmonic" and "indefinite" do not describe the tone.** An aggregator claims that friction drums make inharmonic overtones ([Grokipedia](https://grokipedia.com/page/Friction_drum), claimed, unsourced), and the folk sources call the fanfrnoch and zambomba of indefinite pitch. The measured strokes are harmonic within a few cents. "Indefinite" is better read as untuned to the song, rough, and fixed by the pot rather than chosen.
4. **The stick pots agree and the cuíca exceeds.** The notes' 60–200 Hz for closed stick pots holds: the Brummtopf measured 66–149 Hz, the putipù 62–99 Hz and the zambomba 94 and 223 Hz. The derived 150–500 Hz rest pitch for the cuíca is too narrow, since its top register measured 640–860 Hz.

Two derivations are supported only weakly. The membrane ratio 2.30 appears once, in the furruco (228/99 Hz), which is suggestive and no more. The creak below the pitch appears in a string drum turned by a handle, not in any hand-rubbed stroke.

## Measured here: thirty-two public recordings, and only one fanfrnoch

### What was analysed and how

**Measured here.** The files and their sources:

- **Wikimedia Commons, 6 files:** the Czech group take *Skupina famfrnochů* (fanfrnoch, 9 s), a Styrian Brummtopf at a wine festival, *Zambomba.ogg*, a Pearl cuíca demo and two cuíca files from 2005.
- **Freesound, 26 files, CC0 or CC BY only:** one samba player's 12-take cuíca series (reinsamba), eight putipù takes of one player (bbmario), a flicked Pataxó cuíca, a "constant" cuíca, a cuíca in a stairwell, a Barcelona zambomba and a Venezuelan furruco. One further zambomba is the same audio as part of the Commons file and is not counted.
- **museum-digital, 1 file:** a theatre's string Brummtopf, turned by a handle to make a mill wheel creak.

No freely licensed recording of a rommelpot, buhai or burczybas exists in these collections.

The analysis worked as follows:

- **Frames:** levels every 5 ms; f0 by a YIN-type tracker; aperiodicity and harmonic-to-noise ratio (HNR) from the autocorrelation; spectral centroid.
- **Strokes:** found as runs of level, split at dips of 6 dB.
- **Attack:** the time from −20 to −3 dB under a stroke's peak.
- **Release:** a straight-line fit of dB against time.
- **Pitch templates:** f0 at fixed times after onset.
- **Harmonics:** levels at k·f0 in the five loudest strokes.
- **Roughness:** frame jitter (5–35 ms wobble) and a subharmonic index.

Method, file list, licences and every table are in the [recordings notes](../research_notes/Friction%20drum%20acoustics%20and%20playing/recordings_measured.md). The limits: nobody listened; files are lossy (Ogg Vorbis, 128 kbps MP3 previews); microphones and distances are unknown for all but one series; the fanfrnoch take has several instruments sounding; one zambomba begins with an edited loop; and stroke direction is never named.

### Every rubbed stroke is one harmonic series, mostly with the fundamental first

**Measured here.**

| Recording | Instrument | f0 of strokes | Harmonic levels re strongest (H1 / H2 / H3 / H4 / H5 / H8 / H10) | Centroid |
|---|---|---|---|---|
| [Skupina famfrnochů](https://commons.wikimedia.org/wiki/File:Skupina_famfrnoch%C5%AF.ogg) | fanfrnoch, group | loud strokes 107–133 Hz (5 of 7 at 121–127) | 0 / −7 / −12 / −21 / −22 / −29 / −40 dB | 1.25–1.45 × f0 |
| [Friction drum in action](https://commons.wikimedia.org/wiki/File:Friction_drum_in_action.ogg) | Brummtopf, stick | two registers: 127–149 and 74–80 Hz | high strokes 0 / −15 / −12 / −6 / −20 / −34 / −44 (a zone at about 480–570 Hz) | 218 Hz |
| [Zambomba.ogg](https://commons.wikimedia.org/wiki/File:Zambomba.ogg) | zambomba | 223 Hz [211–227] | 0 / −16 / −20 / −18 / −39 / −43 / −47; fixed off-series peaks at 306 and 420 Hz (−12 to −13 dB) | 1.15 × f0 |
| [zambombaibrasacatalana](https://freesound.org/people/ori2001/sounds/14344/) | zambomba, Barcelona | 94 Hz | −28 / 0 / −5 / −9 / −27 / −28 / −37 | 264 Hz |
| reinsamba [Cuica pack](https://freesound.org/people/reinsamba/packs/1339/) | cuíca, 12 takes | 329–368, 750–790, 850–855 Hz by take | H1 strongest in 11 of 12; H2 −6 to −28, H3 −14 to −35, H5 −32 to −49, H10 −44 to −69 | 1.02–1.24 × f0 in 10 takes |
| [Cuica.Cuica.wav](https://commons.wikimedia.org/wiki/File:Cuica.Cuica.wav) | cuíca, Pearl demo | 491 Hz | 0 / −11 / −22 / −33 / −34 / −59 / −58 | 553 Hz |
| bbmario [Putipù pack](https://freesound.org/people/bbmario/packs/6855/) | putipù | 62–99 Hz | H1 −5 to −10; strongest H5–H6 at **440–520 Hz** whatever the f0 | 3.7–4.3 × f0 |
| [furruco.mp3](https://freesound.org/people/el.papa.montero/sounds/510791/) | furruco | about 70 Hz, not one clean series | peaks at 67–73, 98–103, 182, 228 Hz | 117 Hz |

On long, steady strokes the peaks lie on the k·f0 grid within ±13 cents on the fanfrnoch (k = 2–10), within −33 to +6 cents on the putipù (most within ±10), within −17 to +11 cents on the Brummtopf, and within about 6 cents on steady cuíca strokes. Averaged over the five loudest strokes of every file, the ratios f(k)/(k·f0) for k = 2–5 are 0.992–1.000. No stroke showed a membrane-mode spectrum as its main sound.

**Derived in the recordings notes.** The source locks to one period, so a synthesizer's source can be a harmonic oscillator, and the membrane and body enter as filtering. That means either a gentle colour (fanfrnoch, cuíca, zambomba) or one strong formant at about 450–550 Hz on a low fundamental (putipù, Brummtopf). The steep spectra mean a plain sawtooth or pulse would be far too bright.

### Strokes hold their pitch; the cuíca scoops 2–7 semitones and changes register between strokes

**Measured here.** Rhythmic strokes stay within ±0.2–0.5 semitone on the fanfrnoch, Brummtopf, zambomba, putipù and fast cuíca patterns. Many rise 0.2–0.5 semitone over the first 20–60 ms and fall as much in their last 10–30 ms. The movements that do occur:

- **Cuíca "whoop":** the stroke rises from its onset and holds once it arrives. The rise is **+6.6 semitones** in reinsamba (2) (540 to 795 Hz; all nine strokes +5.6 to +7.2), about 5.7 semitones of it between 5 and 60 ms (roughly 100 semitones per second). It is +2.9 in (13) and (9), and +2.2–2.3 in (5) and (6), arriving 60–150 ms after the onset.
- **Fanfrnoch:** the loud strokes drift **down by 0.6–2.4 semitones, median about 0.8**, from start to end; the first stroke of the take rose instead.
- **Between strokes:** the large changes happen here. Cuíca (10) alternates registers 1.9–2.2 times apart (326–340 against 636–751 Hz; a spectrum confirms they are real). The Brummtopf alternates about 140 and 75 Hz, so successive strokes differ by a median of 9.1 semitones and every second stroke by 2.9.
- **Zambomba mode jump:** in about one stroke in five the pitch jumps at the end from 201–219 to 289–305 Hz (+5.3 to +7.2 semitones, ratio about 1.40), onto the fixed 306 Hz peak.
- **Flicked cuíca:** a flicked cuíca rings freely at 300–310 Hz, and as it dies a subharmonic appears: 149 Hz sits at −9 dB beside 304 Hz in the second half of the decay, against −19 dB in the first.

**Derived in the recordings notes.** For one note per stroke, the pitch per note can be fixed, with an optional scoop (start 2–7 semitones low, arrive in 60–150 ms) and a small drop at the end. Register changes belong to different MIDI notes, not to an envelope.

### The rubbing is the envelope: up in 12–40 ms, a plateau, 20 dB down in 25–75 ms

**Measured here.**

| Recording | Strokes | Duration, median | Within 6 dB of peak | Attack (−20 → −3 dB) | Release slope → T60 |
|---|---|---|---|---|---|
| fanfrnoch (group) | 34, 7 loud | loud 0.34–0.58 s | 0.20–0.27 s | 42 ms [21–88] | −197 dB/s → 0.30 s |
| Brummtopf | 54 | 0.113 s | 0.080 s | 24 ms | −715 dB/s → 0.08 s |
| zambomba (Commons) | 101 | 0.145 s | 0.097 s | 31 ms | −441 dB/s → 0.14 s |
| cuíca, fast samba (10) | 133 | 0.127 s | 0.086 s | 21 ms | −678 dB/s → 0.09 s |
| cuíca, other takes | 8–25 each | 0.15–0.24 s | 0.03–0.15 s | 12–36 ms | −196 to −725 dB/s → 0.08–0.31 s |
| putipù | 20–55 each | 0.49–0.86 s | 0.13–0.22 s | **83–204 ms** (peak 150–300 ms after onset) | −36 to −38 dB/s → 1.6 s (possibly room) |
| furruco | 51 | 0.19 s | 0.099 s | 71 ms | −110 dB/s → 0.54 s |
| cuíca, flicked | 35 | 0.157 s | 0.020 s | **8 ms** | −119 dB/s → 0.50 s (a free ring) |
| string Brummtopf | 219 slips | 0.066 s | 0.013 s | 9 ms | −462 dB/s |

The gaps from the end of one stroke to the next onset are 27 ms on the fast cuíca and 34 ms on the zambomba. On two cuíca takes and the fanfrnoch group they are 1 ms: the strokes run into each other with a dip at the reversal.

**Derived in the recordings notes.** A friction stroke has a quick rise, a plateau while the hand moves and a fast fall when it stops, without the long free ring of a struck drum. The putipù's slow, swelling stroke is a separate class.

**Derived here: one resonator explains both ends in most takes.** A resonator driven by a source that switches on and off rises and decays with the same time constant. Its amplitude follows 1 − e^(−t/τ) up and e^(−t/τ) down, with τ = T60 / 6.91. The rise from −20 to −3 dB then takes 1.125·τ = 0.163 × T60, whatever the pitch. Applied to the measured release of each rubbed take:

| Take | Release T60 | Predicted attack | Measured attack | Ratio |
|---|---|---|---|---|
| fanfrnoch | 0.305 s | 50 ms | 42 ms | 0.85 |
| zambomba (Commons / Barcelona) | 0.136 / 0.317 s | 22 / 52 ms | 31 / 46 ms | 1.40 / 0.89 |
| furruco | 0.545 s | 89 ms | 71 ms | 0.80 |
| cuíca (10) / (8) / (5) / (6) / (9) / (13) | 0.09–0.23 s | 14–37 ms | 13–36 ms | 0.78–1.46 |
| putipù B1 / B3 | 1.58 / 1.62 s | 257 / 264 ms | 173 / 204 ms | 0.67 / 0.77 |
| Brummtopf; cuíca (11) | 0.084 / 0.083 s | 14 / 14 ms | 24 / 21 ms | 1.76 / 1.56 |
| cuíca (4) / (12) / (2) / Pearl; putipù B2 | 0.12–1.67 s | 20–272 ms | 12–83 ms | 0.30–0.61 |

In **12 of 19 rubbed takes** the measured attack lies within a factor of 1.5 of the prediction. Where the attack is slower than predicted (Brummtopf, one cuíca), the hand evidently stops the stick harder than the head would stop by itself. Where it is faster (four cuíca takes, one putipù), the head rings on after the hand stops, or the room adds a tail. Read as a resonator, the fanfrnoch's head has a Q of about 17 at 125 Hz, the cuíca's about 13–37, the Brummtopf's about 5, and the flicked cuíca's free ring about 70. This is arithmetic on a straight-line release fit and a median attack, not a fitted model. It supports two things: **one "ring" time can set both ends of a stroke by default**, and a separate damping control is needed for the takes that depart from it.

### Roughness runs from nearly pure to 5 dB HNR; creak and halved pitch appear only at the edges

**Measured here.**

| Recording | HNR | Frame jitter | Shimmer | Subharmonic index |
|---|---|---|---|---|
| cuíca, reinsamba | 13.7–27.0 dB | 3–16 cents | 0.6–1.3 dB | mostly ≤ −30 dB (none) |
| zambomba | 14.0 dB | 32 cents (includes the jumps) | 0.81 dB | −44 to −46 dB |
| Brummtopf | 9.9 dB | 12 cents | 0.91 dB | −22 to −27 dB |
| fanfrnoch (group) | 5.9 dB over all strokes; **8–13 dB on the loud strokes** | 20 cents | 0.71 dB | −15 to −25 dB |
| putipù | 5.9–8.7 dB | 5–11 cents | 0.44–0.51 dB | −6 to −30 dB |
| furruco | 5.0 dB | 46 cents | 0.76 dB | **−2 to −7 dB** (strong) |
| cuíca, flicked | 6.0 dB | – (the pitch halves) | 1.01 dB | −4 to −16 dB |

The string Brummtopf shows a different roughness. Its slips come about 14 times a second (40–120 ms apart), too slow to fuse into a pitch. Each one jumps about 20 dB and rings a mode at 288–308 Hz, falling 10–16 dB over 30–50 ms: a creak. The flicked cuíca begins with about 20 ms of noise (centroid 700 Hz) before its clean 300 Hz ring.

**Derived in the recordings notes.** A clean voice (cuíca) needs almost no added noise. A rough voice (fanfrnoch, putipù, furruco) at 5–9 dB HNR needs rubbing noise at about −6 to −10 dB against the tone plus a few tens of cents of slow wobble. Creak and period doubling are behaviours a physical friction model produces by itself; a source–filter model must add them.

### The one fanfrnoch take, in detail

**Measured here.** [*Skupina famfrnochů*](https://commons.wikimedia.org/wiki/File:Skupina_famfrnoch%C5%AF.ogg) ("several fanfrnochs played together", CC BY-SA 3.0, 9.0 s, mono, Vorbis at about 96 kbps):

- **Pattern:** a loud low stroke comes every **0.93 s** (0.86–0.96 s), 1.07 per second, with 2–4 quieter, higher strokes between (226–313 Hz, 5–12 dB down), probably other players.
- **The loud strokes:** they sound at **107–133 Hz**, five of seven at 121–127 Hz, last 0.34–0.58 s with 0.20–0.27 s within 6 dB of the peak, rise in 42 ms, fall at about 200 dB/s and drift down about 0.8 semitone.
- **Spectrum:** H2 −7, H3 −12, H4 −21, H10 −40 dB, harmonic within ±13 cents.
- **Roughness:** HNR 8–13 dB on the loud strokes, frame jitter 20 cents.

No formant zone like the putipù's shows; the centroid stays at 1.25–1.45 × f0. This is the one measured reference for the instrument the product is named after. It is a group, so nothing quieter than the loud strokes is clean, and the playing pattern of a single player, left and right hand, is unknown.

## Playing and rhythm: the change of direction is the beat

### Pull and push everywhere, and press and release on the cuíca

**Described and observed.** The basic gesture is the same in every tradition: a wet hand or wet cloth slides along a stick or a hair bundle, and each slide is one sound.

- **Cuíca:** "the rhythm is articulated by pushing and pulling along the length of the rod", and "the tighter one holds the rod, the higher the pitch". The other hand "can press on the head in different spots", so the instrument can "imitate the voice in the form of grunts, groans, moans, and squeaking sounds" or "provide a rhythmic ostinato" ([BYU Percussion](https://percussion.byu.edu/cuica)). The player Frank Colón: "The closer you place your index and middle fingers to the 'button' in the middle of the outside skin, combined with a tighter squeeze on the stick as you stroke it, the higher the pitch" ([DrumsOnTheWeb](http://drumsontheweb.com/DOTWpages/Drumkeypages/lessonspages/FCberimbau3.html)). A Brazilian writer's "decalogue" calls the back-and-forth *leva-e-traz*, gives the strokes as "*tu-tum-tu tum-tu-tu*" and "*fuk-fuk*", and says "the hand inside sets the tone and marks the groove" ([Blog do Turiba](http://blogdoturiba.blogspot.com/2012/01/decalogo-da-cuica.html)). The ethnomusicologist Araújo describes "low, middle and high pitches" made by alternating between a free head and pressure "at its most varied points", with the cloth wetted with water, milk, resin or petrol ([Araújo 2021](https://pantheon.ufrj.br/bitstream/11422/16566/3/miolo_samba.pdf)). A transcription of the Império Serrano bateria notates the cuíca on three levels, "high partials / middle partials / fundamental", though the notes themselves are images that could not be read ([de Paula 2003](https://www.unirio.br/cla/ivl/cursos/copy_of_rafaelpaula.pdf)). Hypercuíca names "a classic cuíca technique in which the final note is prolonged" ([NIME 2026](https://nime.org/proceedings/2026/nime2026_81.pdf)).
- **Buhay and buhai:** "You pull up, and then the membrane returns into position" ([Ukrainer](https://ukrainer.net/bugay-en/)). A skilled player gets "five or six different sounds" (claimed, snippet; [Wikipedia: Buhay](https://en.wikipedia.org/wiki/Buhay)).
- **Rommelpot:** "when you move your wet hand back and forth over the stick, the characteristic 'rommel' sound is heard" (snippet, [Omroep Brabant](https://www.omroepbrabant.nl/nieuws/2932768/Lekker-rommelen-tijdens-carnaval-trief-troef-tralala)).
- **Zambomba:** gives "a strong, sonorous and monotonous sound" (claimed, snippet; [EcuRed](https://www.ecured.cu/Zambomba)).
- **Fanfrnoch:** described only as alternating pulls by both wet hands ([cs.wikipedia](https://cs.wikipedia.org/wiki/Fanfrnoch)).

**Claimed.** Slower, lighter rubbing gives "low croaky tones" and faster, harder rubbing "high squeals" (snippet, a science-museum activity; [Exploratorium](https://www.exploratorium.edu/snacks/coffee-can-cuica)). General MIDI kits map the cuíca as "Mute" and "Open" (notes 78 and 79), trigger keys rather than pitches. No source describes a damped cuíca stroke as a technique.

**Derived in the playing notes.** A stroke vocabulary for the synthesizer:

- pull and push, the direction change being the rhythmic unit; on horsehair drums the pull carries the sound;
- open (low), middle and pressed (high) on the cuíca;
- glides up and down within a stroke;
- a long held final note;
- a continuous rub for the folk pots.

The cuíca's "laugh" is a figure, fast alternation with rising or falling pitch, not a single stroke.

### Samba tempi are the only numbers: 80–130 bpm, sixteenths of 115–190 ms, 7.4 strokes per second measured

**Measured (dataset annotations, read for the notes).** In the Brazilian Rhythmic Instruments Dataset the eleven ensemble recordings that include a cuíca are annotated at these tempi, counting quarter-note beats in 2/4:

- **samba:** 79.6–97.0 bpm;
- **partido alto:** 95.8–99.7 bpm;
- **samba-enredo:** 124.7–129.9 bpm.

Over all 93 mixtures the ranges are samba 62–113, partido alto 87–122 and samba-enredo 103–140 bpm ([BRID annotations](https://zenodo.org/records/14051323); [Maia et al. 2018](https://magdalenafuentes.com/publications/2018_AES_brid.pdf)).

**Derived in the playing notes.** On a sixteenth-note grid that is one stroke every 187.5 ms at 80 bpm (5.3 per second), 150–156 ms in partido alto, 115–120 ms in samba-enredo, and 97 ms at the top of the marcha range. If every push and every pull sounds, a continuous sixteenth line is one back-and-forth cycle per eighth note. A stroke must therefore be complete, and ready to retrigger, within about 100 ms. A "prolonged" stroke can last a beat or more (375–750 ms at 80 bpm).

**Measured here (stroke rates).**

| Recording | Interval between onsets | Rate | Pattern |
|---|---|---|---|
| cuíca (10), fast samba | 0.136 s [0.089–0.192] | 7.35 per second | low-low-high-high cycles (331 334 337 339 … 636 … 689 644 Hz) |
| cuíca (4) / (12) | 0.141 / 0.216 s | 7.1 / 4.6 per second | successive strokes alternate loud and soft by about 6 dB |
| cuíca (5) | 0.233 s, regular to ±20 ms | 4.3 per second | every stroke a +2.3 semitone scoop |
| cuíca (2) | 0.707 s | 1.4 per second | one whoop each time |
| zambomba | 0.169 s | 5.9 per second | the first 2.9 s are an edited loop of a 1.19 s pattern |
| furruco | 0.214 s | 4.7 per second | – |
| Brummtopf | strong strokes 0.454 s | 2.2 per second | high/low alternation about 11 semitones apart |
| fanfrnoch (group) | loud strokes 0.932 s; all 0.184 s | 1.07 loud per second | one loud low stroke, 2–4 quieter higher ones between |
| putipù | 0.62–0.97 s | 1.0–1.6 per second | slow swells |

Push and pull plausibly cause the two-stroke patterns, but which stroke is which direction cannot be read from the audio.

### The patterns: a set phrase with freedom in samba, the beat under a song everywhere else

**Observed.** In the samba school "the cuícas have a model rhythmic phrase, but there is great individual freedom to improvise" ([de Paula 2003](https://www.unirio.br/cla/ivl/cursos/copy_of_rafaelpaula.pdf)). They stand at the front with chocalhos and tamborins and "do not play the whole samba" ([Habitus/UFRJ](https://revistas.ufrj.br/index.php/habitus/article/download/11256/8206/22591)). A director, quoted by Araújo: "the cuíca appears a lot in the second [part of the samba-enredo]. The bateria director is guided by the cuíca" ([Araújo 2021](https://pantheon.ufrj.br/bitstream/11422/16566/3/miolo_samba.pdf)). The decalogue speaks of phrases "going 2-1, 3-1 and 3-3-6" without saying what the numbers count ([Blog do Turiba](http://blogdoturiba.blogspot.com/2012/01/decalogo-da-cuica.html)). A manufacturer's exercise alternates high and low on the eighth notes (claimed, snippet; [Ensoul manual](https://manualshive.com/ru/manual/ensoul/dobani-cuic5/2414288?page=2)). No written-out cuíca pattern was found as text.

**Observed and claimed (Europe).**

- **Rommelpot:** "rhythmic accompaniment for solo singing", taken door to door on New Year's Eve, at Sint-Maarten and on Shrove Tuesday ([nl.wikipedia](https://nl.wikipedia.org/wiki/Rommelpot_(muziekinstrument))).
- **Rummelpott:** the Schleswig-Holstein New Year's Eve begging custom (snippet, [state portal](https://www.schleswig-holstein.de/DE/landesportal/land-und-leute/typisch-sh/tradition-und-brauchtum/_documents/rummelpottlaufen.html)).
- **Zambomba:** accompanies villancicos, and in Jerez gives its name to the pre-Christmas gatherings ([es.wikipedia](https://es.wikipedia.org/wiki/Zambomba)).
- **Buhai:** sounds in the Romanian plugușor with recitation, bell, flute, bass drum, whip and shouts ([Roots of Rhythm](https://rootsofrhythm.net/buhai/)). Plugușor rhythm is called "giusto-syllabic" (snippet).
- **Furro:** plays bass in gaita, "6 x 8, in the old versions 2 x 4" (snippet).
- **Tammurriata:** described in 6/8, though the putipù's role in it is undocumented (snippet, [Ferraiuolo](https://ocf.berkeley.edu/~culturalanalysis/volume14/vol14_Ferraiuolo.html)).
- **Fanfrnoch:** accompanies Czech carols. A New Year tune is named after it (claimed, snippet; [Wikipedia: Fanfrnoch](https://en.wikipedia.org/wiki/Fanfrnoch)), and it appears with shepherd's horn and vozembouch in carolling programmes (snippet, [GoOut](https://goout.net/cs/jak-jsi-krasne-nevinatko/szaledy)).

**Not found.** No tempo, stroke rate or notation exists for any European friction drum. The group take's loud stroke every 0.93 s is the only timing of a fanfrnoch, and whether it marks a beat, a half bar or a bar of the song is unknown.

**Derived in the playing notes.** The folk drums are beat-keepers under processional song. They have one register per pot, mostly short against long rubs, and no pitch control. That is a pad instrument: a few frozen strokes per pot. The cuíca needs the pitch dimension, two or three levels and fast retriggering.

## Synthesis: one published physical model, and no friction drum in any product

### The literature: an FDTD drum nobody recognised, and cheap friction parts in open-source code

**Authors' interpretation (one published model).** Onofrei, Willemsen and Serafin model a friction drum as "a bowed membrane connected to an acoustic tube" by finite differences. The excitation is an elasto-plastic friction model, solved per sample by a 3×3 Newton–Raphson iteration of up to 99 steps. Their parameter table:

| Group | Parameter | Value |
|---|---|---|
| Membrane | size | 0.3 × 0.3 m |
| | wave speed | 15–150 m/s ("Tuning") |
| | losses | σ0 ≤ 6 s⁻¹, σ1 ≤ 0.0026 m²/s |
| Tube | length | 0.4 m |
| | wave speed | 30 m/s instead of air's 343, because the physical value "will actually not produce the desired 'drum' type sound" |
| Friction | Coulomb and static coefficients | µC 0.3, µS 0.8 |
| | Stribeck velocity | vS 0.1 m/s |
| | bristle stiffness | s0 10⁵ N/m |
| | noise term | s3 ≤ 0.04·fN |
| Player | normal force | fN 0–20 N |
| | bow velocity | vB 0–0.2 m/s |

The authors treat the stick "as an infinitely long bow", so the sound is sustained indefinitely and not identical "to either of the real friction drums". Real friction drums, because "the stick is of limited length", "are typically used for percussive sounds, characterised by a sharp attack". In an informal demonstration to 17 students the answers to "which instrument it was" included "Theremin, ... gong, hand drum, metallic drum, bowed bar, low frequency saw, a cymbal that is 'contact-miced' and bowed or even 'a chair being dragged across the floor'". No comparison with real drums was made, and no code is public ([DAFx20in21](https://www.dafx.de/paper-archive/2021/proceedings/papers/DAFx20in21_paper_32.pdf); [thesis](https://projekter.aau.dk/projekter/files/410480603/Real_Time_Implementation_Of_Bowed_Instruments.pdf); [demo](https://www.youtube.com/watch?v=3UEUyYc6PF0)). The author's own remark on what sounded right: "if one focuses on small percussive friction excitations without allowing the membrane to resonate, the app can sound like some of the friction drums in online videos".

**Derived in the synthesis notes.** The simulation lets the bow wander over the head, which excites modes with nodal diameters. A real centre drive cannot do that, and the wandering is one plausible reason the listeners heard a gong or a bowed bar. Its cost is about 6,000–10,000 operations per sample (about 227 membrane points and 364 tube points plus the Newton solve), one to two orders of magnitude over a light per-voice budget.

**Code read for the notes.** The open-source code offers four kinds of cheap friction part:

- **Sound Design Toolkit (SDT).** It computes the elasto-plastic friction force explicitly, without iteration: one `exp`, at most one `sin`, one `sqrt` and one noise sample per sample. Its roughness term is white noise scaled by √(|v|·fN), and it drives exact-discretised modal resonators. It is GPLv3, so for a closed product it can serve only as a reference ([SDTInteractors.c](https://github.com/SkAT-VG/SDT/blob/main/src/SDT/SDTInteractors.c); [LICENSE](https://github.com/SkAT-VG/SDT/blob/main/LICENSE.txt)).
- **Bow tables (STK, Faust).** STK's bow table is (|x|+0.75)⁻⁴, and its banded waveguides put a bandpass per mode in a delay loop ([BowTable.h](https://github.com/thestk/stk/blob/master/include/BowTable.h); [BandedWG.cpp](https://github.com/thestk/stk/blob/master/src/BandedWG.cpp); MIT-style). Faust's `fds.lib` and `mi.lib` have memoryless exponential friction curves for meshes and mass–interaction models ([fds.lib](https://github.com/grame-cncm/faustlibraries/blob/master/fds.lib); LGPL with an exception for compiled code).
- **Mutable Instruments Elements.** It bows eight delay-plus-bandpass modes inside a 64-mode resonator and refreshes the higher modes' coefficients at a slower rate ([resonator.cc](https://github.com/pichenettes/eurorack/blob/master/elements/dsp/resonator.cc); MIT).
- **Sound-design friction.** Farnell's creaking door uses an impulse train with noise on its frequency, "so the motion doesn't become too regular" (snippet, [Wikibooks](https://en.wikibooks.org/wiki/Designing_Sound_in_SuperCollider/Creaking_door)). A tribology group reports that a squeak's frequency "is set by the repetition rate of these propagating pulses", not by random events (snippet, [Nottingham](https://www.nottingham.ac.uk/news/stop-the-squeak-new-research-could-end-squeaking-trainers-or-screeching-chalk)).

Elasto-plastic friction on modal resonators reproduces "rubbing, braking, and squeaky doors" (snippet, [Avanzini, Serafin and Rocchesso 2005](https://typeset.io/pdf/interactive-simulation-of-rigid-body-interaction-with-3k3oo568e2.pdf)). No published source reports a CPU figure for any of these.

**Claimed (products).** Every dedicated cuíca product found is sample-based:

- Sonokinetic's Kontakt library has "a soprano at 6 inches and a bass at 10 inches" in "950+ samples" ([Sonokinetic](https://www.sonokinetic.net/products/ethnic/cuica/)).
- Muletone ([pulse.audio](https://pulse.audio/product/cuica/)) and Drumwavy ([Syntheway](https://www.syntheway.net/Drumwavy.htm)) are also sample-based.

Bowed exciters exist in Logic's Sculpture ([Apple](https://help.apple.com/logicpro/mac/9.1.6/en/logicpro/instruments/chapter_14_section_5.html)), Ableton's Tension ([Ableton](https://www.ableton.com/packs/tension/)) and Elements. None ships a friction drum. Of Tension's bow, an Ableton staffer says that, as on a real violin, "it is easy to get noise and hard to get a nice sound" ([Ableton forum](https://forum.ableton.com/viewtopic.php?p=862329)). Collision and Chromaphone have only mallet and noise exciters ([Ableton Collision](https://www.ableton.com/packs/collision/); [SOS on Chromaphone](https://www.soundonsound.com/reviews/aas-chromaphone)). No review judging the realism of any synthesized friction sound was found. A synthesized engine would win on pitch continuity and on variation from stroke to stroke, which sample libraries cannot give.

### Four ways to build it, compared at sixteen voices

Costs are the notes' operation counts or this report's (marked); none is a measured CPU figure. The sibling Brumle engine runs about 80–90 operations per voice and sample with 16 voices ([Brumle engine design](../../../../Brumle/.planning/specs/2026-11-15-engine-design.md)).

| Method | What it would be here | Operations per voice and sample | Fits the measurements? | Main risk for the ear |
|---|---|---|---|---|
| **Prescribed slip clock** (recommended) | a phase oscillator at the note's pitch, warped into a slow stick and fast slip; a stroke envelope with head inertia; scripted wobble, rub noise, period halving, creak and mode jump; two fixed body resonances | about 50 (this report's count) | yes: one harmonic series at an exact pitch, a gated envelope, both ends of a stroke from one ring time in 12 of 19 takes, harmonics within 2–4 dB from one shape number | "a synthesizer with an envelope": onset irregularity, creak and jumps exist only as far as they are written in |
| Pulse train into a membrane mode bank | the notes' source–filter proposal: a jittered pulse train through 4–8 (0,n) modes plus 1–2 cavity formants | about 60–150 | partly: the recordings show no membrane-mode spectrum as the main sound, so a mode bank adds inharmonic peaks heard only in the zambomba and furruco | metallic or gong-like, the Onofrei listeners' words |
| Friction loop on a few modes | SDT-style elasto-plastic contact, or an STK/Elements bow table, on the loaded head mode plus a few others | about 120–220 (elasto-plastic), 60–100 (bow table) | the onset scratch, creak, double slip and mode lock-in come by themselves; the pitch is the mode's, but drifts with drive | parameter sensitivity ("easy to get noise"); stability of the explicit scheme in single precision undocumented; pads must repeat exactly |
| FDTD membrane and tube | Onofrei et al. | about 6,000–10,000 plus Newton | most complete in principle | out of budget; not recognised by its listeners |

### Why the slip clock, and where it can still fail the ear

**Proposal, with reasons.**

1. **It is the mechanism the recordings show.** One slip per period at the locked pitch, a waveform made of a long stick and a short slip, and a body that colours the result. In the locked regime the pitch belongs to the loaded head, not to the hand, so prescribing it from the MIDI note is physics, not approximation. That differs from the didgeridoo's lips, where Brumle's lineage learned that prescribing a self-sustained pitch can fail by ear.
2. **One shape number matches the harmonics.** A cosine whose phase is warped so that its rise takes a fraction *s* of the period has harmonics that fall by themselves, about 18 dB per octave in the limit (its first derivative is continuous). Derived here by a grid fit against the measured harmonic levels:
   - **fanfrnoch:** *s* = 0.88 gives H2 −9, H3 −14, H4 −17, H5 −20, H8 −30 and H10 −39 dB against the measured −7, −12, −21, −22, −29 and −40, an rms error of **2.2 dB**;
   - **cuíca:** *s* = 0.73 matches targets near the middle of the measured ranges (H2 −15, H3 −25, H5 −40, H10 −55) within **3.5 dB**;
   - **comparison:** an asymmetric tanh saturator fitted the same targets worse, at 3.6 and 4.3 dB.

   The fraction has a physical reading, the share of each period the contact sticks, and harder strokes can raise it, as faster, harder rubbing is said to give "squeals".
3. **The stroke envelope comes from one ring time.** In 12 of 19 rubbed takes the attack and the release agree with a single resonator, so one Ring value sets both, and a Damp and an Attack control cover the takes that depart.
4. **The pitch is exact and continuous.** The note sets f0, and scoops, drift, jumps and pitch bend are smooth functions of time. Pads repeat bit for bit when their random generators are reset.
5. **It is cheap**, about 50 operations per voice and sample with no oversampling. The warped cosine's harmonics fall fast enough: extrapolated from H10 at −39 dB at Stick 0.88, the 25th harmonic of an 860 Hz note (21.5 kHz) is near −62 dB (lower still at the cuíca's 0.73), and a 125 Hz fanfrnoch's harmonics at Nyquist are below −100 dB (derived here; to be checked by measuring the engine's output).

**Risks for the ear, in the order this report would test them.**

- **Sameness.** A prescribed, warped cosine with an envelope is the textbook "synthesizer" sound. The recordings' realism lives in the roughness: HNR of 8–13 dB on the fanfrnoch, 20 cents of frame wobble, 0.7 dB of shimmer, stroke-to-stroke spread. If these do not make it a drum, the friction loop is the next prototype, at two to four times the cost.
- **The onset.** Bowed strings start with "a transient period of non-regular motion", and a flicked cuíca opens with 20 ms of noise. No rubbed stroke was measured with a separate scratch, because the level template rises smoothly. Whether a short scrape helps is an ear question.
- **Fixed brightness.** In the model, brightness follows level by the proposal that the stick fraction rises with the envelope. Nobody has measured how a friction stroke's brightness evolves.
- **Push against pull.** Every real alternation, by level, register or brightness, is attributed to direction without evidence. Alternate is a guess with two numbers.
- **The fanfrnoch itself.** The default is fitted to one 9-second group take, unheard.

## Recommendation for the engine

Everything in this section is a **proposal**. Basis letters in the tables: M published measurement, H measured here, C described or claimed, D derived (in the notes or here), P this report's choice with no evidence behind the number.

### The signal path of one voice

```
note-on: pitch, velocity, and the knob set this stroke plays with (the panel's, or the pad's)

hand    the rubbing starts, runs for Length, and stops. While it runs the head comes up to
        speed with the inertia set by Attack; when it stops the head rings out over Release,
        faster if the hand also damps it (Damp). Key Up: Ignore, or Stop the rubbing early.
clock   a phase oscillator at the note's pitch, one slip per period. Inside the stroke the
        pitch moves by Scoop (start below, arrive over Scoop Time), Drift (over the stroke)
        and Drop (at the end); Wobble jitters it (lowpassed noise, a few tens of cents);
        Jump can step it to a second mode, Jump Ratio above, late in some strokes.
shape   each period is a stick ramp and a fast slip: a cosine whose phase is warped so the
        rise takes Stick of the period. Stick rises a little with level and velocity, so a
        harder stroke is brighter and the tail of a stroke is darker.
        Split makes alternate periods unequal (a component at half the pitch).
        Creak breaks the tone into separate slips at Creak Rate, each ringing for Creak Ring.
body    beside the direct sound, two fixed resonances in parallel: Pot (the vessel's formant)
        and Skin (an off-series mode, the Jump's landing place); Track lets them follow
        the pitch.
rub     noise gated by the stroke and scaled by velocity, through the same body (Rub);
        a short noise at the onset (Scrape); Shimmer on the level.
        -> Volume, Pan -> voices summed -> DC blocker -> limiter
```

The body and noise filters are the trapezoidal state-variable filters Brumle already uses, updated every 16 samples. The warped cosine needs one division-free piecewise phase map (the two slopes are recomputed at control rate) and one cosine approximation per sample. This report's count is about 50 operations per voice and sample:

| Stage | Operations |
|---|---|
| clock and jitter | 3 |
| phase warp | 4 |
| cosine | 6 |
| envelope | 3 |
| split and creak | 6 |
| noise and its filter | 9 |
| two body resonators and their gains | 13 |
| mix and pan | 5 |

For 16 voices at 48 kHz that is about 40 million operations per second.

### What one stroke contains

| Time | What happens | Basis |
|---|---|---|
| 0 | the hand starts to slide; the slip clock starts at the note's pitch, minus Scoop if set | C: the direction change is the stroke |
| 0 to about 20 ms | optionally a Scrape of noise; the pitch, if scooped, is climbing | H: 20 ms of noise on a flicked onset; no separate scratch measured on rubbed strokes |
| 12–40 ms (fanfrnoch about 42, putipù 80–200) | the tone is up to within 3 dB of full level, the time Attack sets | H |
| 60–150 ms | a scooped (cuíca) stroke arrives at its pitch | H: +2.3 to +6.6 semitones |
| plateau, for Length (0.03–0.27 s within 6 dB; fanfrnoch 0.20–0.27) | a steady harmonic tone with wobble, shimmer and rub noise; Drift moves it slowly (fanfrnoch about −0.8 semitone over the stroke) | H |
| late in the stroke, in some strokes | Jump steps the pitch to the Skin mode (zambomba: +5.3 to +7.2 semitones, about one stroke in five) | H |
| the hand stops | the tone falls at Release: 200 dB/s (fanfrnoch) to 700 dB/s (Brummtopf, fast cuíca), faster with Damp; a final Drop of a few tenths of a semitone | H |
| next stroke on the same drum | it starts before the old tail has gone: on the same drum the oscillator's phase carries on, so strokes run into each other with a dip rather than a click | H: 1 ms gaps with a dip on fast takes |

### Default character: a Chod fanfrnoch at B2, a pull of about half a second

**Proposal.** The default program is the instrument the product is named after, set from the one take that exists:

- **Pitch:** the pad's note is **B2 (123.5 Hz)**, against five of seven loud strokes measured at 121–127 Hz.
- **Envelope:** Attack 42 ms, a plateau (Length) of 0.23 s and Release at 200 dB/s (T60 0.3 s), so a stroke sounds about half a second.
- **Pitch movement:** Drift −0.8 semitone, no scoop.
- **Tone:** Stick 0.88. Rub noise for an HNR of about 10 dB, Wobble 20 cents, Shimmer 0.7 dB, no body formant.
- **Two hands:** Alternate set gently (2 dB and 10 cents on every second stroke) and a moderate Vary.

The measured fanfrnoch is a group and nothing quieter in it is clean, so this default is a starting position, not a fit. The rhythm the author wants decides the next steps: whether a stroke should be shorter for fast patterns, rougher for the bladder-and-hair character, or brighter. The other poles are programs.

### Built-in programs

| Program | Tradition and evidence | Starting numbers (differences from the default) |
|---|---|---|
| **Fanfrnoch** | the default; Chod horsehair jug, two hands (C; H, one group take) | as above; a second pad an octave or so higher for the group's quieter strokes (226–313 Hz) |
| **Brummtopf** | Styrian stick pot played in two registers (C; H) | two pads in one group, about 140 Hz and 77 Hz (C♯3 and D♯2); Attack 24 ms, Length 0.08 s, Release 700 dB/s, Pot 540 Hz at Q 4 and +6 dB (the 480–570 Hz zone), HNR 10 dB, Wobble 12 cents; a pitch dip of about 25 cents at 40 ms |
| **Zambomba** | Spanish Christmas pot (C; H) | A3 (220 Hz); Attack 31 ms, Length 0.1 s, Release 440 dB/s, Stick 0.80, Skin 306 Hz at −12 dB, Jump 20 % at ratio 1.40, HNR 14 dB |
| **Zambomba Grave** | the Barcelona take (H) | F♯2 (94 Hz); fundamental weak, H2–H4 strongest: Pot about 250 Hz, broad; Release 190 dB/s |
| **Putipù** | Neapolitan pot: slow swelling strokes (C; H) | C2–F2 (65–87 Hz); Attack 170 ms, Length 0.15 s, Release 40 dB/s (T60 1.6 s, possibly room), Pot 470 Hz at Q 5 and about +12 dB so that H5–H6 lead, HNR 7 dB, Wobble 8 cents; a fall of about 0.5 semitone from the onset |
| **Cuíca** | samba, rhythmic (O; H) | two pads in one group: low about 350 Hz (F4), high about 770 Hz (G5); Attack 15–25 ms, Length 0.09 s, Release 600 dB/s, Stick 0.73, HNR 20 dB, Wobble 8 cents, Alternate 6 dB, Drop 0.3 semitone; with pitch bend as the pressing hand |
| **Cuíca Whoop** | the "laughing" stroke (C; H) | G5; Scoop 6.6 semitones over 80 ms, Length 0.03 s, Release 200 dB/s; a softer variant with Scoop 2.5 over 120 ms at F4 |
| **Furruco** | Venezuelan stick box, bass of the gaita (C; H) | C♯2 (69 Hz); Attack 70 ms, Release 110 dB/s, Split 70 % (subharmonic at −2 to −7 dB), Wobble 45 cents, HNR 5 dB, Skin 100 Hz at −3 dB |
| **Creak** | a string friction drum turned by a handle; the Waldteufel family (D; H) | Creak 100 %: about 14 slips per second, jittered, each ringing a mode near 300 Hz for 40 ms; centroid of the noise 450–550 Hz |
| **Flick** | a cuíca's stick flicked, not rubbed (*peteleco*) (H) | D♯4 (311 Hz); Attack 8 ms, Length 0, Release 120 dB/s (T60 0.5 s), Scrape on, Split rising as it dies |
| **Buhai** | Romanian and Ukrainian horsehair barrel, the "bull" (C only; **no recording measured**) | P throughout: low (around 60–80 Hz), long pulls (Length 0.5 s), rough (HNR 6 dB), no closed-pot stiffening; to be voiced by ear or dropped |

Pitches, times, HNR, wobble and the jump come from the recordings. The Stick values other than the fitted 0.88 and 0.73, every Q, and the levels of Pot and Skin are P: starting points for the builder to fit against the listening list, then for the ear. The default pad kit can hold these as one drum per mute group: fanfrnoch left and right hand, the Brummtopf's two registers, the cuíca's low, high and whoop, the zambomba with and without the jump, the putipù at two pitches, the furruco, Creak, Flick and Buhai. The contents are the builder's to propose and the author's to approve by ear, as in Brumle.

### Parameters

About thirty-five knobs in six sections. Identifiers are suggestions. The first to merge or drop if the panel is too full: Scrape, Jump Ratio, Creak Ring and Skin Q.

| Section | Identifier | Name | Range | Default (Fanfrnoch) | What it does | Basis |
|---|---|---|---|---|---|---|
| Stroke | `attack` | Attack | 5–400 ms (log) | 42 ms | time from −20 to −3 dB: the head's inertia while the hand moves | H |
| Stroke | `length` | Length | 0–2000 ms (log) | 230 ms | how long the hand rubs (the plateau) | H: 0.20–0.27 s within 6 dB |
| Stroke | `release` | Release | T60 0.05–3 s (log) | 0.30 s | how fast the tone dies when the rubbing stops; by default tied to Attack (T60 ≈ 6 × Attack) | H; D: one ring time fits 12 of 19 takes |
| Stroke | `damp` | Damp | 0–100 % | 0 % | the hand stopping the stick: the release up to three times faster | H: Brummtopf, one cuíca |
| Stroke | `keyup` | Key Up | Ignore / Stop | Ignore | whether letting go of the key stops the rubbing early | P |
| Stroke | `alternate` | Alternate | 0–12 dB | 2 dB | every second stroke of a drum quieter (push against pull, or the other hand) | H: 6 dB alternation on two cuíca takes; P for the default |
| Stroke | `alttune` | Alt Tune | −100…+100 cents | +10 | the second stroke's pitch offset | H: 20–40 cents within cuíca pairs; P |
| Stroke | `vary` | Vary | 0–100 % | 20 % | differences from stroke to stroke in level (about ±1.5 dB at 20 %), pitch (±25 cents), length (±20 %) and Stick | H: loud fanfrnoch strokes 121–127 Hz, 0.34–0.58 s |
| Stroke | `velsens` | Vel Sens | 0–100 % | 70 % | how much velocity (rubbing speed and force) changes level and brightness | C; P |
| Pitch | `scoop` | Scoop | 0–12 semitones | 0 | how far below its pitch a stroke starts | H: 2.3–6.6 on the cuíca |
| Pitch | `scooptime` | Scoop Time | 10–300 ms (log) | 80 ms | how long it takes to arrive | H: 60–150 ms |
| Pitch | `drift` | Drift | −3…+3 semitones | −0.8 | pitch change over the plateau | H: fanfrnoch −0.6 to −2.4 |
| Pitch | `drop` | Drop | 0–2 semitones | 0 | fall in the last 10–30 ms | H: 0.2–0.5 on cuíca and zambomba |
| Pitch | `wobble` | Wobble | 0–60 cents | 20 | slow random pitch movement (5–35 ms scale) | H: 3–46 cents |
| Pitch | `jump` | Jump | 0–100 % | 0 % | share of strokes that end on the Skin mode | H: about 20 % on the zambomba |
| Pitch | `jumpratio` | Jump Ratio | 1.1–2.5 | 1.40 | where that mode lies against the pitch | H: 1.40; D: 2.30 for (0,2) |
| Pitch | `veltune` | Vel>Pitch | 0–100 cents | 0 | a harder stroke slightly higher | C: tighter squeeze, harder rubbing, higher |
| Source | `stick` | Stick | 0.50–0.95 | 0.88 | share of each period the contact sticks: 0.5 is a sine, higher is brighter | D: 0.88 fanfrnoch, 0.73 cuíca |
| Source | `stickvel` | Stick>Level | 0–0.1 | 0.03 | how much Stick rises with level and velocity | P |
| Source | `split` | Split | 0–100 % | 0 % | alternate periods unequal: a component at half the pitch | H: furruco, a dying flick |
| Source | `creak` | Creak | 0–100 % | 0 % | the tone broken into separate slips | H: string Brummtopf; D: slow, heavy strokes |
| Source | `creakrate` | Creak Rate | 4–40 Hz | 14 Hz | how often a slip comes, jittered | H |
| Source | `creakring` | Creak Ring | 10–100 ms | 40 ms | how long each slip rings | H: 30–50 ms |
| Body | `pot` | Pot | 150–1500 Hz (log) | 500 Hz | the vessel's formant | H: 440–570 Hz on putipù and Brummtopf |
| Body | `potq` | Pot Q | 1–20 | 4 | its sharpness | P |
| Body | `potlevel` | Pot Level | −∞…+18 dB | −∞ (off) | its level against the direct sound | H: none seen on the fanfrnoch |
| Body | `skin` | Skin | 100–1500 Hz (log) | 306 Hz | an off-series mode | H: zambomba 306 and 420 Hz |
| Body | `skinq`, `skinlevel` | Skin Q, Skin Level | 1–40; −∞…+6 dB | 10; −∞ (off) | its sharpness and level | P; H: −12 dB on the zambomba |
| Body | `track` | Track | 0–100 % | 0 % | whether the body follows the pitch (0: fixed, as the putipù's formant is) | H: putipù formant fixed while f0 moves 62–99 Hz |
| Noise | `rub` | Rub | −40…0 dB against the tone | −10 dB | rubbing noise through the body, gated by the stroke | H: HNR 8–13 dB fanfrnoch, 14–27 cuíca |
| Noise | `scrape` | Scrape | 0–100 % | 10 % | a noise burst of about 20 ms at the onset | H: flicked cuíca only; P |
| Noise | `shimmer` | Shimmer | 0–3 dB | 0.7 dB | random level movement | H: 0.4–1.3 dB |
| Master | `volume`, `pan`, `tune`, `octave` | Volume, Pan, Tune, Octave | as in Brumle | 0 | – | – |

After the knobs come the LFO and VEL amounts as in Brumle. LFOs earn their place only on long strokes. Their targets are Pitch (the pressing hand's slow movement, and the simulation's vibrato of 0–10 Hz), Pot, Rub and Stick. Velocity amounts go to level, Stick, Rub, Scoop and Vel>Pitch.

### Pitch, note length, velocity, voices and mute groups

- **Note number.** In keyboard mode the note sets f0 at its own pitch, so B2 is 123.5 Hz. The measured friction drums run from about 62 Hz (putipù, B1) to 860 Hz (cuíca, about A5), notes 35 to 81. Below and above that nothing has been heard. In pad mode, notes 36–51 trigger the pads as in Brumle, and each pad holds its own pitch.
- **Note length.** Key down is the hand starting to rub. With Key Up = Ignore, a stroke always lasts Length: a drum pad, deterministic whatever the sequencer's note length. With Stop, the note's length is the pull's length, capped by Length, which stands for the stick or hair running out. That is the physical meaning, since "the stick is of limited length". Which should be the default is an ear and workflow question.
- **Velocity.** Velocity is rubbing speed and force. Through Vel Sens it sets level, through Stick>Level brightness, and through Rub the noise, which grows with speed and force as in the physical models' noise terms. Teachers and the science-museum claim tie harder strokes to higher pitch; Vel>Pitch is available and off by default.
- **Pitch bend.** On the cuíca, pitch bend is the pressing hand: a range of +12 semitones up and −2 down covers "an octave or more" (and BYU's claimed two octaves at +24). The modulation wheel suits Rub or Creak; aftertouch suits Stick on held strokes.
- **One drum is one mute group.** A friction drum has one head and sounds one stroke at a time. In pad mode the pads of one instrument share a group: the fanfrnoch's two hands, the cuíca's low, high and whoop. A new stroke in the group takes over the head, and Alternate counts within the group, as Brumle's stroke direction does. In keyboard mode the proposal is the same by default: all notes are one drum, monophonic, with the phase of the old stroke carried into the new one so that fast strokes run into each other with a dip, not a click. A Poly switch would allow several drums.
- **Voices.** Strokes are short (20 dB down within 25–120 ms of the hand stopping) and rates reach 7–10 per second, so Brumle's pool of 16 voices with fade-stealing is ample.

### What carries over from Brumle, and what changes

Unchanged ([Brumle engine design](../../../../Brumle/.planning/specs/2026-11-15-engine-design.md), §7 and §9):

- the C interface over a C++ engine, sample-accurate MIDI and lock-free queues;
- the 16-sample control interval and the trapezoidal resonator;
- a pool of 16 voices;
- 17 knob sets, with only the keyboard set as Audio Unit parameters and the pads in the saved state;
- programs as overrides, kits and user presets, Send to pad and mute groups;
- LFO and VEL amounts and stereo Pan;
- random generators reset with the engine, so that regression references hold.

Four changes:

1. **The amplitude envelope comes back.** Brumle has none, because the reed's swing is the envelope. Here the hand gates the sound, so the voice has Attack, Length and Release, and the rule "a stroke ends when the hand stops" replaces "a reed rings until damped".
2. **A group is one drum.** Within a group or in a monophonic keyboard, a new stroke continues the drum's phase instead of starting a new voice from zero.
3. **Oversampling may not be needed.** The warped cosine's harmonics fall about 18 dB per octave. That should be confirmed by measuring the engine's alias products at 44.1 kHz on the brightest settings (Stick 0.95, 860 Hz) before dropping Brumle's 2× stage.
4. **The regression scores change.** They need a fast alternating pattern on one group, a scooped stroke, a jump, Creak, Split and a held stroke with Key Up = Stop.

## Where the evidence runs out, and what only the ear can settle

### Nobody has measured a friction drum's pitch, envelope or push and pull, except the recordings analysed here

**Measurements.** No published pitch, spectrum, decay time, attack time or harmonic-to-noise ratio exists for any friction drum. The 2002 cuíca study, the one likely exception, was seen only as a snippet. No skin density, tension, vessel volume or friction coefficient of wet cloth, wet hair or rosin was found. Every number in this report on these comes from 32 public recordings analysed without listening, almost all one player and one take, lossy and uncalibrated.

**The fanfrnoch.** One 9-second group take is all there is. It has no solo, no single player's left-and-right pattern, no specimen with dimensions, no description of the sound beyond "deeper, stronger" and no rhythm. The derivation predicts a higher pitch than the recording shows, and nothing settles why.

**Missing relatives.** No freely licensed recording of a rommelpot, Rummelpott, buhai, buhay or burczybas was found, so the eastern horsehair barrels, the fanfrnoch's closest kin by excitation, are described only in words. No Slovak tradition was researched.

**Playing.** No source names which stroke is a push and which a pull, or measures any difference between them. No written cuíca pattern was readable; de Paula's transcriptions are images. No tempo exists for any European tradition. No source describes a damped cuíca stroke.

**Synthesis.** No listening test of any synthetic friction drum exists. No CPU figure exists for any friction model. The stability of an explicit elasto-plastic contact in single precision is undocumented.

**Limits of this research.** Several pages were reached only as snippets: the CDMA zambomba record, the Polish, Hungarian and Romanian dictionaries, and most cuíca retail listings. The Romanian ethnographic PDF and the Britannica page refused automated access. The Serafin thesis on the sound of friction was not read. The model's two central numbers were obtained by this report's own fits to the notes' measurements: the stick fraction of 0.88 and the "one ring time" result. Neither has been heard.

### Fourteen questions for the author's ear

Each names what to compare and the knob that would move.

1. **Drum or synthesizer?** The slip clock's Fanfrnoch default against the recording *Skupina famfrnochů*, played in the same rhythm. If no setting of Rub, Wobble and Shimmer makes it a drum, build the friction-loop prototype (an elasto-plastic or bow-table contact on the head mode) and compare on the same score.
2. **How long is a pull?** Length 0.1, 0.23 and 0.45 s at the measured Attack and Release; and Key Up Ignore against Stop for programming rhythms.
3. **How rough is a fanfrnoch?** Rub at −20, −10 and −6 dB with Wobble 5, 20 and 40 cents. The group take's 6 dB HNR is partly the overlap of players; its loud strokes give 8–13.
4. **How bright?** Stick 0.80, 0.88 and 0.93, and whether brightness should fall in the tail (Stick>Level 0 against 0.05).
5. **Does it need a pot?** Pot Level off against a 500 Hz formant at +6 dB. The putipù and Brummtopf have one; the fanfrnoch take shows none.
6. **Drift.** −0.8 semitone on every pull against 0: realism, or out of tune?
7. **Attack.** 42 ms against 15 ms: does a rhythm instrument want the stroke snappier than the measured fanfrnoch?
8. **Release and ring.** 200 dB/s against 600 dB/s, and Damp 0 against 50 %: does the head ring on or is it stopped?
9. **Two hands.** Alternate 0, 2 and 6 dB with Alt Tune 0 and 10 cents, on a fast pattern of one group.
10. **The onset.** Scrape 0, 10 and 40 %: is a 20 ms scrape the sound of a wet hand catching, or noise?
11. **Creak and Split.** Should a soft stroke creak or halve its pitch (a velocity amount on Creak or Split), or should those stay programs?
12. **The cuíca's whoop.** Scoop 2.5 semitones over 120 ms against 6.6 over 80 ms, and the Drop at the end; and whether pitch bend should press up by 12 or 24 semitones.
13. **One drum.** Keyboard mode monophonic with the phase carried over, against polyphonic. Fast alternation with and without the carried phase.
14. **The range.** A fanfrnoch moved to 300 Hz and to 60 Hz with Track 0 and 100 %: where does it stop sounding like a jug, and should the body follow?

**A first experiment worth more than any of the numbers above.** The ten references in the listening list of the [recordings notes](../research_notes/Friction%20drum%20acoustics%20and%20playing/recordings_measured.md) are public:

- the fanfrnoch group;
- the Brummtopf with its two registers;
- reinsamba's whoop (2) and fast samba (10);
- the putipù's swells;
- the zambomba with its jumps;
- the flicked cuíca;
- the creaking string drum.

Their licences are CC0, CC BY or CC BY-SA, usable as references, not as shipped samples without honouring the licence. The author listens and names the ones that sound like the instrument he means. Above all, a **solo fanfrnoch** should be recorded. One can be made from a jug, a bladder or leather and two bundles of horsehair, as the Czech maker's page describes ([Nesladkář](https://nesladkar.cz/blog-post/vyrob-si-fanfrnoch/)), or obtained from the iFolklor carol. Record one player pulling left and right, slowly and fast, with water and with vinegar. That would replace the weakest link in this report, a 9-second group take, and answer the push-and-pull question at once. The analysis scripts already exist.

### The source ledger: who said what, and how it was read

| Evidence class | Sources |
|---|---|
| Acoustics and simulation, read in full | [Akay 2002](https://www.imperial.ac.uk/media/imperial-college/research-centres-and-groups/dynamics/Akay-Acoustics-of-friction.pdf) (cuíca and lock-in sections); [Onofrei thesis 2021](https://projekter.aau.dk/projekter/files/410480603/Real_Time_Implementation_Of_Bowed_Instruments.pdf); [Onofrei, Willemsen and Serafin, DAFx20in21](https://www.dafx.de/paper-archive/2021/proceedings/papers/DAFx20in21_paper_32.pdf) (read in full by the synthesis notes; the acoustics notes reached it through the thesis); [Rossing 1992](https://aip.brightspotcdn.com/PTO.v45.i3.40_1.online.pdf); [Woodhouse and Galluzzo 2004](https://plus.maths.org/old-files/issue31/features/woodhouse/2pdf/index.html/op.pdf); [Trovato et al., NIME 2026](https://nime.org/proceedings/2026/nime2026_81.pdf) |
| Acoustics, snippet or abstract only | [JASA 2002 cuíca study](https://pubs.aip.org/asa/jasa/article/112/5_Supplement/2266/548495/An-acoustic-study-of-the-Brazilian-cuica); [Koizumi 196](https://www.geidai.ac.jp/labs/koizumi/gcat0/english/html-text/196.html); [Phys. Rev. E 1993](https://journals.aps.org/pre/abstract/10.1103/PhysRevE.47.820); [Rev. Roum. 2011](https://academiaromana.ro/sectii2002/RomanianJournalTS/rev2011-2/RJTS-AM_2011_2_a1_Donescu.pdf); [McGill Schelleng notes](https://caml.music.mcgill.ca/~gary/618/week11/node3.html); [Galluzzo thesis](https://www.repository.cam.ac.uk/bitstream/1810/244810/1/Galluzzo%20thesis_root_singleSided3Apr04.pdf); [Acta Acustica 2026](https://acta-acustica.edpsciences.org/articles/aacus/pdf/2026/01/aacus260048.pdf); [Marogna and Avanzini 2009](https://avanzini.di.unimi.it/downloads/publications/marogna_dafx09.pdf); [Mills 1980](https://huskiecommons.lib.niu.edu/allgraduate-thesesdissertations/6350) |
| Measured here | 32 recordings from [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Skupina_famfrnoch%C5%AF.ogg), [Freesound](https://freesound.org/people/reinsamba/packs/1339/) and [museum-digital](https://berlin.museum-digital.de/object/245237); method, licences and tables in the [recordings notes](../research_notes/Friction%20drum%20acoustics%20and%20playing/recordings_measured.md) |
| Dataset annotations | [BRID on Zenodo](https://zenodo.org/records/14051323) (downloaded and read for the notes); [Maia et al. 2018](https://magdalenafuentes.com/publications/2018_AES_brid.pdf) |
| Museum catalogues | [Horniman M90-1983](https://horniman.ac.uk/object/M90-1983); [Szydłowiec burczybas](https://artsandculture.google.com/asset/friction-drum-with-a-cord-walkusz-jerzy/8QGCxqcK_q7sSQ?hl=en); [GNM MIR651](https://objektkatalog.gnm.de/wisski/navigate/49536/view); [Koizumi 198](https://geidai.ac.jp/labs/koizumi/gcat0/english/html-text/198.html); [Magyar Múzeum](https://magyarmuzeum.org/neprajz/magyar-nepi-hangszerek/kocsogduda/kocsogduda/); [CDMA](https://www.centrodedocumentacionmusicaldeandalucia.es/membranofonos/membranofonos-de-friccion/zambomba-cantaro) (snippet); [Música Para Ver](https://musicaparaver.org/instruments/type/friction-drum/buhai) (snippet) |
| Ethnomusicology | [Araújo 2021](https://pantheon.ufrj.br/bitstream/11422/16566/3/miolo_samba.pdf); [de Paula 2003](https://www.unirio.br/cla/ivl/cursos/copy_of_rafaelpaula.pdf); [Habitus/UFRJ](https://revistas.ufrj.br/index.php/habitus/article/download/11256/8206/22591); [Roots of Rhythm](https://rootsofrhythm.net/buhai/); [Ukrainer](https://ukrainer.net/bugay-en/); [dedes.ro](https://www.dedes.ro/index.php/2017/12/15/buhaiul/) |
| Players, teachers, makers | [Nesladkář](https://nesladkar.cz/blog-post/vyrob-si-fanfrnoch/); [Jihočeské muzeum](https://www.jcted.cz/vite-co-je-fanfrnoch-ve-ctvrtek-muzete-videt-jak-se-vyrabi/?liveMode=1); [BYU Percussion](https://percussion.byu.edu/cuica); [Frank Colón](http://drumsontheweb.com/DOTWpages/Drumkeypages/lessonspages/FCberimbau3.html); [Blog do Turiba](http://blogdoturiba.blogspot.com/2012/01/decalogo-da-cuica.html); [Cuiqueiros](http://cuiqueiros.blogspot.com/2013/01/as-medidas.html); [Instructables lion's roar](https://www.instructables.com/Creating-a-Lions-Roar/) (snippet) |
| Encyclopedias and dictionaries | Wikipedia: [Fanfrnoch (cs)](https://cs.wikipedia.org/wiki/Fanfrnoch), [Fanfrnoch (en)](https://en.wikipedia.org/wiki/Fanfrnoch), [Brumbál](https://cs.wikipedia.org/wiki/Brumb%C3%A1l), [Friction drum](https://en.wikipedia.org/wiki/Friction_drum), [H–S list](https://en.wikipedia.org/wiki/List_of_membranophones_by_Hornbostel%E2%80%93Sachs_number), [Brummtopf](https://de.wikipedia.org/wiki/Brummtopf), [Rommelpot](https://nl.wikipedia.org/wiki/Rommelpot_(muziekinstrument)), [Burczybas](https://pl.wikipedia.org/wiki/Burczybas), [Köcsögduda](https://hu.wikipedia.org/wiki/K%C3%B6cs%C3%B6gduda), [Buhay](https://en.wikipedia.org/wiki/Buhay), [Zambomba](https://es.wikipedia.org/wiki/Zambomba), [Putipù](https://en.wikipedia.org/wiki/Putip%C3%B9), [Cuíca](https://en.wikipedia.org/wiki/Cu%C3%ADca), [Lion's roar](https://en.wikipedia.org/wiki/Lion%27s_roar_(instrument)); [Hudební scéna](https://www.hudebni-scena.cz/slovnik-hudebnich-pojmu/famfrnoch-fanfrnoch-99) (snippet); [dexonline](https://dexonline.ro/intrare/buhai/7130) (snippet); [EcuRed](https://www.ecured.cu/Zambomba) (snippet); [Grokipedia](https://grokipedia.com/page/Friction_drum) (aggregator, low reliability) |
| Synthesis code | [SDT](https://github.com/SkAT-VG/SDT/blob/main/src/SDT/SDTInteractors.c) (GPLv3); [STK BowTable](https://github.com/thestk/stk/blob/master/include/BowTable.h), [BandedWG](https://github.com/thestk/stk/blob/master/src/BandedWG.cpp), [Shakers](https://github.com/thestk/stk/blob/master/src/Shakers.cpp); [Faust fds.lib](https://github.com/grame-cncm/faustlibraries/blob/master/fds.lib); [Elements resonator.cc](https://github.com/pichenettes/eurorack/blob/master/elements/dsp/resonator.cc); [Farnell's creaking door](https://en.wikibooks.org/wiki/Designing_Sound_in_SuperCollider/Creaking_door) (snippet); [Avanzini, Serafin and Rocchesso 2005](https://typeset.io/pdf/interactive-simulation-of-rigid-body-interaction-with-3k3oo568e2.pdf) (snippet) |
| Products and forums | [Sonokinetic Cuica](https://www.sonokinetic.net/products/ethnic/cuica/); [Muletone Cuíca](https://pulse.audio/product/cuica/); [Drumwavy](https://www.syntheway.net/Drumwavy.htm); [Logic Sculpture](https://help.apple.com/logicpro/mac/9.1.6/en/logicpro/instruments/chapter_14_section_5.html); [Ableton Tension](https://www.ableton.com/packs/tension/) and [forum](https://forum.ableton.com/viewtopic.php?p=862329); [Ableton Collision](https://www.ableton.com/packs/collision/); [SOS on Chromaphone](https://www.soundonsound.com/reviews/aas-chromaphone); [Exploratorium](https://www.exploratorium.edu/snacks/coffee-can-cuica) (snippet) |

The five sets of notes behind this report, each with its own cited findings, inferences and gaps: [sound production](../research_notes/Friction%20drum%20acoustics%20and%20playing/sound_production.md), [instruments and construction](../research_notes/Friction%20drum%20acoustics%20and%20playing/instruments_and_construction.md), [playing and rhythm](../research_notes/Friction%20drum%20acoustics%20and%20playing/playing_and_rhythm.md), [synthesis and prior art](../research_notes/Friction%20drum%20acoustics%20and%20playing/synthesis_and_prior_art.md), and this research's own [recordings measured](../research_notes/Friction%20drum%20acoustics%20and%20playing/recordings_measured.md). The sibling report on the jaw harp, whose form this one follows, is [Jaw harp acoustics and playing](../../../../Brumle/.planning/research/reports/Jaw%20harp%20acoustics%20and%20playing.md).

## Conclusion

The friction drum turns out to be the jaw harp's cousin in one respect and its opposite in another. Both have a pitch a model may prescribe: the reed rings at its own frequency, and the loaded skin locks the stick–slip to its own mode. But the jaw harp's source is free and dies away by itself, while the friction drum's source runs only while the hand moves. So the engine gets back the amplitude envelope Brumle threw out, and the envelope turns out to be one physical quantity, the head's ring time, that sets both how fast a stroke builds and how fast it stops in most of the recordings. The tone is plainer than "membranophone of indefinite pitch" suggests: one harmonic series, true to a few cents, mostly with the fundamental first, shaped well enough by a single number, the share of each period the contact sticks. What makes it a friction drum and not a sine with an envelope is the dirt the folk sources describe and the physics predicts: wobble, rubbing noise, a halved pitch at low drive, a creak when the slips get too slow. In the recommended model each of these is a written-in knob, which is the price of exact pitch and a budget of about 50 operations.

What the evidence cannot give is the fanfrnoch itself. Its construction is well described, but its sound rests on one unheard 9-second group take, and its closest relatives, the eastern horsehair barrels, were not recorded at all. So the design is built to be decided by ear. The default is a starting position taken from that single take; the programs span the recorded relatives from the hoarse zambomba to the laughing cuíca; and the fourteen questions above, together with a solo fanfrnoch recorded on purpose, are what a listening prototype should settle before any program is voiced.
