<?hh // strict

namespace Nuxed\Contract\Http\Message;

/**
 * Representation of an incoming, server-side HTTP request.
 *
 * Per the HTTP specification, this interface includes properties for
 * each of the following:
 *
 * - Protocol version
 * - HTTP method
 * - URI
 * - Headers
 * - Message body
 *
 * Additionally, it encapsulates all data as it has arrived to the
 * application from the CGI and/or Hack environment, including:
 *
 * - The values represented in $_SERVER.
 * - Any cookies provided (generally via $_COOKIE)
 * - Query string arguments (generally via $_GET, or as parsed via parse_str())
 * - Upload files, if any (as represented by $_FILES)
 * - Deserialized body parameters (generally from $_POST)
 *
 * $_SERVER values MUST be treated as immutable, as they represent application
 * state at the time of request; as such, no methods are provided to allow
 * modification of those values. The other values provide such methods, as they
 * can be restored from $_SERVER or the request body, and may need treatment
 * during the application (e.g., body parameters may be deserialized based on
 * content type).
 *
 * Additionally, this interface recognizes the utility of introspecting a
 * request to derive and match additional parameters (e.g., via URI path
 * matching, decrypting cookie values, deserializing non-form-encoded body
 * content, matching authorization headers to users, etc). These parameters
 * are stored in an "attributes" property.
 *
 * Requests are considered immutable; all methods that might change state MUST
 * be implemented such that they retain the internal state of the current
 * message and return an instance that contains the changed state.
 */
interface ServerRequestInterface extends RequestInterface {
  /**
   * Retrieve server parameters.
   *
   * Retrieves data related to the incoming request environment,
   * typically derived from Hack's $_SERVER superglobal. The data IS NOT
   * REQUIRED to originate from $_SERVER.
   */
  public function getServerParams(): KeyedContainer<string, mixed>;

  /**
   * Retrieve cookies.
   *
   * Retrieves cookies sent by the client to the server.
   *
   * The data MUST be compatible with the structure of the $_COOKIE
   * superglobal.
   */
  public function getCookieParams(): KeyedContainer<string, string>;

  /**
   * Return an instance with the specified cookies.
   *
   * The data IS NOT REQUIRED to come from the $_COOKIE superglobal, but MUST
   * be compatible with the structure of $_COOKIE. Typically, this data will
   * be injected at instantiation.
   *
   * This method MUST NOT update the related Cookie header of the request
   * instance, nor related values in the server params.
   *
   * This method MUST be implemented in such a way as to retain the
   * immutability of the message, and MUST return an instance that has the
   * updated cookie values.
   *
   * @param KeyedContainer<string, string> $cookies KeyedContainer of key/value pairs representing cookies.
   */
  public function withCookieParams(
    KeyedContainer<string, string> $cookies,
  ): this;

  /**
   * Retrieve query string arguments.
   *
   * Retrieves the deserialized query string arguments, if any.
   *
   * Note: the query params might not be in sync with the URI or server
   * params. If you need to ensure you are only getting the original
   * values, you may need to parse the query string from `getUri()->getQuery()`
   * or from the `QUERY_STRING` server param.
   */
  public function getQueryParams(): KeyedContainer<string, mixed>;

  /**
   * Return an instance with the specified query string arguments.
   *
   * These values SHOULD remain immutable over the course of the incoming
   * request. They MAY be injected during instantiation, such as from Hack's
   * $_GET superglobal, or MAY be derived from some other value such as the
   * URI. In cases where the arguments are parsed from the URI, the data
   * MUST be compatible with what Hack's parse_str() would return for
   * purposes of how duplicate query parameters are handled, and how nested
   * sets are handled.
   *
   * Setting query string arguments MUST NOT change the URI stored by the
   * request, nor the values in the server params.
   *
   * This method MUST be implemented in such a way as to retain the
   * immutability of the message, and MUST return an instance that has the
   * updated query string arguments.
   *
   * @param KeyedContainer<string, mixed> $query KeyedContainer of query string arguments, typically from
   *     $_GET.
   */
  public function withQueryParams(KeyedContainer<string, mixed> $query): this;

