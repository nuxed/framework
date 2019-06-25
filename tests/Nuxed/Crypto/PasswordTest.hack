namespace Nuxed\Test\Crypto;

use namespace Nuxed\Crypto;
use namespace Facebook\HackTest;
use namespace HH\Lib\SecureRandom;
use namespace Nuxed\Crypto\Password;
use function Facebook\FBExpect\expect;

class PasswordTest extends HackTest\HackTest {
  <<HackTest\DataProvider('provideRandomPasswords')>>
  public function testRandom(Crypto\HiddenString $password): void {
    $interactive = Password\hash($password, Crypto\SecurityLevel::INTERACTIVE);
    $moderate = Password\hash($password, Crypto\SecurityLevel::MODERATE);
    $sensitive = Password\hash($password, Crypto\SecurityLevel::SENSITIVE);

    expect(Password\verify($password, $interactive))->toBeTrue();
    expect(Password\verify($password, $moderate))->toBeTrue();
    expect(Password\verify($password, $sensitive))->toBeTrue();

    expect(
      Password\needs_rehash($interactive, Crypto\SecurityLevel::INTERACTIVE),
    )->toBeFalse();
    expect(Password\needs_rehash($interactive, Crypto\SecurityLevel::MODERATE))
      ->toBeTrue();
    expect(Password\needs_rehash($interactive, Crypto\SecurityLevel::SENSITIVE))
      ->toBeTrue();

    expect(Password\needs_rehash($moderate, Crypto\SecurityLevel::INTERACTIVE))
      ->toBeTrue();
    expect(Password\needs_rehash($moderate, Crypto\SecurityLevel::MODERATE))
      ->toBeFalse();
    expect(Password\needs_rehash($moderate, Crypto\SecurityLevel::SENSITIVE))
      ->toBeTrue();

    expect(Password\needs_rehash($sensitive, Crypto\SecurityLevel::INTERACTIVE))
      ->toBeTrue();
    expect(Password\needs_rehash($sensitive, Crypto\SecurityLevel::MODERATE))
      ->toBeTrue();
    expect(Password\needs_rehash($sensitive, Crypto\SecurityLevel::SENSITIVE))
      ->toBeFalse();
  }

  public function provideRandomPasswords(): Container<(Crypto\HiddenString)> {
    $passwords = vec[];
    for ($i = 1; $i < 7; $i++) {
      $passwords[] = tuple(
        new Crypto\HiddenString(SecureRandom\string($i * 32)),
      );
    }
    return $passwords;
  }
}
