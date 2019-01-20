namespace Nuxed\Contract\Http\Message;

/**
 * Representation of an outgoing, server-side response.
 *
 * Per the HTTP specification, this interface includes properties for
 * each of the following:
 *
 * - Protocol version
 * - Status code and reason phrase
 * - Headers
 * - Message body
 *
 * Responses are considered immutable; all methods that might change state MUST
 * be implemented such that they retain the internal state of the current
 * message and return an instance that contains the changed state.
 */
interface ResponseInterface extends MessageInterface {
  /**
   * Return an instance with the specified status code and, optionally, reason phrase.
   *
   * If no reason phrase is specified, implementations MAY choose to default
   * to the RFC 7231 or IANA recommended reason phrase for the response's
   * status code.
   *
   * This method MUST be implemented in such a way as to retain the
   * immutability of the message, and MUST return an instance that has the
   * updated status and reason phrase.
   *
   * @link http://tools.ietf.org/html/rfc7231#section-6
   * @link http://www.iana.org/assignments/http-status-codes/http-status-codes.xhtml
   * @param int $code The 3-digit integer result code to set.
   * @param string $reasonPhrase The reason phrase to use with the
   *     provided status code; if none is provided, implementations MAY
   *     use the defaults as suggested in the HTTP specification.
   *
   * @throws \InvalidArgumentException For invalid status code arguments.
   */
  public function withStatus(int $code, string $reasonPhrase = ''): this;

  /**
   * Gets the response status code.
   *
   * The status code is a 3-digit integer result code of the server's attempt
   * to understand and satisfy the request.
   */
  public function getStatusCode(): int;

  /**
   * Gets the response reason phrase associated with the status code.
   *
   * Because a reason phrase is not a required element in a response
   * status line, the reason phrase value MAY be null. Implementations MAY
   * choose to return the default RFC 7231 recommended reason phrase (or those
   * listed in the IANA HTTP Status Code Registry) for the response's
   * status code.
   *
   * @link http://tools.ietf.org/html/rfc7231#section-6
   * @link http://www.iana.org/assignments/http-status-codes/http-status-codes.xhtml
   * @return string Reason phrase; must return an empty string if none present.
   */
  public function getReasonPhrase(): string;

  /**
   * Retrieve all cookies from the response.
   *
   * The keys represent the cookie name as it will be sent over the wire, and
   * each value is a CookieInterface implementation associated with the cookie.
   *
   *      // emit cookies iteratively:
   *      foreach ($response->getCookies() as $name => $cookie) {
   *          setcookie(
   *              $name,
   *              $cookie->getValue(),
   *              $cookie->getExpires() ?? 0,
   *              $cookie->getPath() ?? '/',
   *              $cookie->getDomain() ?? '',
   *              $cookie->isSecure(),
   *              $cookie->isHttpOnly()
   *          )
   *     }
   *
   * cookies names are case-sensitive, getCookies() MUST preserve the
   * exact case in which cookies were originally specified.
   *
   * @return KeyedContainer<string, CookiesInterface> response cookies.
   */
  public function getCookies(): KeyedContainer<string, CookieInterface>;

  /**
   * Retrieve a single request cookie.
   *
   * Retrieves a single cookie as described in
   * getCookiess(). If the cookie has not been previously set, returns
   * null.
   *
   * @see getCookies()
   */
  public function getCookie(string $name): ?CookieInterface;

  /**
   * Create a new instance with the specified cookie.
   *
   * This method MUST be implemented in such a way as to retain the
   * immutability of the message, and MUST return an instance that has the
   * new cookie added to the cookies map.
   */
  public function withCookie(string $name, CookieInterface $cookie): this;

  /**
   * Return an instance that removes the specified derived response cookie.
   *
   * This method allows removing a single derived response cookie as
   * described in getCookie().
   *
   * This method MUST be implemented in such a way as to retain the
   * immutability of the message, and MUST return an instance that removes
   * the cookie.
   *
   * @see getCookies()
   *
   * @param string $name The cookie name.
   */
  public function withoutCookie(string $name): this;
}
