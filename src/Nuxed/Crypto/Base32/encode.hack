namespace Nuxed\Crypto\Base32 {
  use namespace Nuxed\Crypto;

  /**
   * Encode into Base32 (RFC 4648)
   *
   * Base32 character set:
   *  [a-z]      [2-7]
   *  0x61-0x7a, 0x32-0x37
   */
  function encode(string $src, bool $strictPadding = false): string {
    return Crypto\_Private\Base32::encode($src, false, $strictPadding);
  }

  /**
   * Encode into uppercase Base32 (RFC 4648)
   *
   * Base32 character set:
   *  [A-Z]      [2-7]
   *  0x41-0x5a, 0x32-0x37
   */
  function encode_upper(string $src, bool $strictPadding = false): string {
    return Crypto\_Private\Base32::encode($src, true, $strictPadding);
  }
}

namespace Nuxed\Crypto\Base32\Hex {
  use namespace Nuxed\Crypto;

  /**
   * Encode into Base32 (RFC 4648)
   *
   * Base32 character set:
   *  [0-9]      [a-v]
   *  0x30-0x39, 0x61-0x76
   */
  function encode(string $src, bool $strictPadding = false): string {
    return Crypto\_Private\Base32Hex::encode($src, false, $strictPadding);
  }

  /**
   * Encode into uppercase Base32 (RFC 4648)
   *
   * Base32 character set:
   *  [0-9]      [A-V]
   *  0x30-0x39, 0x41-0x56
   */
  function encode_upper(string $src, bool $strictPadding = false): string {
    return Crypto\_Private\Base32Hex::encode($src, true, $strictPadding);
  }
}
