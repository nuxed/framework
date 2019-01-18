<?hh // strict

namespace Nuxed\Http\Message;

use namespace HH\Lib\C;
use type Nuxed\Contract\Http\Message\ServerRequestInterface;
use type Nuxed\Contract\Http\Message\StreamInterface;
use type Nuxed\Contract\Http\Message\UriInterface;
use type Nuxed\Contract\Http\Message\UploadedFileInterface;

class ServerRequest extends Request implements ServerRequestInterface {
  protected dict<string, mixed> $attributes = dict[];

  protected KeyedContainer<string, string> $cookieParams = dict[];

  protected ?KeyedContainer<string, mixed> $parsedBody = null;

  protected KeyedContainer<string, mixed> $queryParams = dict[];

  protected KeyedContainer<string, UploadedFileInterface> $uploadedFiles =
    dict[];

  public function __construct(
    string $method,
    UriInterface $uri,
    KeyedContainer<string, Container<string>> $headers = dict[],
    ?StreamInterface $body = null,
    string $version = '1.1',
    protected KeyedContainer<string, mixed> $serverParams = dict[],
  ) {
    $this->method = $method;
    $this->uri = $uri;
    parent::__construct($method, $uri, $headers, $body, $version);
  }

  /**
   * Create a new Http Server Request Message from the global variables.
   *
   * @see Factory->createServerRequestFromGlobals()
   */
  public static function capture(): ServerRequestInterface {
    return (new Factory())->createServerRequestFromGlobals();
  }

  public function getServerParams(): KeyedContainer<string, mixed> {
    return $this->serverParams;
  }

  public function getUploadedFiles(
  ): KeyedContainer<string, UploadedFileInterface> {
    return $this->uploadedFiles;
  }

  public function withUploadedFiles(
    KeyedContainer<string, UploadedFileInterface> $uploadedFiles,
  ): this {
    $new = clone $this;
    $new->uploadedFiles = $uploadedFiles;

    return $new;
  }

  public function getCookieParams(): KeyedContainer<string, string> {
    return $this->cookieParams;
  }

  public function withCookieParams(
    KeyedContainer<string, string> $cookies,
  ): this {
    $new = clone $this;
    $new->cookieParams = $cookies;

    return $new;
  }

  public function getQueryParams(): KeyedContainer<string, mixed> {
    return $this->queryParams;
  }

  public function withQueryParams(KeyedContainer<string, mixed> $query): this {
    $new = clone $this;
    $new->queryParams = $query;

    return $new;
  }

  public function getParsedBody(): ?KeyedContainer<string, mixed> {
    return $this->parsedBody;
  }

  public function withParsedBody(
    ?KeyedContainer<string, mixed> $parsedBody,
  ): this {
    $new = clone $this;
    $new->parsedBody = $parsedBody;

    return $new;
  }

  public function getAttributes(): KeyedContainer<string, mixed> {
    return $this->attributes;
  }

  public function getAttribute(
    string $attribute,
    mixed $default = null,
  ): mixed {
    if (C\contains_key($this->attributes, $attribute)) {
      return $this->attributes[$attribute];
    }
    return $default;
  }

  public function withAttribute(string $attribute, mixed $value): this {
    $new = clone $this;
    $new->attributes[$attribute] = $value;
    return $new;
  }

  public function withoutAttribute(string $attribute): this {
    if (!C\contains_key($this->attributes, $attribute)) {
      return $this;
    }

    $new = clone $this;
    unset($new->attributes[$attribute]);

    return $new;
  }
}
