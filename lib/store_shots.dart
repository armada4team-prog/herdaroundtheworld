// Only for the Google Play screenshots (`--dart-define=STORE_SHOTS=true`): the app starts on The
// Herd's real Companions exactly as they are in the Wix lists today (all six waiting at the
// studio), as a brand-new traveler would see them: nothing found, nothing followed, no stamps.
// Normal builds never use this.
import 'wix_api.dart';

const storeShots = bool.fromEnvironment('STORE_SHOTS');

/// The Companions and their first stops, copied from The Herd's Wix lists.
WixLists storeShotLists() => WixLists.fromJson(_lists)!;

const Map<String, Object> _lists = {
  "companions": [
    {
      "number": "0",
      "name": "Stella",
      "isOriginal": true,
      "status": "waiting",
      "wish": "see a telescope",
      "wishGranted": false,
      "glaze": "F4C7C3",
      "accent": "E58FA6",
      "blob": "FBE4E2",
      "blurb": "The stars call to me.",
      "originStory": "This Companion wasn’t made. They fell out of the sky during a meteor shower over Aurora, landed in the studio’s clay bucket and climbed out demanding a form. The Herd gave them one. They’ve been trying to get back to the stars ever since."
    },
    {
      "number": "1",
      "name": "Wynter",
      "isOriginal": true,
      "status": "waiting",
      "wish": "ride a train",
      "wishGranted": false,
      "glaze": "A8DCC9",
      "accent": "5FA8A0",
      "blob": "DDF0E8",
      "blurb": "There's nothing like a good friend to make a chilly day, a happy day.",
      "originStory": "The first snow of the year fell the day this Companion came out of the kiln. They learned early that the quietest moments can change everything, and they’ve been looking for more of them ever since."
    },
    {
      "number": "2",
      "name": "Nimbus",
      "isOriginal": true,
      "status": "waiting",
      "wish": "ride a bike",
      "wishGranted": false,
      "glaze": "F6E3A1",
      "accent": "E0B94A",
      "blob": "FBF3D6",
      "blurb": "I've spent my life with my head in the clouds. Excited to see new things!",
      "originStory": "They were carved from a piece of a cloud that got too heavy, fell to the ground and turned into clay. That’s why they’re always looking up."
    },
    {
      "number": "3",
      "name": "Angel",
      "isOriginal": true,
      "status": "waiting",
      "wish": "meet a dog",
      "wishGranted": false,
      "glaze": "D9CCEB",
      "accent": "A08BC9",
      "blob": "EFE9F7",
      "blurb": "You found me! Now we’re friends.",
      "originStory": "On the day they were made, a sunbeam landed right on the worktable and stayed there all afternoon. The Herd says that’s where this Companion’s sunny mood comes from. The Companion says they’ve been following that sunbeam ever since."
    },
    {
      "number": "4",
      "name": "Sprout",
      "isOriginal": true,
      "status": "waiting",
      "wish": "smell the roses",
      "wishGranted": false,
      "glaze": "BFDDF0",
      "accent": "7FB2D9",
      "blob": "E5F1FA",
      "blurb": "I love hugs and hope we can be the best of friends.",
      "originStory": "Some clay is meant to hold flowers. Some is meant to hold water. This clay held a wish so big it needed legs to carry it. It was dug from the edge of a garden bed, still tangled with roots and smelling of rain, and it never forgot where it came from. Now this companion stops for every flower, says hello to every tree, and believes the best views are the ones you have to walk to."
    },
    {
      "number": "5",
      "name": "Bubba",
      "isOriginal": true,
      "status": "waiting",
      "wish": "visit a restaurant",
      "wishGranted": false,
      "glaze": "F4C7C3",
      "accent": "D98C86",
      "blob": "DDF0E8",
      "blurb": "I don’t take up much room, I never complain about the window seat, and I love snacks",
      "originStory": "The day they were made, a train whistle echoed across Aurora, long and lonely. This Companion heard something else in it: an invitation. They’ve been saying yes ever since."
    }
  ],
  "stops": [
    {
      "companionNumber": "0",
      "kind": "made",
      "city": "Aurora, CO",
      "latitude": 39.74247,
      "longitude": -104.81046,
      "byName": "The Herd",
      "whenText": "Where they were made"
    },
    {
      "companionNumber": "1",
      "kind": "made",
      "city": "Aurora, CO",
      "latitude": 39.74247,
      "longitude": -104.81046,
      "byName": "The Herd",
      "whenText": "Where they were made"
    },
    {
      "companionNumber": "2",
      "kind": "made",
      "city": "Aurora, CO",
      "latitude": 39.74247,
      "longitude": -104.81046,
      "byName": "The Herd",
      "whenText": "Where they were made"
    },
    {
      "companionNumber": "3",
      "kind": "made",
      "city": "Aurora, CO",
      "latitude": 39.74247,
      "longitude": -104.81046,
      "byName": "The Herd",
      "whenText": "Where they were made"
    },
    {
      "companionNumber": "4",
      "kind": "made",
      "city": "Aurora, CO",
      "latitude": 39.74247,
      "longitude": -104.81046,
      "byName": "The Herd",
      "whenText": "Where they were made"
    },
    {
      "companionNumber": "5",
      "kind": "made",
      "city": "Aurora, CO",
      "latitude": 39.74247,
      "longitude": -104.81046,
      "byName": "The Herd",
      "whenText": "Where they were made"
    }
  ]
};
