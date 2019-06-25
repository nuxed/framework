namespace Nuxed\Crypto\Base32 {
  use namespace Nuxed\Crypto\{_Private};

  /**
   * Decode a Base32-encoded string into raw binary
   *
   * Base32 character set:
   *  [a-z]      [2-7]
   *  0x61-0x7a, 0x32-0x37
   */
  function decode(string $src, bool $strictPadding = false): string {
    return _Private\Base32::decode($src, false, $strictPadding);
  }

  /**
   * Decode a Base32-encoded uppercase string into raw binary
   *
   * Base32 character set:
   *  [A-Z]      [2-7]
   *  0x41-0x5a, 0x32-0x37
   */
  function decode_upper(string $src, bool $strictPadding = false): string {
    return _Private\Base32::decode($src, true, $strictPadding);
  }
}

namespace Nuxed\Crypto\Base32\Hex {

  /**
   * Decode a Base32-encoded string into raw binary
   *
   * Base32 character set:
   *  [0-9]      [a-v]
   *  0x30-0x39, 0x61-0x76
   */
  function decode(string $src, bool $strictPadding = false): string {
    return _Private\Base32Hex::decode($src, false, $strictPadding);
  }

  /**
   * Decode a Base32-encoded uppercase string into raw binary
   *
   * Base32 character set:
   *  [0-9]      [A-V]
   *  0x30-0x39, 0x41-0x56
   */
  function decode_upper(string $src, bool $strictPadding = false): string {
    return _Private\Base32Hex::decode($src, true, $strictPadding);
  }
}
