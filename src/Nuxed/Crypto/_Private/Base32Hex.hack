namespace Nuxed\Crypto\_Private;

final abstract class Base32Hex extends Base32 {
  /**
   * Uses bitwise operators instead of table-lookups to turn 5-bit integers
   * into 8-bit integers.
   */
  <<__Override>>
  protected static function decode5Bits(int $src): int {
    $ret = -1;
    // if ($src > 0x30 && $src < 0x3a) ret += $src - 0x2e + 1; // -47
    $ret += (((0x2f - $src) & ($src - 0x3a)) >> 8) & ($src - 47);
    // if ($src > 0x60 && $src < 0x77) ret += $src - 0x61 + 10 + 1; // -86
    $ret += (((0x60 - $src) & ($src - 0x77)) >> 8) & ($src - 86);
    return $ret;
  }

  /**
   * Uses bitwise operators instead of table-lookups to turn 5-bit integers
   * into 8-bit integers.
   */
  <<__Override>>
  protected static function decode5BitsUpper(int $src): int {
    $ret = -1;
    // if ($src > 0x30 && $src < 0x3a) ret += $src - 0x2e + 1; // -47
    $ret += (((0x2f - $src) & ($src - 0x3a)) >> 8) & ($src - 47);
    // if ($src > 0x40 && $src < 0x57) ret += $src - 0x41 + 10 + 1; // -54
    $ret += (((0x40 - $src) & ($src - 0x57)) >> 8) & ($src - 54);
    return $ret;
  }

  /**
   * Uses bitwise operators instead of table-lookups to turn 8-bit integers
   * into 5-bit integers.
   */
  <<__Override>>
  protected static function encode5Bits(int $src): string {
    $src += 0x30;
    // if ($src > 0x39) $src += 0x61 - 0x3a; // 39
    $src += ((0x39 - $src) >> 8) & 39;
    return \pack('C', $src);
  }

  /**
   * Uses bitwise operators instead of table-lookups to turn 8-bit integers
   * into 5-bit integers.
   *
   * Uppercase variant.
   */
  <<__Override>>
  protected static function encode5BitsUpper(int $src): string {
    $src += 0x30;
    // if ($src > 0x39) $src += 0x41 - 0x3a; // 7
    $src += ((0x39 - $src) >> 8) & 7;
    return \pack('C', $src);
  }
}
