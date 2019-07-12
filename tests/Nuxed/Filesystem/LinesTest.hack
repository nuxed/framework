namespace Nuxed\Test\Filesystem;

use namespace Nuxed\Filesystem;
use type Facebook\HackTest\HackTest;
use type Facebook\HackTest\DataProvider;
use function Facebook\FBExpect\expect;

class LinesTest extends HackTest {
  <<DataProvider('provideCountData')>>
  public function testCount(Container<string> $lines, int $expected): void {
    $lines = new Filesystem\Lines($lines);
    expect($lines->count())->toBeSame($expected);
  }

  public function provideCountData(): Container<(Container<string>, int)> {
    return vec[
      tuple(vec[], 0),
      tuple(vec['foo', 'bar', 'baz'], 3),
      tuple(vec['foo', 'bar', 'baz', 'qux'], 4),
      tuple(vec['foo'], 1),
    ];
  }

  <<DataProvider('provideFirstData')>>
  public function testFirst(Container<string> $lines, string $expected): void {
    $lines = new Filesystem\Lines($lines);
    expect($lines->first())->toBeSame($expected);
  }

  public function provideFirstData(): Container<(Container<string>, string)> {
    return vec[
      tuple(vec[''], ''),
      tuple(vec['', 'foo', 'bar'], ''),
      tuple(vec['foo', 'foo'], 'foo'),
      tuple(vec['bar', 'baz'], 'bar'),
    ];
  }

  public function testFirstThrowsForEmptyLines(): void {
    $lines = new Filesystem\Lines(vec[]);
    expect(() ==> $lines->first())
      ->toThrow(
        Filesystem\Exception\OutOfRangeException::class,
        'Lines instance is empty.',
      );
  }

  <<DataProvider('provideJumpData')>>
  public function testJump(
    Container<string> $lines,
    string $expectedFirst,
    Container<string> $expectedRest,
  ): void {
    $lines = new Filesystem\Lines($lines);
    list($first, $rest) = $lines->jump();
    expect($first)
      ->toBeSame($expectedFirst);
    expect(vec($rest->getIterator()))
      ->toBeSame(vec($expectedRest));
  }

  public function provideJumpData(
  ): Container<(Container<string>, string, Container<string>)> {
    return vec[
      tuple(vec['foo'], 'foo', vec[]),
      tuple(vec['foo', 'bar'], 'foo', vec['bar']),
      tuple(vec['foo', 'bar', 'baz'], 'foo', vec['bar', 'baz']),
      tuple(vec[''], '', vec[]),
    ];
  }

  <<DataProvider('provideBlankData')>>
  public function testBlank(string $line, bool $expected): void {
    Filesystem\Lines::blank($line)
      |> expect($$)->toBeSame($expected);
  }

  public function provideBlankData(): Container<(string, bool)> {
    return vec[
      tuple('', true),
      tuple(" \t", true),
      tuple('foo', false),
      tuple(' ', true),
      tuple(
        '
      ',
        false,
      ),
      tuple(
        '
',
        false,
      ),
    ];
  }

  <<DataProvider('provideToStringData')>>
  public function testToString(
    Container<string> $lines,
    string $expected,
  ): void {
    new Filesystem\Lines($lines)
      |> $$->toString()
      |> expect($$)->toBeSame($expected);
  }

  public function provideToStringData(
  ): Container<(Container<string>, string)> {
    return vec[
      tuple(vec[], ''),
      tuple(vec['foo'], 'foo'),
      tuple(
        vec['foo', 'bar'],
        'foo
bar',
      ),
    ];
  }

  public function testLinesIsIterator(): void {
    $lines = new Filesystem\Lines(vec['foo', 'bar']);
    $result = vec[];
    foreach ($lines as $line) {
      $result[] = $line;
    }
    expect($result)->toBeSame(vec['foo', 'bar']);
  }
}
