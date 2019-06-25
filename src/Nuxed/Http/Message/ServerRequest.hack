namespace Nuxed\Http\Message;

use namespace HH\Lib\C;
use namespace Nuxed\Http\{Flash, Session};

class ServerRequest extends Request {
  protected dict<string, mixed> $attributes = dict[];

  protected KeyedContainer<string, string> $cookieParams = dict[];

  protected ?KeyedContainer<string, string> $parsedBody = null;

  protected KeyedContainer<string, string> $queryParams = dict[];

  protected KeyedContainer<string, UploadedFile> $uploadedFiles = dict[];

  protected ?Session\Session $session = null;
  protected ?Flash\FlashMessages $flash = null;

  public function __construct(
    string $method,
    Uri $uri,
    KeyedContainer<string, Container<string>> $headers = dict[],
    ?IStream $body = null,
    string $version = '1.1',
    protected KeyedContainer<string, mixed> $serverParams = dict[],
  ) {
    $this->method = $method;
    $this->uri = $uri;
    parent::__construct($method, $uri, $headers, $body, $version);
  }

  /**
   * Create a new Http Server Request Message from the global variables.
   */
  public static function capture(): ServerRequest {
    return _Private\create_server_request_from_globals();
  }

  public function getServerParams(): KeyedContainer<string, dynamic> {
    /* HH_IGNORE_ERROR[4110] */
    return $this->serverParams;
  }

  public function getUploadedFiles(): KeyedContainer<string, UploadedFile> {
    return $this->uploadedFiles;
  }

  public function withUploadedFiles(
    KeyedContainer<string, UploadedFile> $uploadedFiles,
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

  public function getQueryParams(): KeyedContainer<string, string> {
    return $this->queryParams;
  }

  public function withQueryParams(KeyedContainer<string, string> $query): this {
    $new = clone $this;
    $new->queryParams = $query;

    return $new;
  }

  public function getParsedBody(): ?KeyedContainer<string, string> {
    return $this->parsedBody;
  }

  public function withParsedBody(
    ?KeyedContainer<string, string> $parsedBody,
  ): this {
    $new = clone $this;
    $new->parsedBody = $parsedBody;

    return $new;
  }

  public function getAttributes(): KeyedContainer<string, dynamic> {
    /* HH_IGNORE_ERROR[4110] */
    return $this->attributes;
  }

  public function getAttribute(
    string $attribute,
    mixed $default = null,
  ): dynamic {
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

  /**
   * Return an instance with the specified session implementation.
   *
   * This method MUST be implemented in such a way as to retain the
   * immutability of the message, and MUST return an instance that has the
   * session instance.
   *
   * @param Session\Session $session session instance.
   */
  public function withSession(Session\Session $session): this {
    $clone = clone $this;
    $clone->session = $session;
    return $clone;
  }

  /**
   * Whether the request contains a Session object.
   *
   * This method does not give any information about the state of the session object,
   * like whether the session is started or not. It is just a way to check if this request
   * is associated with a session instance.
   *
   * @see setSession()
   * @see getSession()
   *
   * @return bool Returns true when the request contains a Session object, false otherwise
   */
  public function hasSession(): bool {
    return $this->session is nonnull;
  }

  /**
   * Gets the body of the message.
   *
   * @see hasSession()
   * @see setSession()
   *
   * @return Session\Session Returns the session object.
   */
  public function getSession(): Session\Session {
    return $this->session as nonnull;
  }

  /**
   * Return an instance with the specified flash implementation.
   *
   * This method MUST be implemented in such a way as to retain the
   * immutability of the message, and MUST return an instance that has the
   * flash instance.
   *
   * @param Flash\FlashMessages $flash flash instance.
   */
  public function withFlash(Flash\FlashMessages $flash): this {
    $clone = clone $this;
    $clone->flash = $flash;
    return $clone;
  }

  /**
   * Whether the request contains a flash object.
   *
   * @see setFlash()
   * @see getFlash()
   *
   * @return bool Returns true when the request contains a flash instance, false otherwise
   */
  public function hasFlash(): bool {
    return $this->flash is nonnull;
  }

  /**
   * Gets the body of the message.
   *
   * @see hasFlash()
   * @see setFlash()
   *
   * @return Flash\FlashMessages Returns the flash object.
   */
  public function getFlash(): Flash\FlashMessages {
    return $this->flash as nonnull;
  }
}
