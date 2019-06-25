namespace Nuxed\Crypto\_Private;

use namespace HH\Lib\Str;
use namespace Nuxed\Crypto\{Binary, Exception};

<<__Sealed(Base32Hex::class)>>
abstract class Base32 {
  /**
   * Uses bitwise operators instead of table-lookups to turn 5-bit integers
   * into 8-bit integers.
   */
  protected static function decode5Bits(int $src): int {
    $ret = -1;
    // if ($src > 96 && $src < 123) $ret += $src - 97 + 1; // -64
    $ret += (((0x60 - $src) & ($src - 0x7b)) >> 8) & ($src - 96);
    // if ($src > 0x31 && $src < 0x38) $ret += $src - 24 + 1; // -23
    $ret += (((0x31 - $src) & ($src - 0x38)) >> 8) & ($src - 23);
    return $ret;
  }

  /**
   * Uses bitwise operators instead of table-lookups to turn 5-bit integers
   * into 8-bit integers.
   *
   * Uppercase variant.
   */
  protected static function decode5BitsUpper(int $src): int {
    $ret = -1;
    // if ($src > 64 && $src < 91) $ret += $src - 65 + 1; // -64
    $ret += (((0x40 - $src) & ($src - 0x5b)) >> 8) & ($src - 64);
    // if ($src > 0x31 && $src < 0x38) $ret += $src - 24 + 1; // -23
    $ret += (((0x31 - $src) & ($src - 0x38)) >> 8) & ($src - 23);
    return $ret;
  }

  /**
   * Uses bitwise operators instead of table-lookups to turn 8-bit integers
   * into 5-bit integers.
   */
  protected static function encode5Bits(int $src): string {
    $diff = 0x61;
    // if ($src > 25) $ret -= 72;
    $diff -= ((25 - $src) >> 8) & 73;
    return \pack('C', $src + $diff);
  }

  /**
   * Uses bitwise operators instead of table-lookups to turn 8-bit integers
   * into 5-bit integers.
   *
   * Uppercase variant.
   */
  protected static function encode5BitsUpper(int $src): string {
    $diff = 0x41;
    // if ($src > 25) $ret -= 40;
    $diff -= ((25 - $src) >> 8) & 41;
    return \pack('C', $src + $diff);
  }

  /**
   * Base32 decoding
   */
  public static function decode(
    string $src,
    bool $upper = false,
    bool $strictPadding = false,
  ): string {
    // We do this to reduce code duplication:
    $decode = (int $i): int ==>
      $upper ? static::decode5BitsUpper($i) : static::decode5Bits($i);

    // Remove padding
    $srcLen = Binary\length($src);
    if ($srcLen === 0) {
      return '';
    }
    if ($strictPadding) {
      if (($srcLen & 7) === 0) {
        for ($j = 0; $j < 7; ++$j) {
          if ($src[$srcLen - 1] === '=') {
            $srcLen--;
          } else {
            break;
          }
        }
      }
      if (($srcLen & 7) === 1) {
        throw new Exception\RangeException('Incorrect padding');
      }
    } else {
      $src = Str\trim_right($src, '=');
      $srcLen = Binary\length($src);
    }
    $err = 0;
    $dest = '';
    // Main loop (no padding):
    for ($i = 0; $i + 8 <= $srcLen; $i += 8) {
      /** @var array<int, int> $chunk */
      $chunk = \unpack('C*', Binary\slice($src, $i, 8));
      $c0 = $decode($chunk[1]);
      $c1 = $decode($chunk[2]);
      $c2 = $decode($chunk[3]);
      $c3 = $decode($chunk[4]);
      $c4 = $decode($chunk[5]);
      $c5 = $decode($chunk[6]);
      $c6 = $decode($chunk[7]);
      $c7 = $decode($chunk[8]);
      $dest .= \pack(
        'CCCCC',
        (($c0 << 3) | ($c1 >> 2)) & 0xff,
        (($c1 << 6) | ($c2 << 1) | ($c3 >> 4)) & 0xff,
        (($c3 << 4) | ($c4 >> 1)) & 0xff,
        (($c4 << 7) | ($c5 << 2) | ($c6 >> 3)) & 0xff,
        (($c6 << 5) | ($c7)) & 0xff,
      );
      $err |= ($c0 | $c1 | $c2 | $c3 | $c4 | $c5 | $c6 | $c7) >> 8;
    }
    // The last chunk, which may have padding:
    if ($i < $srcLen) {
      /** @var array<int, int> $chunk */
      $chunk = \unpack('C*', Binary\slice($src, $i, $srcLen - $i));
      $c0 = $decode($chunk[1]);
      if ($i + 6 < $srcLen) {
        $c1 = $decode($chunk[2]);
        $c2 = $decode($chunk[3]);
        $c3 = $decode($chunk[4]);
        $c4 = $decode($chunk[5]);
        $c5 = $decode($chunk[6]);
        $c6 = $decode($chunk[7]);
        $dest .= \pack(
          'CCCC',
          (($c0 << 3) | ($c1 >> 2)) & 0xff,
          (($c1 << 6) | ($c2 << 1) | ($c3 >> 4)) & 0xff,
          (($c3 << 4) | ($c4 >> 1)) & 0xff,
          (($c4 << 7) | ($c5 << 2) | ($c6 >> 3)) & 0xff,
        );
        $err |= ($c0 | $c1 | $c2 | $c3 | $c4 | $c5 | $c6) >> 8;
      } else if ($i + 5 < $srcLen) {
        $c1 = $decode($chunk[2]);
        $c2 = $decode($chunk[3]);
        $c3 = $decode($chunk[4]);
        $c4 = $decode($chunk[5]);
        $c5 = $decode($chunk[6]);
        $dest .= \pack(
          'CCCC',
          (($c0 << 3) | ($c1 >> 2)) & 0xff,
          (($c1 << 6) | ($c2 << 1) | ($c3 >> 4)) & 0xff,
          (($c3 << 4) | ($c4 >> 1)) & 0xff,
          (($c4 << 7) | ($c5 << 2)) & 0xff,
        );
        $err |= ($c0 | $c1 | $c2 | $c3 | $c4 | $c5) >> 8;
      } else if ($i + 4 < $srcLen) {
        $c1 = $decode($chunk[2]);
        $c2 = $decode($chunk[3]);
        $c3 = $decode($chunk[4]);
        $c4 = $decode($chunk[5]);
        $dest .= \pack(
          'CCC',
          (($c0 << 3) | ($c1 >> 2)) & 0xff,
          (($c1 << 6) | ($c2 << 1) | ($c3 >> 4)) & 0xff,
          (($c3 << 4) | ($c4 >> 1)) & 0xff,
        );
        $err |= ($c0 | $c1 | $c2 | $c3 | $c4) >> 8;
      } else if ($i + 3 < $srcLen) {
        $c1 = $decode($chunk[2]);
        $c2 = $decode($chunk[3]);
        $c3 = $decode($chunk[4]);
        $dest .= \pack(
          'CC',
          (($c0 << 3) | ($c1 >> 2)) & 0xff,
          (($c1 << 6) | ($c2 << 1) | ($c3 >> 4)) & 0xff,
        );
        $err |= ($c0 | $c1 | $c2 | $c3) >> 8;
      } else if ($i + 2 < $srcLen) {
        $c1 = $decode($chunk[2]);
        $c2 = $decode($chunk[3]);
        $dest .= \pack(
          'CC',
          (($c0 << 3) | ($c1 >> 2)) & 0xff,
          (($c1 << 6) | ($c2 << 1)) & 0xff,
        );
        $err |= ($c0 | $c1 | $c2) >> 8;
      } else if ($i + 1 < $srcLen) {
        $c1 = $decode($chunk[2]);
        $dest .= \pack('C', (($c0 << 3) | ($c1 >> 2)) & 0xff);
        $err |= ($c0 | $c1) >> 8;
      } else {
        $dest .= \pack('C', (($c0 << 3)) & 0xff);
        $err |= ($c0) >> 8;
      }
    }
    $check = ($err === 0);
    if (!$check) {
      throw new Exception\RangeException(
        'Expected characters in the correct base32 alphabet',
      );
    }
    return $dest;
  }

