namespace Nuxed\Test\Util;

use type Facebook\HackTest\HackTest;
use type Facebook\HackTest\DataProvider;
use function Facebook\FBExpect\expect;
use function Nuxed\Util\alternatives;

class AlternativesTest extends HackTest {
  <<DataProvider('data')>>
  public function testAlternatives(
    string $name,
    Container<string> $items,
    Container<string> $expected,
  ): void {
    $result = alternatives($name, $items);
    // the alternatives function can return
    // any type of container, so we need to ensure that
    // both the $result and $expected are the same type.
    $result = vec($result);
    $expected = vec($expected);
    expect($result)->toBeSame($expected);
  }

  public function data(
  ): Container<(string, Container<string>, Container<string>)> {
    return vec[
      tuple('helo', vec['hello', 'morning'], Set {'hello'}),
      tuple(
        'daiky',
        vec['daily', 'weekly', 'monthly', 'dairy', 'book'],
        vec['daily', 'dairy'],
      ),
      tuple('foet', vec['foot', 'feet', 'boot', 'fool'], vec['foot', 'feet']),
    ];
  }
}
