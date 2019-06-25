namespace Nuxed\Crypto\_Private;

use namespace HH\Lib\Str;
use namespace Nuxed\Crypto\{Binary, Exception};

<<__Sealed(
  Base64UrlSafe::class,
  Base64DotSlash::class,
  Base64DotSlashOrdered::class,
)>>
abstract class Base64 {
  /**
   * Encode into Base64
   *
   * Base64 character set "[A-Z][a-z][0-9]+/"
   */
  public static function encode(string $src, bool $pad = true): string {
    $dest = '';
    $srcLen = Binary\length($src);
    // Main loop (no padding):
    for ($i = 0; $i + 3 <= $srcLen; $i += 3) {
      /** @var array<int, int> $chunk */
      $chunk = \unpack('C*', Binary\slice($src, $i, 3));
      $b0 = $chunk[1];
      $b1 = $chunk[2];
      $b2 = $chunk[3];
      $dest .= static::encode6Bits($b0 >> 2).
        static::encode6Bits((($b0 << 4) | ($b1 >> 4)) & 63).
        static::encode6Bits((($b1 << 2) | ($b2 >> 6)) & 63).
        static::encode6Bits($b2 & 63);
    }
    // The last chunk, which may have padding:
    if ($i < $srcLen) {
      /** @var array<int, int> $chunk */
      $chunk = \unpack('C*', Binary\slice($src, $i, $srcLen - $i));
      $b0 = $chunk[1];
      if ($i + 1 < $srcLen) {
        $b1 = $chunk[2];
        $dest .= static::encode6Bits($b0 >> 2).
          static::encode6Bits((($b0 << 4) | ($b1 >> 4)) & 63).
          static::encode6Bits(($b1 << 2) & 63);
        if ($pad) {
          $dest .= '=';
        }
      } else {
        $dest .= static::encode6Bits($b0 >> 2).
          static::encode6Bits(($b0 << 4) & 63);
        if ($pad) {
          $dest .= '==';
        }
      }
    }
    return $dest;
  }

  /**
   * decode from base64 into binary
   *
   * Base64 character set "./[A-Z][a-z][0-9]"
   */
  public static function decode(
    string $src,
    bool $strictPadding = false,
  ): string {
    // Remove padding
    $srcLen = Binary\length($src);
    if ($srcLen === 0) {
      return '';
    }
    if ($strictPadding) {
      if (($srcLen & 3) === 0) {
        if ($src[$srcLen - 1] === '=') {
          $srcLen--;
          if ($src[$srcLen - 1] === '=') {
            $srcLen--;
          }
        }
      }
      if (($srcLen & 3) === 1) {
        throw new Exception\RangeException('Incorrect padding');
      }
      if ($src[$srcLen - 1] === '=') {
        throw new Exception\RangeException('Incorrect padding');
      }
    } else {
      $src = Str\trim_right($src, '=');
      $srcLen = Binary\length($src);
    }
    $err = 0;
    $dest = '';
    // Main loop (no padding):
    for ($i = 0; $i + 4 <= $srcLen; $i += 4) {
      /** @var array<int, int> $chunk */
      $chunk = \unpack('C*', Binary\slice($src, $i, 4));
      $c0 = static::decode6Bits($chunk[1]);
      $c1 = static::decode6Bits($chunk[2]);
      $c2 = static::decode6Bits($chunk[3]);
      $c3 = static::decode6Bits($chunk[4]);
      $dest .= \pack(
        'CCC',
        ((($c0 << 2) | ($c1 >> 4)) & 0xff),
        ((($c1 << 4) | ($c2 >> 2)) & 0xff),
        ((($c2 << 6) | $c3) & 0xff),
      );
      $err |= ($c0 | $c1 | $c2 | $c3) >> 8;
    }
    // The last chunk, which may have padding:
    if ($i < $srcLen) {
      /** @var array<int, int> $chunk */
      $chunk = \unpack('C*', Binary\slice($src, $i, $srcLen - $i));
      $c0 = static::decode6Bits($chunk[1]);
      if ($i + 2 < $srcLen) {
        $c1 = static::decode6Bits($chunk[2]);
        $c2 = static::decode6Bits($chunk[3]);
        $dest .= \pack(
          'CC',
          ((($c0 << 2) | ($c1 >> 4)) & 0xff),
          ((($c1 << 4) | ($c2 >> 2)) & 0xff),
        );
        $err |= ($c0 | $c1 | $c2) >> 8;
      } else if ($i + 1 < $srcLen) {
        $c1 = static::decode6Bits($chunk[2]);
        $dest .= \pack('C', ((($c0 << 2) | ($c1 >> 4)) & 0xff));
        $err |= ($c0 | $c1) >> 8;
      } else if ($i < $srcLen && $strictPadding) {
        $err |= 1;
      }
    }
    /** @var bool $check */
    $check = ($err === 0);
    if (!$check) {
      throw new Exception\RangeException(
        'Expected characters in the correct base64 alphabet',
      );
    }
    return $dest;
  }

  /**
   * Uses bitwise operators instead of table-lookups to turn 6-bit integers
   * into 8-bit integers.
   *
   * Base64 character set:
   * [A-Z]      [a-z]      [0-9]      +     /
   * 0x41-0x5a, 0x61-0x7a, 0x30-0x39, 0x2b, 0x2f
   */
  protected static function decode6Bits(int $src): int {
    $ret = -1;
    // if ($src > 0x40 && $src < 0x5b) $ret += $src - 0x41 + 1; // -64
    $ret += (((0x40 - $src) & ($src - 0x5b)) >> 8) & ($src - 64);
    // if ($src > 0x60 && $src < 0x7b) $ret += $src - 0x61 + 26 + 1; // -70
    $ret += (((0x60 - $src) & ($src - 0x7b)) >> 8) & ($src - 70);
    // if ($src > 0x2f && $src < 0x3a) $ret += $src - 0x30 + 52 + 1; // 5
    $ret += (((0x2f - $src) & ($src - 0x3a)) >> 8) & ($src + 5);
    // if ($src == 0x2b) $ret += 62 + 1;
    $ret += (((0x2a - $src) & ($src - 0x2c)) >> 8) & 63;
    // if ($src == 0x2f) ret += 63 + 1;
    $ret += (((0x2e - $src) & ($src - 0x30)) >> 8) & 64;
    return $ret;
  }

  /**
   * Uses bitwise operators instead of table-lookups to turn 8-bit integers
   * into 6-bit integers.
   */
  protected static function encode6Bits(int $src): string {
    $diff = 0x41;
    // if ($src > 25) $diff += 0x61 - 0x41 - 26; // 6
    $diff += ((25 - $src) >> 8) & 6;
    // if ($src > 51) $diff += 0x30 - 0x61 - 26; // -75
    $diff -= ((51 - $src) >> 8) & 75;
    // if ($src > 61) $diff += 0x2b - 0x30 - 10; // -15
    $diff -= ((61 - $src) >> 8) & 15;
    // if ($src > 62) $diff += 0x2f - 0x2b - 1; // 3
    $diff += ((62 - $src) >> 8) & 3;
    return \pack('C', $src + $diff);
  }
}
