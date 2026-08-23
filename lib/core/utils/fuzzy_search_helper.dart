class FuzzySearchHelper {
  static const Map<String, String> corrections = {
    'maketa': 'makita',
    'macketa': 'makita',
    'macta': 'makita',
    'makit': 'makita',
    'bosh': 'bosch',
    'bocsh': 'bosch',
    'boshe': 'bosch',
    'dewalt': 'dewalt',
    'devault': 'dewalt',
    'devalt': 'dewalt',
    'dewat': 'dewalt',
    'milwoki': 'milwaukee',
    'milwakee': 'milwaukee',
    'stanli': 'stanley',
    'stanly': 'stanley',
    'taparia': 'taparia',
    'taparja': 'taparia',
    '3m': '3m',
    'threem': '3m',
    'black and decker': 'black & decker',
    'black & decker': 'black & decker',
    'ryobi': 'ryobi',
    'riobi': 'ryobi',
    
    // Tools
    'dril': 'drill',
    'drils': 'drill',
    'driller': 'drill',
    'dril machine': 'drill machine',
    'hamer': 'hammer',
    'hammers': 'hammer',
    'saw': 'saw',
    'saws': 'saw',
    'sew': 'saw',
    'spanner': 'spanner',
    'spaner': 'spanner',
    'wrench': 'wrench',
    'rensch': 'wrench',
    'wrensh': 'wrench',
    'goggle': 'goggles',
    'gogles': 'goggles',
    'safety gogle': 'safety goggles',
    'safty': 'safety',
    'safty gear': 'safety gear',
  };

  static String? getCorrection(String query) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return null;
    if (corrections.containsKey(clean)) {
      return corrections[clean];
    }
    
    final words = clean.split(RegExp(r'\s+'));
    final correctedWords = words.map((word) {
      if (corrections.containsKey(word)) {
        return corrections[word]!;
      }
      
      // Only accept a fuzzy correction when the edit distance is small
      // relative to the word length. maxDistance is 0 for words shorter than
      // 4 chars, so such words require an exact match (already handled above)
      // and plausibly-valid queries like "raw", "war" or "sea" are never
      // mangled into unrelated dictionary keys.
      final maxDistance = word.length ~/ 4;
      String bestMatch = word;
      int bestDistance = maxDistance + 1; // a candidate must beat this

      for (final key in corrections.keys) {
        // A genuine typo rarely changes the length by more than one char.
        if ((key.length - word.length).abs() > 1) continue;
        final d = _levenshtein(word, key);
        if (d < bestDistance) {
          bestDistance = d;
          bestMatch = corrections[key]!;
        }
      }
      return bestMatch;
    }).toList();
    
    final correctedQuery = correctedWords.join(' ');
    if (correctedQuery != clean) {
      return correctedQuery;
    }
    return null;
  }

  static int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.generate(t.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < t.length; j++) {
        int cost = (s[i] == t[j]) ? 0 : 1;
        v1[j + 1] = _min3(v1[j] + 1, v0[j + 1] + 1, v0[j] + cost);
      }
      for (int j = 0; j < v0.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v0[t.length];
  }

  static int _min3(int a, int b, int c) =>
      a < b ? (a < c ? a : c) : (b < c ? b : c);
}
