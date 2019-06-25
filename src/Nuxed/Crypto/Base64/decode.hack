namespace Nuxed\Crypto\Base64 {
  use namespace Nuxed\Crypto\{_Private};

  /**
   * Decode from base64 into binary
   *
   * Base64 character set:
   *  [A-Z]      [a-z]      [0-9]      +     /
   *  0x41-0x5a, 0x61-0x7a, 0x30-0x39, 0x2b, 0x2f
   */
  function decode(string $src, bool $strictPadding = false): string {
    return _Private\Base64::decode($src, $strictPadding);
  }
}

namespace Nuxed\Crypto\Base64\UrlSafe {

  /**
   * Decode from base64 into binary
   *
   * Base64 character set:
   *  [A-Z]      [a-z]      [0-9]      -     _
   *  0x41-0x5a, 0x61-0x7a, 0x30-0x39, 0x2d, 0x5f
   */
  function decode(string $src, bool $strictPadding = false): string {
    return _Private\Base64UrlSafe::decode($src, $strictPadding);
  }
}

namespace Nuxed\Crypto\Base64\DotSlash {

  /**
   * Decode from base64 into binary
   *
   * Base64 character set:
   *  ./         [A-Z]      [a-z]     [0-9]
   *  0x2e-0x2f, 0x41-0x5a, 0x61-0x7a, 0x30-0x39
   */
  function decode(string $src, bool $strictPadding = false): string {
    return _Private\Base64DotSlash::decode($src, $strictPadding);
  }
}

namespace Nuxed\Crypto\Base64\DotSlash\Ordered {

  /**
   * Decode from base64 into binary
   *
   * Base64 character set:
   *  [.-9]      [A-Z]      [a-z]
   *  0x2e-0x39, 0x41-0x5a, 0x61-0x7a
   */
  function decode(string $src, bool $strictPadding = false): string {
    return _Private\Base64DotSlashOrdered::decode($src, $strictPadding);
  }
}
