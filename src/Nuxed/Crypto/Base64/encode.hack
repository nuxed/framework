namespace Nuxed\Crypto\Base64 {
  use namespace Nuxed\Crypto\_Private;

  /**
   * Encode into Base64
   *
   * Base64 character set:
   *  [A-Z]      [a-z]      [0-9]      +     /
   *  0x41-0x5a, 0x61-0x7a, 0x30-0x39, 0x2b, 0x2f
   */
  function encode(string $src, bool $pad = true): string {
    return _Private\Base64::encode($src, $pad);
  }
}

namespace Nuxed\Crypto\Base64\UrlSafe {
  use namespace Nuxed\Crypto\_Private;

  /**
   * Encode into Base64
   *
   * Base64 character set:
   *  [A-Z]      [a-z]      [0-9]      -     _
   *  0x41-0x5a, 0x61-0x7a, 0x30-0x39, 0x2d, 0x5f
   */
  function encode(string $src, bool $pad = true): string {
    return _Private\Base64UrlSafe::encode($src, $pad);
  }
}

namespace Nuxed\Crypto\Base64\DotSlash {
  use namespace Nuxed\Crypto\_Private;

  /**
   * Encode into Base64
   *
   * Base64 character set:
   *  ./         [A-Z]      [a-z]     [0-9]
   *  0x2e-0x2f, 0x41-0x5a, 0x61-0x7a, 0x30-0x39
   */
  function encode(string $src, bool $pad = true): string {
    return _Private\Base64DotSlash::encode($src, $pad);
  }
}

namespace Nuxed\Crypto\Base64\DotSlash\Ordered {
  use namespace Nuxed\Crypto\_Private;

  /**
   * Encode into Base64
   *
   * Base64 character set:
   *  [.-9]      [A-Z]      [a-z]
   *  0x2e-0x39, 0x41-0x5a, 0x61-0x7a
   */
  function encode(string $src, bool $pad = true): string {
    return _Private\Base64DotSlashOrdered::encode($src, $pad);
  }
}
