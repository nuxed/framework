namespace Nuxed\Crypto\Password;

use namespace Nuxed\Crypto;
use namespace Nuxed\Crypto\Binary;

/**
 * Is this password hash stale ?
 */
function needs_rehash(
  string $stored,
  Crypto\SecurityLevel $level = Crypto\SecurityLevel::INTERACTIVE,
): bool {
  // verify that we're using Argon2i
  if (
    !Crypto\Str\equals(
      Binary\slice($stored, 0, 10),
      \SODIUM_CRYPTO_PWHASH_STRPREFIX,
    )
  ) {
    return true;
  }

  switch ($level) {
    case Crypto\SecurityLevel::INTERACTIVE:
      return !Crypto\Str\equals(
        '$argon2id$v=19$m=65536,t=2,p=1$',
        Binary\slice($stored, 0, 31),
      );
    case Crypto\SecurityLevel::MODERATE:
      return !Crypto\Str\equals(
        '$argon2id$v=19$m=262144,t=3,p=1$',
        Binary\slice($stored, 0, 32),
      );
    case Crypto\SecurityLevel::SENSITIVE:
      return !Crypto\Str\equals(
        '$argon2id$v=19$m=1048576,t=4,p=1$',
        Binary\slice($stored, 0, 33),
      );
  }
}
