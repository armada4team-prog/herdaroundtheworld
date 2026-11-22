// Only for the Google Play screenshots (`--dart-define=STORE_SHOTS=true`): the sample data gets
// The Herd's real Originals (names, blurbs, stories, wishes) and friendly traveler names instead
// of placeholders. Normal builds never use this.
import 'models.dart';

const storeShots = bool.fromEnvironment('STORE_SHOTS');

const _originals = {
  '0': ('Stella', 'see a telescope', 'The stars call to me.',
      'This Companion wasn’t made. They fell out of the sky during a meteor shower over Aurora, landed in the studio’s clay bucket and climbed out demanding a form. The Herd gave them one. They’ve been trying to get back to the stars ever since.'),
  '1': ('Wynter', 'ride a train', 'There’s nothing like a good friend to make a chilly day, a happy day.',
      'The first snow of the year fell the day this Companion came out of the kiln. They learned early that the quietest moments can change everything, and they’ve been looking for more of them ever since.'),
  '2': ('Nimbus', 'ride a bike', 'I’ve spent my life with my head in the clouds. Excited to see new things!',
      'They were carved from a piece of a cloud that got too heavy, fell to the ground and turned into clay. That’s why they’re always looking up.'),
  '3': ('Angel', 'meet a dog', 'You found me! Now we’re friends.',
      'On the day they were made, a sunbeam landed right on the worktable and stayed there all afternoon. The Herd says that’s where this Companion’s sunny mood comes from.'),
  '4': ('Sprout', 'smell the roses', 'I love hugs and hope we can be the best of friends.',
      'Some clay is meant to hold flowers. Some is meant to hold water. This clay held a wish so big it needed legs to carry it.'),
  '07': ('Clover', 'see the ocean', 'Lucky to meet you! Where are we going next?',
      'A four-leaf clover was pressed into this clay by accident, and The Herd swears it’s been lucky ever since. Every traveler who carries them says something good happens on the way.'),
};

const _names = {'[TRAVELER]': 'Maya', '[TRAVELER 2]': 'Jonah', '[TRAVELER 3]': 'Priya'};

List<Companion> applyStoreShots(List<Companion> list) {
  if (!storeShots) return list;
  for (final c in list) {
    final o = _originals[c.number];
    if (o != null) {
      c.name = o.$1;
      c.wish = o.$2;
      c.blurb = o.$3;
      c.originStory = o.$4;
    }
    for (var i = 0; i < c.stops.length; i++) {
      final s = c.stops[i];
      final who = _names[s.leftBy];
      if (who == null) continue;
      c.stops[i] = Stop(
        city: s.city, place: s.place, latitude: s.latitude, longitude: s.longitude, leftBy: who, when: s.when,
        note: s.note, photo: s.photo, photoUrl: s.photoUrl, found: s.found, handedOn: s.handedOn, kind: s.kind, date: s.date, id: s.id,
      );
    }
  }
  return list;
}
