namespace Nuxed\Jwt;

interface IParser {
  /**
   * Parses the JWT and returns a token
   *
   * @throws Exception\InvalidArgumentException
   */
  public function parse(string $jwt): IToken;
}
