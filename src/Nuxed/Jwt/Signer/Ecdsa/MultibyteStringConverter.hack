namespace Nuxed\Jwt\Signer\Ecdsa;

use namespace HH\Lib\Str;
use namespace Nuxed\Jwt\Exception;
use const STR_PAD_LEFT;

/**
 * ECDSA signature converter using ext-mbstring
 *
 * @internal
 */
final class MultibyteStringConverter implements ISignatureConverter {
  const string ASN1_SEQUENCE = '30';
  const string ASN1_INTEGER = '02';
  const int ASN1_MAX_SINGLE_BYTE = 128;
  const string ASN1_LENGTH_2BYTES = '81';
  const string ASN1_BIG_INTEGER_LIMIT = '7f';
  const string ASN1_NEGATIVE_INTEGER = '00';
  const int BYTE_SIZE = 2;

  public function toAsn1(string $signature, int $length): string {
    $signature = \bin2hex($signature);
    if (self::octetLength($signature) !== $length) {
      throw new Exception\InvalidArgumentException('Invalid signature length.');
    }
    $pointR = self::preparePositiveInteger(
      \mb_substr($signature, 0, $length, '8bit'),
    );
    $pointS = self::preparePositiveInteger(
      \mb_substr($signature, $length, null, '8bit'),
    );
    $lengthR = self::octetLength($pointR);
    $lengthS = self::octetLength($pointS);
    $totalLength = $lengthR + $lengthS + self::BYTE_SIZE + self::BYTE_SIZE;
    $lengthPrefix = $totalLength > self::ASN1_MAX_SINGLE_BYTE
      ? self::ASN1_LENGTH_2BYTES
      : '';
    $asn1 = \hex2bin(
      self::ASN1_SEQUENCE.
      $lengthPrefix.
      \dechex($totalLength).
      self::ASN1_INTEGER.
      \dechex($lengthR).
      $pointR.
      self::ASN1_INTEGER.
      \dechex($lengthS).
      $pointS,
    );

    return $asn1 as string;
  }

  private static function octetLength(string $data): int {
    return (int)(\mb_strlen($data, '8bit') / self::BYTE_SIZE);
  }

  private static function preparePositiveInteger(string $data): string {
    if (
      \mb_substr($data, 0, self::BYTE_SIZE, '8bit') >
        self::ASN1_BIG_INTEGER_LIMIT
    ) {
      return self::ASN1_NEGATIVE_INTEGER.$data;
    }
    while (
      \mb_substr($data, 0, self::BYTE_SIZE, '8bit') ===
        self::ASN1_NEGATIVE_INTEGER &&
      \mb_substr($data, 2, self::BYTE_SIZE, '8bit') <=
        self::ASN1_BIG_INTEGER_LIMIT
    ) {
      $data = \mb_substr($data, 2, null, '8bit');
    }
    return $data;
  }

  public function fromAsn1(string $signature, int $length): string {
    $message = \bin2hex($signature);
    $position = 0;
    list($asn1, $position) = self::readAsn1Content(
      $message,
      $position,
      self::BYTE_SIZE,
    );
    if ($asn1 !== self::ASN1_SEQUENCE) {
      throw new Exception\InvalidArgumentException(
        'Invalid data. Should start with a sequence.',
      );
    }

    list($asn1, $position) = self::readAsn1Content(
      $message,
      $position,
      self::BYTE_SIZE,
    );
    if ($asn1 === self::ASN1_LENGTH_2BYTES) {
      $position += self::BYTE_SIZE;
    }

    list($asn1Integer, $position) = self::readAsn1Integer($message, $position);
    $pointR = self::retrievePositiveInteger($asn1Integer);
    list($asn1Integer, $position) = self::readAsn1Integer($message, $position);
    $pointS = self::retrievePositiveInteger($asn1Integer);
    $points = \hex2bin(Str\format(
      '%s%s',
      Str\pad_left($pointR, $length, '0'),
      Str\pad_left($pointS, $length, '0'),
    ));

    return $points as string;
  }

  private static function readAsn1Content(
    string $message,
    int $position,
    int $length,
  ): (string, int) {
    $content = \mb_substr($message, $position, $length, '8bit');
    $position += $length;
    return tuple($content, $position);
  }

  private static function readAsn1Integer(
    string $message,
    int $position,
  ): (string, int) {
    list($asn1, $position) = self::readAsn1Content(
      $message,
      $position,
      self::BYTE_SIZE,
    );

    if ($asn1 !== self::ASN1_INTEGER) {
      throw new Exception\InvalidArgumentException(
        'Invalid data. Should contain an integer.',
      );
    }

    list($asn1, $position) = self::readAsn1Content(
      $message,
      $position,
      self::BYTE_SIZE,
    );

    $length = (int)\hexdec($asn1);

    return self::readAsn1Content(
      $message,
      $position,
      $length * self::BYTE_SIZE,
    );
  }

  private static function retrievePositiveInteger(string $data): string {
    while (
      \mb_substr($data, 0, self::BYTE_SIZE, '8bit') ===
        self::ASN1_NEGATIVE_INTEGER &&
      \mb_substr($data, 2, self::BYTE_SIZE, '8bit') >
        self::ASN1_BIG_INTEGER_LIMIT
    ) {
      $data = \mb_substr($data, 2, null, '8bit');
    }
    return $data;
  }
}
