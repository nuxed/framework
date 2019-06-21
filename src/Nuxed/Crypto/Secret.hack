namespace Nuxed\Crypto;

use namespace Nuxed\Crypto;
use namespace Nuxed\Crypto\Str;
use namespace Nuxed\Crypto\Exception;
use namespace HH\Lib\Experimental\Filesystem;

/**
 * Base class for all cryptography secrets
 */
<<
  __Sealed(Symmetric\Secret::class, Asymmetric\Secret::class),
  __ConsistentConstruct
>>
abstract class Secret {
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
    $hidden = new HiddenString(
      Hex\encode(
        _Private\HALITE_VERSION_KEYS.
        $data.
        \sodium_crypto_generichash(
          _Private\HALITE_VERSION_KEYS.$data,
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
   * Save a secret to a file.
   */
  public async function save(string $file): Awaitable<void> {
    await using ($file = Filesystem\open_write_only($file)) {
      await $file->writeAsync($this->export()->toString());
    }
  }

  /**
   * Read a secret from a file, verify its checksum.
   */
  public static async function load(string $file): Awaitable<this> {
    await using ($file = Filesystem\open_read_only($file)) {
      $content = await $file->readAsync();
      $data = Hex\decode($content);
      \sodium_memzero(&$content);
      return new static(new HiddenString(static::getKeyDataFromString($data)));
    }
  }

  /**
   * Take a stored key string, get the derived key (after verifying the
   * checksum)
   */
  protected static function getKeyDataFromString(string $data): string {
    $versionTag = Binary\slice($data, 0, _Private\VERSION_TAG_LEN);
    $keyData = Binary\slice(
      $data,
      _Private\VERSION_TAG_LEN,
      -\SODIUM_CRYPTO_GENERICHASH_BYTES_MAX,
    );
    $checksum = Binary\slice(
      $data,
      -\SODIUM_CRYPTO_GENERICHASH_BYTES_MAX,
      \SODIUM_CRYPTO_GENERICHASH_BYTES_MAX,
    );
    $calc = \sodium_crypto_generichash(
      $versionTag.$keyData,
      '',
      \SODIUM_CRYPTO_GENERICHASH_BYTES_MAX,
    );
    if (!\hash_equals($calc, $checksum)) {
      throw new Exception\InvalidKeyException('Checksum validation fail');
    }
    \sodium_memzero(&$data);
    \sodium_memzero(&$versionTag);
    \sodium_memzero(&$calc);
    \sodium_memzero(&$checksum);
    return $keyData;
  }

  abstract public static function generate(): this;
}
