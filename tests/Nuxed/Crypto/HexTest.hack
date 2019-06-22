namespace Nuxed\Test\Crypto;

use namespace HH\Lib\Str;
use namespace Facebook\HackTest;
use namespace Nuxed\Crypto\Hex;
use namespace HH\Lib\SecureRandom;
use function Facebook\FBExpect\expect;

class HexTest extends HackTest\HackTest {
  <<HackTest\DataProvider('provideRandomBytes')>>
  public function testRandom(string $random): void {
    $enc = Hex\encode($random);
    expect(Hex\decode($enc))->toBeSame($random);
    expect(Hex\encode($random))->toBeSame(\bin2hex($random));
    $enc = Hex\encode_upper($random);
    expect(Hex\decode_upper($enc))->toBeSame($random);
    expect(Hex\decode($enc))->toBeSame($random);
    expect($enc)->toBeSame(Str\uppercase(\bin2hex($random)));
  }

  public function provideRandomBytes(): Container<(string)> {
    $data = vec[];
    for ($i = 1; $i < 32; ++$i) {
      for ($j = 0; $j < 50; ++$j) {
        $data[] = tuple(SecureRandom\string($i));
      }
    }
    return $data;
  }
}
