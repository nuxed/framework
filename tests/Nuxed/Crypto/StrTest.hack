namespace Nuxed\Test\Crypto;

use namespace HH\Lib\Str as H;
use namespace Nuxed\Crypto\Str;
use namespace Facebook\HackTest;
use namespace HH\Lib\SecureRandom;
use namespace Nuxed\Crypto\Exception;
use function Facebook\FBExpect\expect;

class StrTest extends HackTest\HackTest {
  public function testChrOrd(): void {
    expect(Str\ord("a"))->toBeSame(0x61);
    expect(Str\ord("\xe0"))->toBeSame(0xe0);

    expect(() ==> Str\ord("ab"))->toThrow(
      Exception\InvalidArgumentException::class,
    );

    $random = SecureRandom\int(0, 255);
    expect(Str\ord(Str\chr($random)))->toBeSame($random);
  }

  public function testAssemble(): void {
    expect(Str\assemble(vec[0, 1, 3, 4]))->toBeSame("\x00\x01\x03\x04");
    expect(Str\assemble(vec[256, 257, 259, 260]))->toBeSame(
      "\x00\x01\x03\x04",
      "Masking failed",
    );
  }

  public function testDisasseble(): void {
    expect(vec(Str\disassemble("\x00\x01\x03\x04")))->toBeSame(vec[0, 1, 3, 4]);
  }

  /**
   * Verify that Str\copy() doesn't fall prey to interned strings.
   */
  public function testCopy(): void {
    for ($i = 1; $i <= 128; $i++) {
      $unique = SecureRandom\string($i);
      $clone = Str\copy($unique);
      expect($clone)->toBeSame($unique);
      \sodium_memzero(&$unique);
      expect($clone)->toNotBeSame($unique);
    }
  }

  /**
   * Verify that exclusive_or() produces the expected result.
   */
  public function testXorStrings(): void {
    expect(Str\exclusive_or('', ''))->toBeSame('');
    $a = H\repeat("\x0f", 32);
    $b = H\repeat("\x88", 32);
    expect(Str\exclusive_or($a, $b))->toBeSame(H\repeat("\x87", 32));

    $a .= "\x00";
    expect(() ==> Str\exclusive_or($a, $b))->toThrow(
      Exception\InvalidArgumentException::class,
      'Both strings must be the same length',
    );
  }
}
