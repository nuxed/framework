<?hh // strict

namespace Nuxed\Http\Emitter;

use namespace HH\Lib\C;
use namespace HH\Lib\Str;
use namespace Nuxed\Http\Emitter\Exception;
use type Nuxed\Contract\Http\Emitter\EmitterInterface;
use type Nuxed\Contract\Http\Message\CookieInterface;
use type Nuxed\Contract\Http\Message\ResponseInterface;
use function ob_get_level;
use function ob_get_length;
use function header;
use function headers_sent;
use function urlencode;

/**
 * Logic largely refactored from the Zend-HttpHandleRunner Zend\HttpHandlerRunner\Emitter\SapiEmitter class.
 *
 * @copyright Copyright (c) 2018 Zend Technologies USA Inc. (https://www.zend.com)
 * @license   https://github.com/zendframework/zend-httphandlerrunner/blob/master/LICENSE.md New BSD License
 */
class Emitter implements EmitterInterface {
  const SET_COOKIE_HEADER = 'Set-Cookie';

  public async function emit(ResponseInterface $response): Awaitable<bool> {
    $this->assertNoPreviousOutput();

    $response = $this->renderCookiesIntoHeader($response);

    $this->emitHeaders($response);
    $this->emitStatusLine($response);
    $this->emitBody($response);

    return true;
  }

  /**
   * Checks to see if content has previously been sent.
   *
   * If either headers have been sent or the output buffer contains content,
   * raises an exception.
   *
   * @throws EmitterException if headers have already been sent.
   * @throws EmitterException if output is present in the output buffer.
   */
  private function assertNoPreviousOutput(): void {
    if (headers_sent()) {
      throw Exception\EmitterException::forHeadersSent();
    }
    if (ob_get_level() > 0 && ob_get_length() > 0) {
      throw Exception\EmitterException::forOutputSent();
    }
  }

  /**
   * Emit the status line.
   *
   * Emits the status line using the protocol version and status code from
   * the response; if a reason phrase is available, it, too, is emitted.
   *
   * It is important to mention that this method should be called after
   * `emitHeaders()` in order to prevent PHP from changing the status code of
   * the emitted response.
   *
   * @see emitHeaders()
   */
  private function emitStatusLine(ResponseInterface $response): void {
    $reasonPhrase = $response->getReasonPhrase();
    $statusCode = $response->getStatusCode();
    header(
      Str\format(
        'HTTP/%s %d%s',
        $response->getProtocolVersion(),
        $statusCode,
        ($reasonPhrase ? ' '.$reasonPhrase : ''),
      ),
      true,
      $statusCode,
    );
  }

  /**
   * Emit response headers.
   *
   * Loops through each header, emitting each; the header value
   * is a set with multiple values; ensures that each is sent
   * in such a way as to create aggregate headers (instead of replace
   * the previous).
   */
  private function emitHeaders(ResponseInterface $response): void {
    $statusCode = $response->getStatusCode();
    foreach ($response->getHeaders() as $header => $values) {
      $name = $this->filterHeader($header);
      $first = $name === 'Set-Cookie' ? false : true;
      foreach ($values as $value) {
        header(Str\format('%s: %s', $name, $value), $first, $statusCode);
        $first = false;
      }
    }
  }

  /**
   * Filter a header name to wordcase
   */
  private function filterHeader(string $header): string {
    $filtered = Str\replace($header, '-', ' ');
    $filtered = Str\capitalize_words($filtered);
    return Str\replace($filtered, ' ', '-');
  }

  /**
   * Emit the message body.
   */
  private function emitBody(ResponseInterface $response): void {
    echo $response->getBody();
  }

  private function renderCookiesIntoHeader(
    ResponseInterface $response,
  ): ResponseInterface {
    $response = $response->withoutHeader(static::SET_COOKIE_HEADER);
    $cookies = vec[];

    foreach ($response->getCookies() as $name => $cookie) {
      $cookies[] = $this->convertCookieIntoString($name, $cookie);
    }

    if (0 === C\count($cookies)) {
      return $response;
    }
    return $response->withAddedHeader(static::SET_COOKIE_HEADER, $cookies);
  }

  private function convertCookieIntoString(
    string $name,
    CookieInterface $cookie,
  ): string {
    $cookieStringParts = [urlencode($name).'='.urlencode($cookie->getValue())];

    $domain = $cookie->getDomain();
    if (null !== $domain) {
      $cookieStringParts[] = Str\format('Domain=%s', $domain);
    }
    $path = $cookie->getPath();
    if (null !== $path) {
      $cookieStringParts[] = Str\format('Path=%s', $path);
    }
    $expires = $cookie->getExpires();
    if (null !== $expires) {
      $cookieStringParts[] =
        Str\format('Expires=%s', $expires->format('D, d M Y H:i:s T'));
    }
    if ($cookie->isSecure()) {
      $cookieStringParts[] = 'Secure';
    }
    if ($cookie->isHttpOnly()) {
      $cookieStringParts[] = 'HttpOnly';
    }
    $sameSite = $cookie->getSameSite();
    if ($sameSite is nonnull) {
      $cookieStringParts[] = $sameSite;
    }

    return Str\join($cookieStringParts, '; ');
  }

  public function reset(): void {
    // noop
  }
}
