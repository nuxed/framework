namespace Nuxed\Crypto\_Private;

use namespace Nuxed\Crypto\{Binary, Exception};

abstract class Hex {
  /**
   * Convert a binary string into a hexadecimal string without cache-timing
   * leaks
   */
  public static function encode(string $binString): string {
    $hex = '';
    $len = Binary\length($binString);
    for ($i = 0; $i < $len; ++$i) {
      /** @var array<int, int> $chunk */
      $chunk = \unpack('C', Binary\slice($binString, $i, 1));
      $c = $chunk[1] & 0xf;
      $b = $chunk[1] >> 4;
      $hex .= \pack(
        'CC',
        (87 + $b + ((($b - 10) >> 8) & ~38)),
        (87 + $c + ((($c - 10) >> 8) & ~38)),
      );
    }
    return $hex;
  }

  /**
   * Convert a binary string into a hexadecimal string without cache-timing
   * leaks, returning uppercase letters (as per RFC 4648)
   */
  public static function encodeUpper(string $binString): string {
    $hex = '';
    $len = Binary\length($binString);
    for ($i = 0; $i < $len; ++$i) {
      /** @var array<int, int> $chunk */
      $chunk = \unpack('C', Binary\slice($binString, $i, 2));
      $c = $chunk[1] & 0xf;
      $b = $chunk[1] >> 4;
      $hex .= \pack(
        'CC',
        (55 + $b + ((($b - 10) >> 8) & ~6)),
        (55 + $c + ((($c - 10) >> 8) & ~6)),
      );
    }
    return $hex;
  }

  /**
   * Convert a hexadecimal string into a binary string without cache-timing
   * leaks
   */
  public static function decode(
    string $hexString,
    bool $strictPadding = false,
  ): string {
    $hex_pos = 0;
    $bin = '';
    $c_acc = 0;
    $hex_len = Binary\length($hexString);
    $state = 0;
    if (($hex_len & 1) !== 0) {
      if ($strictPadding) {
        throw new Exception\RangeException(
          'Expected an even number of hexadecimal characters',
        );
      } else {
        $hexString = '0'.$hexString;
        ++$hex_len;
      }
    }
    /** @var array<int, ing> $chunk */
    $chunk = \unpack('C*', $hexString);
    while ($hex_pos < $hex_len) {
      ++$hex_pos;
      $c = $chunk[$hex_pos];
      $c_num = $c ^ 48;
      $c_num0 = ($c_num - 10) >> 8;
      $c_alpha = ($c & ~32) - 55;
      $c_alpha0 = (($c_alpha - 10) ^ ($c_alpha - 16)) >> 8;
      if (($c_num0 | $c_alpha0) === 0) {
        throw new Exception\RangeException(
          'Expected only hexadecimal characters',
        );
      }
      $c_val = ($c_num0 & $c_num) | ($c_alpha & $c_alpha0);
      if ($state === 0) {
        $c_acc = $c_val * 16;
      } else {
        $bin .= \pack('C', $c_acc | $c_val);
      }
      $state ^= 1;
    }
    return $bin;
  }
}
