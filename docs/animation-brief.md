# Brief: an animated graphic for "Herd Around the World"

Hi Claude! I'd like your help making a short animated graphic. Here's everything about the project
and its look. Please keep the style consistent with this brief.

## The project in one breath

**The Herd** is a small handmade ceramics studio in Aurora, Colorado (theherdstudio.com). Its
community art project, **Herd Around the World**, sends little clay **Companions** out into the
world. People find one on a café shelf or park bench, scan the code on its bottom, carry it for a
while, help grant its wish, then pass it on or leave it somewhere new for the next person. Each
Companion's journey shows up on a map, chapter by chapter.

**Tagline:** Find one. Carry one. Watch them go.
**Also used:** "Art in Transit" (printed on each Companion's label), "Made to be part of the family."
**Feeling:** warm, hopeful, gentle, a little whimsical. Small acts of goodwill traveling far.

## The three steps (great for a story or animation)

1. **Find one.** Spot a little clay Companion somewhere unexpected.
2. **Carry one.** Take them along, help their wish come true (ride a train, see a telescope…).
3. **Watch them go.** Pass them on, and follow their journey across the map.

## The six real Companions (the "Originals")

| # | Name | Glaze color | Accent | Wish | Blurb |
|---|---|---|---|---|---|
| 0 | Stella | `#F4C7C3` (pink) | `#E58FA6` | see a telescope | "The stars call to me." |
| 1 | Wynter | `#A8DCC9` (mint) | `#5FA8A0` | ride a train | "There's nothing like a good friend to make a chilly day, a happy day." |
| 2 | Nimbus | `#F6E3A1` (butter) | `#E0B94A` | ride a bike | "I've spent my life with my head in the clouds. Excited to see new things!" |
| 3 | Angel | `#D9CCEB` (lavender) | `#A08BC9` | meet a dog | "You found me! Now we're friends." |
| 4 | Sprout | `#BFDDF0` (sky) | `#7FB2D9` | smell the roses | "I love hugs and hope we can be the best of friends." |
| 5 | Bubba | `#F4C7C3` (pink) | `#D98C86` | visit a restaurant | "I don't take up much room, I never complain about the window seat, and I love snacks" |

**Important:** the real clay Companions have **no faces**. In drawings, the simple smiling face
below is fine and loved (it shows the goodwill of the project), but **never write about them
smiling** in any text or captions.

## Colors

| Use | Hex |
|---|---|
| Soft mint background | `#DDF0E8` |
| Mint | `#A8DCC9` |
| Sage green (buttons, logo text) | `#5B7869` / logo `#6A8B81` |
| Dark green ink (text) | `#3F5A4C` |
| Pink (map pin, accents) | `#E07A93` |
| Butter yellow | `#F9EBB5` |
| Blush pink | `#F6D3D3` |
| Cream | `#FDF8F3` |
| The Herd beige | `#F7F0E8` |

Style: flat shapes, soft rounded "blob" backgrounds in pink, butter and mint, dotted travel paths
between places, no harsh outlines, lots of breathing room.

## Fonts (all free on Google Fonts)

- **Headlines:** "Shadows Into Light Two" (handwritten, friendly)
- **The Herd's own script:** "Playwrite AU QLD" (light, school-handwriting look)
- **Body text:** "Fira Sans"
- **Chunky labels and numbers:** "Baloo 2" (weight 800)

## Ready-made art you can use or animate

**The Herd logo** (elephant + "THE HERD"):
https://raw.githubusercontent.com/armada4team-prog/herdaroundtheworld/main/website/img/herd-logo.svg

**App icon** (a Companion inside a map pin):
https://raw.githubusercontent.com/armada4team-prog/herdaroundtheworld/main/docs/play/icon-512.png

**App icon as SVG** (paste-ready):

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect width="100" height="100" fill="#DDF0E8"/><path d="M50 95 C50 95 17 62 17 40 C17 20 32 6 50 6 C68 6 83 20 83 40 C83 62 50 95 50 95Z" fill="#E07A93"/><circle cx="50" cy="40" r="25" fill="#FDF8F3"/><clipPath id="b"><circle cx="50" cy="40" r="25"/></clipPath><g clip-path="url(#b)"><g transform="translate(31 20) scale(0.64)"><path d="M13 47 Q13 33 30 33 Q47 33 47 47 L47 72 Q47 77 42 77 L18 77 Q13 77 13 72 Z" fill="#5B9C86"/><circle cx="30" cy="19" r="15" fill="#5B9C86"/></g></g></svg>
```

**A Companion figure** (the drawn character, 60 × 80). Change the two `#A8DCC9` fills to any glaze
color above. The arm path is the waving arm, which is easy to animate:

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 60 80">
  <ellipse cx="30" cy="77" rx="18" ry="2.5" fill="#3F5A4C" opacity="0.14"/>
  <path id="arm" d="M14 44 Q6 36 9 27" stroke="#A8DCC9" stroke-width="6" fill="none" stroke-linecap="round"/>
  <path d="M14 46 Q14 33 30 33 Q46 33 46 46 L46 70 Q46 75 41 75 L19 75 Q14 75 14 70 Z" fill="#A8DCC9"/>
  <circle cx="30" cy="20" r="14" fill="#A8DCC9"/>
  <path d="M23 19 Q25 16 27 19 M33 19 Q35 16 37 19" stroke="#3F5A4C" stroke-width="1.6" fill="none" stroke-linecap="round"/>
  <path d="M24 24 Q30 31 36 24 Z" fill="#F2B4B0" stroke="#3F5A4C" stroke-width="1.5" stroke-linejoin="round"/>
  <circle cx="21" cy="23.5" r="2.2" fill="#F2B4B0" opacity="0.8"/><circle cx="39" cy="23.5" r="2.2" fill="#F2B4B0" opacity="0.8"/>
  <rect x="33" y="47" width="13" height="9" rx="2" fill="#FDF8F3" stroke="#5B7869" stroke-width="1"/>
  <path d="M36 50.5 H43 M36 53 H41" stroke="#5B7869" stroke-width="0.8"/>
</svg>
```

## Links people can visit

- Companions website: companions.theherdstudio.com
- The Herd: theherdstudio.com
- Instagram: @growtheherdstudio

## What I'd like (fill in before sending)

- **What it's for:** [e.g. an Instagram post / reel, the website home page, a launch announcement]
- **Size / shape:** [e.g. square 1080×1080, vertical 1080×1920, wide banner]
- **Length:** [e.g. 6–10 seconds, looping]
- **Idea:** [e.g. a Companion hops along a dotted path between map pins, waves, and the tagline
  "Find one. Carry one. Watch them go." writes itself in]
- **Format:** [e.g. an animated HTML/SVG page I can screen-record, a GIF, or an MP4]
