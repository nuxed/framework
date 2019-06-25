namespace Nuxed\Crypto;

use namespace Nuxed\Crypto;
use namespace Nuxed\Crypto\{Exception, Str};
use namespace HH\Lib\SecureRandom;

/**
 * Base class for all cryptography secrets
 */
<<
  __Sealed(Symmetric\Secret::class, Asymmetric\Secret::class),
  __ConsistentConstruct
>>
abstract class Secret {
  private static int $prefixTagLength = 12;

  protected string $material;

  public function __construct(Crypto\HiddenString $material) {
    $this->material = Str\copy($material->toString());
  }

  /**
   * Hide this from var_dump(), etc.
   */
  public function __debugInfo(): dict<string, string> {
    return dict[
      'material' => '*',
      'attention' => 'If you need the value of a Crypto Secret, '.
        'invoke toString() instead of dumping it.',
    ];
  }

  /**
   * Don't allow this object to ever be cloned
   */
  public function __clone(): void {
    throw new Exception\UnclonableException('Crypto key cannot be cloned.');
  }

  /**
   * Don't allow this object to ever be serialized
   */
  public function __sleep(): void {
    throw new Exception\UnserializableException();
  }

  /**
   * Don't allow this object to ever be unserialized
   */
  public function __wakeup(): void {
    throw new Exception\UnserializableException();
  }

  /**
   * Get the actual secret material
   */
  public function toString(): string {
    return Str\copy($this->material);
  }

  /**
   * Export a cryptography secret to a string (with a checksum).
   */
  public function export(): HiddenString {
    $data = $this->toString();
    $prefix = SecureRandom\string(self::$prefixTagLength);
    $hidden = new HiddenString(
      Hex\encode(
        $prefix.
        $data.
        \sodium_crypto_generichash(
          $prefix.$data,
          '',
          \SODIUM_CRYPTO_GENERICHASH_BYTES_MAX,
        ),
      ),
    );
    // wipe secret material
    \sodium_memzero(&$data);
    return $hidden;
  }

  /**
   * Load a secret from a string.
   */
  public static function import(HiddenString $data): this {
    return new static(
      new HiddenString(
        static::getKeyDataFromString(Hex\decode($data->toString())),
      ),
    );
  }

  /**
   * Take a stored key string, get the derived key (after verifying the
   * checksum)
   */
  protected static function getKeyDataFromString(string $data): string {
    $prefixTag = Binary\slice($data, 0, self::$prefixTagLength);
    $keyData = Binary\slice(
      $data,
      self::$prefixTagLength,
      -\SODIUM_CRYPTO_GENERICHASH_BYTES_MAX,
    );
    $checksum = Binary\slice(
      $data,
      -\SODIUM_CRYPTO_GENERICHASH_BYTES_MAX,
      \SODIUM_CRYPTO_GENERICHASH_BYTES_MAX,
    );
    $calc = \sodium_crypto_generichash(
      $prefixTag.$keyData,
      '',
      \SODIUM_CRYPTO_GENERICHASH_BYTES_MAX,
    );
    if (!\hash_equals($calc, $checksum)) {
      throw new Exception\InvalidKeyException('Checksum validation fail');
    }
    \sodium_memzero(&$data);
    \sodium_memzero(&$prefixTag);
    \sodium_memzero(&$calc);
    \sodium_memzero(&$checksum);
    return $keyData;
  }
}
