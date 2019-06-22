namespace Nuxed\Test\Crypto\Base64\DotSlash;

use namespace HH\Lib\Str;
use namespace Facebook\HackTest;
use namespace Nuxed\Crypto\Base64;
use namespace HH\Lib\SecureRandom;
use function Facebook\FBExpect\expect;

class OrderedTest extends HackTest\HackTest {
  <<HackTest\DataProvider('provideRandomBytes')>>
  public function testRandom(string $random): void {
    $enc = Base64\DotSlash\Ordered\encode($random);
    expect(Base64\DotSlash\Ordered\decode($enc))->toBeSame($random);
    $unpadded = Str\trim_right($enc, '=');
    expect(Base64\DotSlash\Ordered\encode($random, false))->toBeSame($unpadded);
    expect(Base64\DotSlash\Ordered\decode($unpadded))->toBeSame($random);
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
