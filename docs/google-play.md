# Google Play: everything to paste in

Play Console → your app → the sections below. Copy each box as it is.

## Store listing (Grow users → Store presence → Main store listing)

**App name** (30 characters max)

```
Herd Around the World
```

**Short description** (80 characters max)

```
Find a clay Companion, carry it a while, pass it on and watch where it goes.
```

**Full description** (4,000 characters max)

```
Little clay Companions, handmade by The Herd in Aurora, Colorado, are traveling the world one person at a time. Herd Around the World lets you follow them.

FIND ONE
Spot a Companion on a café shelf, a windowsill or a park bench. Scan the code on their bottom (or type their number and find code) to say hello and see where they've been.

CARRY ONE
Take them along for a while. Every Companion has a wish, like riding a train or seeing the ocean. Help make it come true and choose their next one.

PASS THEM ON
Hand them to someone new, or leave them somewhere they'll be found. Add a photo and a line to their story, and watch where they go next.

WHAT'S INSIDE
• A world map of every Companion's journey
• Each Companion's story, written chapter by chapter by the people who carried them
• A Passport with stamps for every Companion you carry and every wish you grant
• Traveler chat for each Companion
• Follow your favorites and see when they move
• English, Spanish, French and Japanese

GOOD TO KNOW
• Free, with no ads and no purchases.
• No account needed. Signing in with your email is optional and keeps your Passport on every device.
• You choose whether the map shows the exact spot or only the general area.
• Photos are checked by The Herd before anyone else sees them.

Made with love by The Herd, a small handmade ceramics studio. theherdstudio.com
```

**Graphics**

- App icon (512 × 512): `docs/play/icon-512.png`
- Feature graphic (1024 × 500): `docs/play/feature-graphic.png`
- Phone screenshots: `docs/play/screenshot-1.png` … (upload all of them)

**Category:** Travel & Local (or Lifestyle). **Tags:** pick "Travel" and "Art".

**Contact details:** email growtheherd@gmail.com, website https://www.theherdstudio.com

## Privacy policy (Policy → App content → Privacy policy)

Your Privacy Policy page on theherdstudio.com (copy its address from the browser).

## App access

"All functionality is available without special access." (No login is required.)

## Ads

"No, my app does not contain ads."

## Content rating questionnaire

- Category: **All other app types**
- Violence, sexuality, language, drugs, gambling: **No** to all
- "Can users interact or exchange information?" **Yes** (traveler chat and story chapters)
- "Does the app share the user's current location with other users?" **Yes** (the map pin of a find or stop)
- "Can users purchase digital goods?" **No**

## Target audience

- Target age groups: **13–15, 16–17, 18 and over**. Don't pick any group under 13.
- "Could the app unintentionally appeal to children?" Answer honestly; if asked, explain it's a community art project for teens and adults, and children take part with a parent.

## Data safety (Policy → App content → Data safety)

**Does your app collect or share user data?** Yes.
**Is all collected data encrypted in transit?** Yes.
**Do you provide a way for users to request that their data is deleted?** Yes.

Data types to tick (for each: **Collected: yes**, **Shared: no**, **Processed ephemerally: no**):

| Data type | Required or optional | Why |
|---|---|---|
| Location → **Precise location** | Optional (only when logging a find or stop) | App functionality |
| Location → **Approximate location** | Optional | App functionality |
| Personal info → **Name** (the nickname they choose) | Optional | App functionality |
| Personal info → **Email address** | Optional | App functionality, Account management, Developer communications |
| Photos and videos → **Photos** | Optional | App functionality |
| Messages → **Other in-app messages** (traveler chat, story chapters) | Optional | App functionality |

Nothing is used for advertising or analytics, and nothing is sold.

**Account deletion URL** (asked because email sign-in exists):

```
https://companions.theherdstudio.com/#/passport
```

(Users sign in there and use **Delete my data**, or email growtheherd@gmail.com.)

## Permissions declarations

- **Camera:** scanning a Companion's QR code and taking a photo when passing them on.
- **Location (precise):** logging where a Companion was found, handed on or left. Only while using the app; never in the background.

## Releases

1. Testing → **Closed testing** → create a track, add at least **12 testers** (their Gmail addresses), upload `herd-around-the-world.aab` from the GitHub test-build page.
2. Testers open the opt-in link, install, and keep it for **14 days**.
3. Then **Apply for production** and upload the latest `.aab` to Production.
