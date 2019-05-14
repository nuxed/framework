namespace Nuxed\Http\Message\_Private;

use namespace HH\Lib\C;
use namespace HH\Lib\Str;
use namespace HH\Lib\Regex;
use namespace Nuxed\Http\Message\Exception;
use type Nuxed\Contract\Http\Message\UriInterface;
use type Nuxed\Http\Message\Uri;

final class UriMarshaler {
  public function marshal(
    KeyedContainer<string, mixed> $server,
    KeyedContainer<string, Container<string>> $headers,
  ): UriInterface {
    $uri = new Uri('');
    // URI scheme
    $scheme = 'http';
    if (C\contains_key($server, 'HTTPS')) {
      $https = $this->marshalHttpsValue($server['HTTPS']);
    } else if (C\contains_key($server, 'https')) {
      $https = $this->marshalHttpsValue($server['https']);
    } else {
      $https = false;
    }

    if (
      $https ||
      Str\lowercase(
        $this->getHeadersFromMap('x-forwarded-proto', $headers, '') as string,
      ) ===
        'https'
    ) {
      $scheme = 'https';
    }

    $uri = $uri->withScheme($scheme);

    // Set the host
    $hostAndPort = $this->marshalHostAndPort($headers, $server);
    $host = $hostAndPort['host'];
    $port = $hostAndPort['port'];

    if ($host !== '') {
      $uri = $uri->withHost($host);
      if (null !== $port) {
        $uri = $uri->withPort($port);
      }
    }

    $path = $this->marshalRequestPath($server);
    $path = C\firstx(Str\split($path, '?', 2));
    $query = '';
    if (C\contains_key($server, 'QUERY_STRING')) {
      $query = Str\trim_left((string)$server['QUERY_STRING'], '?');
    }
    // URI fragment
    $fragment = '';

    if (Str\contains($path, '#')) {
      list($path, $fragment) = Str\split($path, '#', 2);
    }

    return $uri
      ->withPath($path)
      ->withFragment($fragment)
      ->withQuery($query);
  }

  private function marshalIpv6HostAndPort(
    KeyedContainer<string, mixed> $server,
    string $host,
    ?int $port,
  ): shape('host' => string, 'port' => ?int, ...) {
    $host = '['.((string)$server['SERVER_ADDR'] ?? '').']';
    $port ??= 80;
    if (
      $port.']' === Str\slice($host, ((int)Str\search_last($host, ':')) + 1)
    ) {
      // The last digit of the IPv6-Address has been taken as port
      // Unset the port so the default port can be used
      $port = null;
    }

    return shape(
      'host' => $host,
      'port' => $port,
    );
  }

  /**
   * From Symfony's Symfony\Component\HttpFoundation\Request class
   * @see https://github.com/symfony/symfony/blob/master/src/Symfony/Component/HttpFoundation/Request.php#L1149-L1161
   *
   * @copyright Copyright (c) 2004-2018 Fabien Potencier <fabien@symfony.com>
   * @license   https://github.com/symfony/symfony/blob/master/LICENSE MIT License
   */
  private function marshalHostFromHeader(string $host): string {
    // trim and remove port number from host
    // host is lowercase as per RFC 952/2181
    $host = Str\lowercase(Regex\replace(Str\trim($host), re"/:\d+$/", ''));

    // as the host can come from the user (HTTP_HOST and depending on the configuration, SERVER_NAME too can come from the user)
    // check that it does not contain forbidden characters (see RFC 952 and RFC 2181)
    // use preg_replace() instead of preg_match() to prevent DoS attacks with long host names
    if (
      $host !== '' &&
      '' !== Regex\replace($host, re"/(?:^\[)?[a-zA-Z0-9-:\]_]+\.?/", '')
    ) {
      return '';
    }

    return $host;
  }

