namespace Nuxed\Crypto;

enum SecurityLevel: int {
  INTERACTIVE = 0;
  MODERATE = 1;
  SENSITIVE = 2;
}

function kdf_limits(SecurityLevel $level): (int, int) {
  switch ($level) {
    case SecurityLevel::INTERACTIVE:
      return tuple(
        \SODIUM_CRYPTO_PWHASH_OPSLIMIT_INTERACTIVE,
        \SODIUM_CRYPTO_PWHASH_MEMLIMIT_INTERACTIVE,
      );
    case SecurityLevel::MODERATE:
      return tuple(
        \SODIUM_CRYPTO_PWHASH_OPSLIMIT_MODERATE,
        \SODIUM_CRYPTO_PWHASH_MEMLIMIT_MODERATE,
      );
    case SecurityLevel::SENSITIVE:
      return tuple(
        \SODIUM_CRYPTO_PWHASH_OPSLIMIT_SENSITIVE,
        \SODIUM_CRYPTO_PWHASH_MEMLIMIT_SENSITIVE,
      );
  }
}
