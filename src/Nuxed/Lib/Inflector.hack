namespace Nuxed\Lib;

use namespace HH\Lib\Str;
use function ctype_upper;

final abstract class Inflector {
  /**
   * Map English plural to singular suffixes.
   *
   * @see http://english-zone.com/spelling/plurals.html
   */
  private static vec<(string, int, bool, bool, vec<string>)> $pluralMap = vec[
    // First entry: plural suffix, reversed
    // Second entry: length of plural suffix
    // Third entry: Whether the suffix may succeed a vocal
    // Fourth entry: Whether the suffix may succeed a consonant
    // Fifth entry: singular suffix, normal

    // bacteria (bacterium), criteria (criterion), phenomena (phenomenon)
    tuple('a', 1, true, true, vec['on', 'um']),

    // nebulae (nebula)
    tuple('ea', 2, true, true, vec['a']),

    // services (service)
    tuple('secivres', 8, true, true, vec['service']),

    // mice (mouse), lice (louse)
    tuple('eci', 3, false, true, vec['ouse']),

    // geese (goose)
    tuple('esee', 4, false, true, vec['oose']),

    // fungi (fungus), alumni (alumnus), syllabi (syllabus), radii (radius)
    tuple('i', 1, true, true, vec['us']),

    // men (man), women (woman)
    tuple('nem', 3, true, true, vec['man']),

    // children (child)
    tuple('nerdlihc', 8, true, true, vec['child']),

    // oxen (ox)
    tuple('nexo', 4, false, false, vec['ox']),

    // indices (index), appendices (appendix), prices (price)
    tuple('seci', 4, false, true, vec['ex', 'ix', 'ice']),

    // selfies (selfie)
    tuple('seifles', 7, true, true, vec['selfie']),

    // movies (movie)
    tuple('seivom', 6, true, true, vec['movie']),

    // feet (foot)
    tuple('teef', 4, true, true, vec['foot']),

    // geese (goose)
    tuple('eseeg', 5, true, true, vec['goose']),

    // teeth (tooth)
    tuple('hteet', 5, true, true, vec['tooth']),

    // news (news)
    tuple('swen', 4, true, true, vec['news']),

    // series (series)
    tuple('seires', 6, true, true, vec['series']),

    // babies (baby)
    tuple('sei', 3, false, true, vec['y']),

    // accesses (access), addresses (address), kisses (kiss)
    tuple('sess', 4, true, false, vec['ss']),

    // analyses (analysis), ellipses (ellipsis), fungi (fungus),
    // neuroses (neurosis), theses (thesis), emphases (emphasis),
    // oases (oasis), crises (crisis), houses (house), bases (base),
    // atlases (atlas)
    tuple('ses', 3, true, true, vec['s', 'se', 'sis']),

    // objectives (objective), alternative (alternatives)
    tuple('sevit', 5, true, true, vec['tive']),

    // drives (drive)
    tuple('sevird', 6, false, true, vec['drive']),

    // lives (life), wives (wife)
    tuple('sevi', 4, false, true, vec['ife']),

    // moves (move)
    tuple('sevom', 5, true, true, vec['move']),

    // hooves (hoof), dwarves (dwarf), elves (elf), leaves (leaf), caves (cave), staves (staff)
    tuple('sev', 3, true, true, vec['f', 've', 'ff']),

    // axes (axis), axes (ax), axes (axe)
    tuple('sexa', 4, false, false, vec['ax', 'axe', 'axis']),

    // indexes (index), matrixes (matrix)
    tuple('sex', 3, true, false, vec['x']),

    // quizzes (quiz)
    tuple('sezz', 4, true, false, vec['z']),

    // bureaus (bureau)
    tuple('suae', 4, false, true, vec['eau']),

    // roses (rose), garages (garage), cassettes (cassette),
    // waltzes (waltz), heroes (hero), bushes (bush), arches (arch),
    // shoes (shoe)
    tuple('se', 2, true, true, vec['', 'e']),

    // tags (tag)
    tuple('s', 1, true, true, vec['']),

    // chateaux (chateau)
    tuple('xuae', 4, false, true, vec['eau']),

    // people (person)
    tuple('elpoep', 6, true, true, vec['person']),
  ];

  /**
   * Returns the singular possibilities form of a word.
   *
   * @param string $plural A word in plural form
   *
   * @return container of possible singular forms
   */
  public static function singularize(string $plural): Container<string> {
    $pluralRev = Str\reverse($plural);
    $lowerPluralRev = Str\lowercase($pluralRev);
    $pluralLength = Str\length($lowerPluralRev);

    // The outer loop iterates over the entries of the plural table
    // The inner loop $j iterates over the characters of the plural suffix
    // in the plural table to compare them with the characters of the actual
    // given plural suffix
    foreach (self::$pluralMap as $map) {
      $suffix = $map[0];
      $suffixLength = $map[1];
      $j = 0;

      // Compare characters in the plural table and of the suffix of the
      // given plural one by one
      while ($suffix[$j] === $lowerPluralRev[$j]) {
        // Let $j point to the next character
        ++$j;

        // Successfully compared the last character
        // Add an entry with the singular suffix to the singular array
        if ($j === $suffixLength) {
          // Is there any character preceding the suffix in the plural string?
          if ($j < $pluralLength) {
            $nextIsVocal = Str\contains('aeiou', $lowerPluralRev[$j]);

            if (!$map[2] && $nextIsVocal) {
              // suffix may not succeed a vocal but next char is one
              break;
            }

            if (!$map[3] && !$nextIsVocal) {
              // suffix may not succeed a consonant but next char is one
              break;
            }
          }

          $newBase = Str\slice($plural, 0, $pluralLength - $suffixLength);
          $newSuffix = $map[4];

          // Check whether the first character in the plural suffix
          // is uppercased. If yes, uppercase the first character in
          // the singular suffix too
          $firstUpper = ctype_upper($pluralRev[$j - 1]);

          $singulars = vec[];

          foreach ($newSuffix as $newSuffixEntry) {
            $singulars[] = $newBase.
              ($firstUpper ? Str\capitalize($newSuffixEntry) : $newSuffixEntry);
          }

          return $singulars;
        }

        // Suffix is longer than word
        if ($j === $pluralLength) {
          break;
        }
      }
    }

    // Assume that plural and singular is identical
    return vec[$plural];
  }
}
