namespace Nuxed\Test\Crypto;

use namespace HH\Lib\Str;
use namespace Facebook\HackTest;
use namespace Nuxed\Crypto\Binary;
use namespace HH\Lib\SecureRandom;
use function Facebook\FBExpect\expect;

class BinaryTest extends HackTest\HackTest {
  <<HackTest\DataProvider('provideLengthData')>>
  public function testLength(string $input, int $expected): void {
    expect(Binary\length($input))->toBeSame($expected);
  }

  public function provideLengthData(): Container<(string, int)> {
    $data = vec[];
    for ($i = 1; $i < 50; $i++) {
      for ($j = 1; $j < 32; $j++) {
        $data[] = tuple(SecureRandom\string($i), $i);
        $data[] = tuple(SecureRandom\string($j), $j);
        $data[] = tuple(SecureRandom\string($i + $j), $i + $j);
        $data[] = tuple(SecureRandom\string($i * $j), $i * $j);
      }
    }
    return $data;
  }
}