  /**
   * Base32 Encoding
   */
  public static function encode(
    string $src,
    bool $upper = false,
    bool $pad = true,
  ): string {
    // We do this to reduce code duplication:
    $encode = (int $i): string ==>
      $upper ? static::encode5BitsUpper($i) : static::encode5Bits($i);

    $dest = '';
    $srcLen = Binary\length($src);
    // Main loop (no padding):
    for ($i = 0; $i + 5 <= $srcLen; $i += 5) {
      /** @var array<int, int> $chunk */
      $chunk = \unpack('C*', Binary\slice($src, $i, 5));
      $b0 = $chunk[1];
      $b1 = $chunk[2];
      $b2 = $chunk[3];
      $b3 = $chunk[4];
      $b4 = $chunk[5];
      $dest .= $encode(($b0 >> 3) & 31).
        $encode((($b0 << 2) | ($b1 >> 6)) & 31).
        $encode((($b1 >> 1)) & 31).
        $encode((($b1 << 4) | ($b2 >> 4)) & 31).
        $encode((($b2 << 1) | ($b3 >> 7)) & 31).
        $encode((($b3 >> 2)) & 31).
        $encode((($b3 << 3) | ($b4 >> 5)) & 31).
        $encode($b4 & 31);
    }
    // The last chunk, which may have padding:
    if ($i < $srcLen) {
      /** @var array<int, int> $chunk */
      $chunk = \unpack('C*', Binary\slice($src, $i, $srcLen - $i));
      $b0 = $chunk[1];
      if ($i + 3 < $srcLen) {
        $b1 = $chunk[2];
        $b2 = $chunk[3];
        $b3 = $chunk[4];
        $dest .= $encode(($b0 >> 3) & 31).
          $encode((($b0 << 2) | ($b1 >> 6)) & 31).
          $encode((($b1 >> 1)) & 31).
          $encode((($b1 << 4) | ($b2 >> 4)) & 31).
          $encode((($b2 << 1) | ($b3 >> 7)) & 31).
          $encode((($b3 >> 2)) & 31).
          $encode((($b3 << 3)) & 31);
        if ($pad) {
          $dest .= '=';
        }
      } else if ($i + 2 < $srcLen) {
        $b1 = $chunk[2];
        $b2 = $chunk[3];
        $dest .= $encode(($b0 >> 3) & 31).
          $encode((($b0 << 2) | ($b1 >> 6)) & 31).
          $encode((($b1 >> 1)) & 31).
          $encode((($b1 << 4) | ($b2 >> 4)) & 31).
          $encode((($b2 << 1)) & 31);
        if ($pad) {
          $dest .= '===';
        }
      } else if ($i + 1 < $srcLen) {
        $b1 = $chunk[2];
        $dest .= $encode(($b0 >> 3) & 31).
          $encode((($b0 << 2) | ($b1 >> 6)) & 31).
          $encode((($b1 >> 1)) & 31).
          $encode((($b1 << 4)) & 31);
        if ($pad) {
          $dest .= '====';
        }
      } else {
        $dest .= $encode(($b0 >> 3) & 31).$encode(($b0 << 2) & 31);
        if ($pad) {
          $dest .= '======';
        }
      }
    }
    return $dest;
  }
}