  /**
   * Retrieve normalized file upload data.
   *
   * If the uploaded files has not been previously set, returns
   * Null.
   *
   * These values of the UploadsFolder MAY be prepared from $_FILES or
   * the message body during instantiation, or MAY be injected via withUploadsFolder().
   *
   * @return KeyedContainer<string, UploadedFileInterface> A KeyedContainer of
   * UploadedFileInterface instances; an empty KeyedContainer MUST
   * be returned if no data is present.
   */
  public function getUploadedFiles(
  ): KeyedContainer<string, UploadedFileInterface>;

  /**
   * Create a new instance with the specified uploaded files.
   *
   * This method MUST be implemented in such a way as to retain the
   * immutability of the message, and MUST return an instance that has the
   * updated body parameters.
   *
   * @param UploadsFolderInterface An UploadsFolderInterface instances;
   */
  public function withUploadedFiles(
    KeyedContainer<string, UploadedFileInterface> $uploadedFiles,
  ): this;

  /**
   * Retrieve any parameters provided in the request body.
   *
   * If the request Content-Type is either application/x-www-form-urlencoded
   * or multipart/form-data, and the request method is POST, this method MUST
   * return the contents of $_POST.
   *
   * Otherwise, this method may return any results of deserializing
   * the request body content; as parsing returns structured content, the
   * potential types MUST be a KeyedContainer only. A null value indicates
   * the absence of body content.
   *
   * @return KeyedContainer<string, mixed> The deserialized body parametersm if any.
   */
  public function getParsedBody(): ?KeyedContainer<string, mixed>;

  /**
   * Return an instance with the specified body parameters.
   *
   * These MAY be injected during instantiation.
   *
   * If the request Content-Type is either application/x-www-form-urlencoded
   * or multipart/form-data, and the request method is POST, use this method
   * ONLY to inject the contents of $_POST.
   *
   * The data IS NOT REQUIRED to come from $_POST, but MUST be the results of
   * deserializing the request body content. Deserialization/parsing returns
   * structured data, and, as such, this method ONLY accepts Maps,
   * or a null value if nothing was available to parse.
   *
   * As an example, if content negotiation determines that the request data
   * is a JSON payload, this method could be used to create a request
   * instance with the deserialized parameters.
   *
   * This method MUST be implemented in such a way as to retain the
   * immutability of the message, and MUST return an instance that has the
   * updated body parameters.
   *
   * @param KeyedContainer<string, mixed> $data The deserialized body data.

   * @throws \InvalidArgumentException if an unsupported argument type is
   *     provided.
   */
  public function withParsedBody(?KeyedContainer<string, mixed> $data): this;

  /**
   * Retrieve attributes derived from the request.
   *
   * The request "attributes" may be used to allow injection of any
   * parameters derived from the request: e.g., the results of path
   * match operations; the results of decrypting cookies; the results of
   * deserializing non-form-encoded message bodies; etc. Attributes
   * will be application and request specific, and CAN be mutable.
   *
   * @return KeyedContainer<string, mixed> Attributes derived from the request.
   */
  public function getAttributes(): KeyedContainer<string, mixed>;

  /**
   * Retrieve a single derived request attribute.
   *
   * Retrieves a single derived request attribute as described in
   * getAttributes(). If the attribute has not been previously set, returns
   * the default value as provided.
   *
   * This method obviates the need for a hasAttribute() method, as it allows
   * specifying a default value to return if the attribute is not found.
   *
   * @see getAttributes()
   *
   * @param string $name The attribute name.
   * @param mixed $default Default value to return if the attribute does not exist.
   */
  public function getAttribute(string $name, mixed $default = null): mixed;

  /**
   * Return an instance with the specified derived request attribute.
   *
   * This method allows setting a single derived request attribute as
   * described in getAttributes().
   *
   * This method MUST be implemented in such a way as to retain the
   * immutability of the message, and MUST return an instance that has the
   * updated attribute.
   *
   * @see getAttributes()
   *
   * @param string $name The attribute name.
   * @param mixed $value The value of the attribute.
   */
  public function withAttribute(string $name, mixed $value): this;

  /**
   * Return an instance that removes the specified derived request attribute.
   *
   * This method allows removing a single derived request attribute as
   * described in getAttributes().
   *
   * This method MUST be implemented in such a way as to retain the
   * immutability of the message, and MUST return an instance that removes
   * the attribute.
   *
   * @see getAttributes()
   *
   * @param string $name The attribute name.
   */
  public function withoutAttribute(string $name): this;
}
