namespace Nuxed\Http\Emitter;

use namespace HH\Lib\C;
use namespace HH\Lib\Str;
use namespace HH\Lib\Experimental\IO;
use namespace Nuxed\Http\Emitter\Exception;
use namespace Nuxed\Http\Message;

/**
 * Logic largely refactored from the Zend-HttpHandleRunner Zend\HttpHandlerRunner\Emitter\SapiEmitter class.
 *
 * @copyright Copyright (c) 2018 Zend Technologies USA Inc. (https://www.zend.com)
 * @license   https://github.com/zendframework/zend-httphandlerrunner/blob/master/LICENSE.md New BSD License
 */
<<__Sealed(SapiStreamEmitter::class)>>
class SapiEmitter implements IEmitter {
  const SET_COOKIE_HEADER = 'Set-Cookie';

  public async function emit(Message\Response $response): Awaitable<bool> {
    $this->assertNoPreviousOutput();
    $this->emitHeaders($response);
    $this->emitStatusLine($response);
    await $this->emitBody($response);
    return true;
  }

  protected async function emitBody(
    Message\Response $response,
  ): Awaitable<void> {
    $stream = $response->getBody();
    if ($stream->isSeekable()) {
      $stream->seek(0);
    }

    $output = IO\request_output();
    $content = await $stream->readAsync();
    await $output->writeAsync($content);
    await $output->closeAsync();
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
  protected function assertNoPreviousOutput(): void {
    if (\headers_sent()) {
      throw Exception\EmitterException::forHeadersSent();
    }

    if (\ob_get_level() > 0 && \ob_get_length() > 0) {
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
   * `emitHeaders()` in order to prevent HHVM from changing the status code of
   * the emitted response.
   *
   * @see emitHeaders()
   */
  protected function emitStatusLine(Message\Response $response): void {
    $reasonPhrase = $response->getReasonPhrase();
    $statusCode = $response->getStatusCode();
    \header(
      Str\format(
        'HTTP/%s %d%s',
        $response->getProtocolVersion(),
        $statusCode,
        (!Str\is_empty($reasonPhrase) ? ' '.$reasonPhrase : ''),
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
  protected function emitHeaders(Message\Response $response): void {
    $response = $this->renderCookiesIntoHeader($response);
    $statusCode = $response->getStatusCode();
    foreach ($response->getHeaders() as $header => $values) {
      $name = $this->filterHeader($header);
      $first = $name === static::SET_COOKIE_HEADER ? false : true;
      foreach ($values as $value) {
        \header(Str\format('%s: %s', $name, $value), $first, $statusCode);
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

  private function renderCookiesIntoHeader(
    Message\Response $response,
  ): Message\Response {
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
    Message\Cookie $cookie,
  ): string {
    $cookieStringParts = vec[
      \urlencode($name).'='.\urlencode($cookie->getValue()),
    ];

    $domain = $cookie->getDomain();
    if ($domain is nonnull) {
      $cookieStringParts[] = Str\format('Domain=%s', $domain);
    }

    $path = $cookie->getPath();
    if ($path is nonnull) {
      $cookieStringParts[] = Str\format('Path=%s', $path);
    }

    $expires = $cookie->getExpires();
    if ($expires is nonnull) {
      $cookieStringParts[] = Str\format(
        'Expires=%s',
        $expires->format('D, d M Y H:i:s T'),
      );
    }

    if ($cookie->isSecure()) {
      $cookieStringParts[] = 'Secure';
    }

    if ($cookie->isHttpOnly()) {
      $cookieStringParts[] = 'HttpOnly';
    }

    $sameSite = $cookie->getSameSite();
    if ($sameSite is nonnull) {
      $cookieStringParts[] = Str\format('SameSite=%s', $sameSite as string);
    }

    return Str\join($cookieStringParts, '; ');
  }
}
