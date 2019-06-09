namespace Nuxed\Jwt;

interface ISigner {
  /**
   * Returns the algorithm id
   */
  public function getAlgorithmId(): string;

  /**
   * Creates a hash for the given payload
   *
   * @throws Exception\InvalidArgumentException When given key is invalid.
   */
  public function sign(string $payload, Signer\Key $key): string;

  /**
   * Returns if the expected hash matches with the data and key
   *
   * @throws Exception\InvalidArgumentException When given key is invalid.
   */
  public function verify(
    string $expected,
    string $payload,
    Signer\Key $key,
  ): bool;
}
