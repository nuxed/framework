namespace Nuxed\Test\Crypto\Base32;

use namespace HH\Lib\Str;
use namespace Facebook\HackTest;
use namespace Nuxed\Crypto\Base32;
use namespace HH\Lib\SecureRandom;
use function Facebook\FBExpect\expect;

class HexTest extends HackTest\HackTest {
  <<HackTest\DataProvider('provideRandomBytes')>>
  public function testRandom(string $random): void {
    $enc = Base32\Hex\encode($random);
    expect(Base32\Hex\decode($enc))->toBeSame($random);
    $unpadded = Str\trim_right($enc, '=');
    expect(Base32\Hex\encode($random, false))->toBeSame($unpadded);
    expect(Base32\Hex\decode($unpadded))->toBeSame($random);
    $enc = Base32\Hex\encode_upper($random);
    expect(Base32\Hex\decode_upper($enc))->toBeSame($random);
    $unpadded = Str\trim_right($enc, '=');
    expect(Base32\Hex\encode_upper($random, false))->toBeSame($unpadded);
    expect(Base32\Hex\decode_upper($unpadded))->toBeSame($random);
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
