/// Deterministic alias generator for auction participants.
/// Produces the same alias for a given (auctionId, userId) pair every time.
/// Uses the same word lists as the SQL function in migration 00133.
class AuctionAliasGenerator {
  static const _adjectives = [
    'Swift',
    'Bold',
    'Clever',
    'Brave',
    'Noble',
    'Lucky',
    'Keen',
    'Calm',
    'Wise',
    'Bright',
    'Rapid',
    'Steady',
    'Sharp',
    'Fierce',
    'Quick',
    'Silent',
    'Mystic',
    'Phantom',
    'Shadow',
    'Crimson',
    'Golden',
    'Silver',
    'Iron',
    'Crystal',
    'Storm',
    'Thunder',
    'Frost',
    'Blaze',
    'Dusk',
    'Dawn',
  ];

  static const _animals = [
    'Eagle',
    'Tiger',
    'Falcon',
    'Wolf',
    'Bear',
    'Hawk',
    'Fox',
    'Lion',
    'Panther',
    'Viper',
    'Stallion',
    'Cobra',
    'Raven',
    'Phoenix',
    'Dragon',
    'Shark',
    'Bison',
    'Lynx',
    'Jaguar',
    'Condor',
    'Mustang',
    'Puma',
    'Osprey',
    'Raptor',
    'Gorilla',
    'Rhino',
    'Cheetah',
    'Orca',
    'Mantis',
    'Griffin',
  ];

  AuctionAliasGenerator._();

  /// Generate a deterministic alias from auctionId and userId.
  static String generate(String auctionId, String userId) {
    final h1 = _fnv1a('$auctionId:$userId');
    final h2 = _fnv1a('$userId:$auctionId');
    final adj = _adjectives[h1 % _adjectives.length];
    final animal = _animals[h2 % _animals.length];
    return '$adj $animal';
  }

  /// FNV-1a 32-bit hash – simple, fast, deterministic across runs.
  static int _fnv1a(String input) {
    int h = 0x811c9dc5;
    for (int i = 0; i < input.length; i++) {
      h ^= input.codeUnitAt(i);
      h = (h * 0x01000193) & 0xFFFFFFFF;
    }
    return h.abs();
  }
}
