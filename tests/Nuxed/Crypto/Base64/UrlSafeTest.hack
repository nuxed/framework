namespace Nuxed\Test\Crypto\Base64;

use namespace HH\Lib\Str;
use namespace Facebook\HackTest;
use namespace Nuxed\Crypto\Base64;
use namespace Nuxed\Crypto\Binary;
use namespace HH\Lib\SecureRandom;
use function Facebook\FBExpect\expect;

class UrlSafeTest extends HackTest\HackTest {
  <<HackTest\DataProvider('provideRandomBytes')>>
  public function testRandom(string $random): void {
    $enc = Base64\UrlSafe\encode($random);
    expect(Base64\UrlSafe\decode($enc))->toBeSame($random);
    expect($enc)->toBeSame(\strtr(\base64_encode($random), '+/', '-_'));
    $unpadded = Str\trim_right($enc, '=');
    expect(Base64\UrlSafe\encode($random, false))->toBeSame($unpadded);
    expect(Base64\UrlSafe\decode($unpadded))->toBeSame($random);
  }

  public function testStringTruncation(): void {
    $random = \random_bytes(1 << 20);
    $enc = Base64\UrlSafe\encode($random);
    expect(Binary\length($enc))->toBeGreaterThan(65536);
    expect(Base64\UrlSafe\decode($enc))->toBeSame($random);
    expect($enc)->toBeSame(\strtr(\base64_encode($random), '+/', '-_'));
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
