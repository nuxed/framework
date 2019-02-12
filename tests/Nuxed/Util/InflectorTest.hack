namespace Nuxed\Test\Util;

use type Facebook\HackTest\HackTest;
use type Facebook\HackTest\DataProvider;
use type Nuxed\Util\Inflector;
use function Facebook\FBExpect\expect;

class InflectorTest extends HackTest {
  public function provideSingularizeData(
  ): Container<(string, Container<string>)> {
    return vec[
      tuple('accesses', vec['access']),
      tuple('addresses', vec['address']),
      tuple('agendas', vec['agenda']),
      tuple('alumnae', vec['alumna']),
      tuple('alumni', vec['alumnus']),
      tuple('analyses', vec['analys', 'analyse', 'analysis']),
      tuple('antennae', vec['antenna']),
      tuple('antennas', vec['antenna']),
      tuple('appendices', vec['appendex', 'appendix', 'appendice']),
      tuple('arches', vec['arch', 'arche']),
      tuple('atlases', vec['atlas', 'atlase', 'atlasis']),
      tuple('axes', vec['ax', 'axe', 'axis']),
      tuple('babies', vec['baby']),
      tuple('bacteria', vec['bacterion', 'bacterium']),
      tuple('bases', vec['bas', 'base', 'basis']),
      tuple('batches', vec['batch', 'batche']),
      tuple('beaux', vec['beau']),
      tuple('bees', vec['be', 'bee']),
      tuple('boxes', vec['box']),
      tuple('boys', vec['boy']),
      tuple('bureaus', vec['bureau']),
      tuple('bureaux', vec['bureau']),
      tuple('buses', vec['bus', 'buse', 'busis']),
      tuple('bushes', vec['bush', 'bushe']),
      tuple('calves', vec['calf', 'calve', 'calff']),
      tuple('cars', vec['car']),
      tuple('cassettes', vec['cassett', 'cassette']),
      tuple('caves', vec['caf', 'cave', 'caff']),
      tuple('chateaux', vec['chateau']),
      tuple('cheeses', vec['chees', 'cheese', 'cheesis']),
      tuple('children', vec['child']),
      tuple('circuses', vec['circus', 'circuse', 'circusis']),
      tuple('cliffs', vec['cliff']),
      tuple('committee', vec['committee']),
      tuple('crises', vec['cris', 'crise', 'crisis']),
      tuple('criteria', vec['criterion', 'criterium']),
      tuple('cups', vec['cup']),
      tuple('data', vec['daton', 'datum']),
      tuple('days', vec['day']),
      tuple('discos', vec['disco']),
      tuple('devices', vec['devex', 'devix', 'device']),
      tuple('drives', vec['drive']),
      tuple('drivers', vec['driver']),
      tuple('dwarves', vec['dwarf', 'dwarve', 'dwarff']),
      tuple('echoes', vec['echo', 'echoe']),
      tuple('elves', vec['elf', 'elve', 'elff']),
      tuple('emphases', vec['emphas', 'emphase', 'emphasis']),
      tuple('faxes', vec['fax']),
      tuple('feet', vec['foot']),
      tuple('feedback', vec['feedback']),
      tuple('foci', vec['focus']),
      tuple('focuses', vec['focus', 'focuse', 'focusis']),
      tuple('formulae', vec['formula']),
      tuple('formulas', vec['formula']),
      tuple('fungi', vec['fungus']),
      tuple('funguses', vec['fungus', 'funguse', 'fungusis']),
      tuple('garages', vec['garag', 'garage']),
      tuple('geese', vec['goose']),
      tuple('halves', vec['half', 'halve', 'halff']),
      tuple('hats', vec['hat']),
      tuple('heroes', vec['hero', 'heroe']),
      tuple(
        'hippopotamuses',
        vec['hippopotamus', 'hippopotamuse', 'hippopotamusis'],
      ), //hippopotami
      tuple('hoaxes', vec['hoax']),
      tuple('hooves', vec['hoof', 'hoove', 'hooff']),
      tuple('houses', vec['hous', 'house', 'housis']),
      tuple('indexes', vec['index']),
      tuple('indices', vec['index', 'indix', 'indice']),
      tuple('ions', vec['ion']),
      tuple('irises', vec['iris', 'irise', 'irisis']),
      tuple('kisses', vec['kiss']),
      tuple('knives', vec['knife']),
      tuple('lamps', vec['lamp']),
      tuple('leaves', vec['leaf', 'leave', 'leaff']),
      tuple('lice', vec['louse']),
      tuple('lives', vec['life']),
      tuple('matrices', vec['matrex', 'matrix', 'matrice']),
      tuple('matrixes', vec['matrix']),
      tuple('men', vec['man']),
      tuple('mice', vec['mouse']),
      tuple('moves', vec['move']),
      tuple('movies', vec['movie']),
      tuple('nebulae', vec['nebula']),
      tuple('neuroses', vec['neuros', 'neurose', 'neurosis']),
      tuple('news', vec['news']),
      tuple('oases', vec['oas', 'oase', 'oasis']),
      tuple('objectives', vec['objective']),
      tuple('oxen', vec['ox']),
      tuple('parties', vec['party']),
      tuple('people', vec['person']),
      tuple('persons', vec['person']),
      tuple('phenomena', vec['phenomenon', 'phenomenum']),
      tuple('photos', vec['photo']),
      tuple('pianos', vec['piano']),
      tuple('plateaux', vec['plateau']),
      tuple('poppies', vec['poppy']),
      tuple('prices', vec['prex', 'prix', 'price']),
      tuple('quizzes', vec['quiz']),
      tuple('radii', vec['radius']),
      tuple('roofs', vec['roof']),
      tuple('roses', vec['ros', 'rose', 'rosis']),
      tuple('sandwiches', vec['sandwich', 'sandwiche']),
      tuple('scarves', vec['scarf', 'scarve', 'scarff']),
      tuple('schemas', vec['schema']), //schemata
      tuple('selfies', vec['selfie']),
      tuple('series', vec['series']),
      tuple('services', vec['service']),
      tuple('sheriffs', vec['sheriff']),
      tuple('shoes', vec['sho', 'shoe']),
      tuple('spies', vec['spy']),
      tuple('staves', vec['staf', 'stave', 'staff']),
      tuple('stories', vec['story']),
      tuple('strata', vec['straton', 'stratum']),
      tuple('suitcases', vec['suitcas', 'suitcase', 'suitcasis']),
      tuple('syllabi', vec['syllabus']),
      tuple('tags', vec['tag']),
      tuple('teeth', vec['tooth']),
      tuple('theses', vec['thes', 'these', 'thesis']),
      tuple('thieves', vec['thief', 'thieve', 'thieff']),
      tuple('trees', vec['tre', 'tree']),
      tuple('waltzes', vec['waltz', 'waltze']),
      tuple('wives', vec['wife']),
      tuple('Men', vec['Man']),
      tuple('GrandChildren', vec['GrandChild']),
      tuple('SubTrees', vec['SubTre', 'SubTree']),
    ];
  }

  <<DataProvider('provideSingularizeData')>>
  public function testSingularize(
    string $word,
    Container<string> $expected,
  ): void {
    expect(Inflector::singularize($word))->toBeSame($expected);
  }
}
