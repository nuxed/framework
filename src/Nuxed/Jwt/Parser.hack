namespace Nuxed\Jwt;

use namespace HH\Lib\C;
use namespace HH\Lib\Str;
use namespace Nuxed\Util\Json;
use namespace Nuxed\Util\Base64;
use namespace Facebook\TypeSpec;

final class Parser implements IParser {
  const type Headers = KeyedContainer<string, dynamic>;
  const int BASE64_PADDING_LENGTH = 4;

  /**
   * {@inheritdoc}
   */
  public function parse(string $jwt): IToken {
    list($encodedHeaders, $encodedClaims, $encodedSignature) = $this->split(
      $jwt,
    );
    $headers = $this->parseHeaders($encodedHeaders);

    return new Token(
      $headers,
      $this->parseClaims($encodedClaims),
      $this->parseSignature($headers, $encodedSignature),
    );
  }

  private function split(string $jwt): (string, string, string) {
    $parts = Str\split($jwt, '.');

    if (C\count($parts) !== 3) {
      throw new Exception\InvalidArgumentException('Invalid JWT');
    }

    return tuple($parts[0], $parts[1], $parts[2]);
  }

  /**
   * Parses the claim set from a string
   */
  private function parseClaims(string $data): Token\Claims {
    $claims = Base64\url_decode($data)
      |> Json\structure($$, \type_structure(Token\Claims::class, 'Type'))
      |> Shapes::toDict($$)
      |> TypeSpec\dict(TypeSpec\string(), TypeSpec\mixed())
        ->coerceType($$);

    return new Token\Claims($claims, $data);
  }

  private function parseHeaders(string $encodedHeaders): Token\Headers {
    $headers = Json\structure(
      Base64\url_decode($encodedHeaders),
      \type_structure($this, 'Headers'),
    );

    if (C\contains_key($headers, 'enc')) {
      throw new Exception\InvalidArgumentException(
        'Encryption is not supported yet',
      );
    }

    if (!C\contains_key($headers, 'typ')) {
      throw new Exception\InvalidArgumentException(
        'The header "typ" must be present',
      );
    }

    return new Token\Headers($headers, $encodedHeaders);
  }

  /**
   * Returns the signature from given data
   */
  private function parseSignature(
    Token\Headers $header,
    string $data,
  ): Token\Signature {
    if (
      $data === '' ||
      !$header->contains('alg') ||
      $header->get('alg') === 'none'
    ) {
      return new Token\Signature('', '');
    }

    $hash = Base64\url_decode($data);
    return new Token\Signature($hash, $data);
  }
}