  /**
   * From Symfony's Symfony\Component\HttpFoundation\Request class
   * @see https://github.com/symfony/symfony/blob/master/src/Symfony/Component/HttpFoundation/Request.php#L910-L918
   *
   * @copyright Copyright (c) 2004-2018 Fabien Potencier <fabien@symfony.com>
   * @license   https://github.com/symfony/symfony/blob/master/LICENSE MIT License
   */
  private function marshalPortFromHeader(string $host): ?int {
    if ('[' === Str\slice($host, 0, 1)) {
      $pos = Str\search($host, ':', (int)Str\search_last($host, ']'));
    } else {
      $pos = Str\search_last($host, ':');
    }

    if (null !== $pos) {
      return (int)Str\slice($host, $pos + 1);
    }

    return null;
  }

  /**
   * Marshal the host and port from HTTP headers and/or the PHP environment.
   *
   * @return shape('host' => string, 'port' => ?int,...) shape of two items, host and port, in that order.
   */
  private function marshalHostAndPort(
    KeyedContainer<string, Container<string>> $headers,
    KeyedContainer<string, mixed> $server,
  ): shape('host' => string, 'port' => ?int, ...) {
    $header = $this->getHeadersFromMap('host', $headers);
    if (null !== $header) {
      return shape(
        'host' => $this->marshalHostFromHeader($header),
        'port' => $this->marshalPortFromHeader($header),
      );
    }

    if (!C\contains_key($server, 'SERVER_NAME')) {
      return shape('host' => '', 'port' => null);
    }

    $host = $server['SERVER_NAME'] as string;
    $port = C\contains_key($server, 'SERVER_PORT')
      ? (int)$server['SERVER_PORT']
      : null;

    if (
      !C\contains_key($server, 'SERVER_ADDR') ||
      !Regex\matches($host, re"/^\[[0-9a-fA-F\:]+\]$/")
    ) {
      return shape('host' => $host, 'port' => $port);
    }

    return $this->marshalIpv6HostAndPort($server, $host, $port);
  }

  /**
   * Detect the path for the request
   *
   * Looks at a variety of criteria in order to attempt to autodetect the base
   * request path, including:
   *
   * - IIS7 UrlRewrite environment
   * - REQUEST_URI
   * - ORIG_PATH_INFO
   *
   * From ZF2's Zend\Http\PhpEnvironment\Request class
   * @copyright Copyright (c) 2005-2015 Zend Technologies USA Inc. (http://www.zend.com)
   * @license   http://framework.zend.com/license/new-bsd New BSD License
   */
  private function marshalRequestPath(
    KeyedContainer<string, mixed> $server,
  ): string {
    // IIS7 with URL Rewrite: make sure we get the unencoded url
    // (double slash problem).
    $iisUrlRewritten = C\contains_key($server, 'IIS_WasUrlRewritten')
      ? $server['IIS_WasUrlRewritten'] as string
      : null;
    $unencodedUrl = C\contains_key($server, 'UNENCODED_URL')
      ? $server['UNENCODED_URL'] as string
      : '';

    if ('1' === $iisUrlRewritten && '' !== $unencodedUrl) {
      return $unencodedUrl;
    }

    $requestUri = $server['REQUEST_URI'] ?? null;

    if ($requestUri is string) {
      return Regex\replace($requestUri, re"#^[^/:]+://[^/]+#", '');
    }

    $origPathInfo = $server['ORIG_PATH_INFO'] ?? null;

    if (null === $origPathInfo || '' === $origPathInfo) {
      return '/';
    }

    return $origPathInfo as string;
  }

  private function marshalHttpsValue(mixed $https): bool {
    if ($https is bool) {
      return $https;
    }

    if (!$https is string) {
      throw new Exception\InvalidArgumentException(
        Str\format(
          'SAPI HTTPS value MUST be a string or boolean; received %s',
          \gettype($https),
        ),
      );
    }

    return '' !== $https && 'off' !== Str\lowercase($https);
  }

  private function getHeadersFromMap(
    string $name,
    KeyedContainer<string, Container<string>> $headers,
    ?string $default = null,
  ): ?string {
    $header = Str\lowercase($name);

    foreach ($headers as $key => $value) {
      if (Str\lowercase($key) === $header) {
        return Str\join($value, ', ');
      }
    }

    return $default;
  }
}
