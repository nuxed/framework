namespace Nuxed\Http\Message;

use namespace HH\Lib\{C, Regex, Str};
use type Nuxed\Util\StringableTrait;

final class Uri {
  use StringableTrait;

  private static dict<string, int> $schemes = dict[
    'http' => 80,
    'https' => 443,
  ];

  private string $scheme = '';

  private (string, ?string) $userInfo = tuple('', null);

  private string $host = '';

  private ?int $port;

  private string $path = '';

  private string $query = '';

  private string $fragment = '';

  public function __construct(string $uri = '') {
    if ('' !== $uri) {
      $parts = \parse_url($uri);

      if (false === $parts) {
        throw new Exception\InvalidArgumentException(
          "Unable to parse URI: ".$uri,
        );
      }

      $this->applyParts(dict($parts));
    }
  }

  public function toString(): string {
    return self::createUriString(
      $this->scheme,
      $this->getAuthority(),
      $this->path,
      $this->query,
      $this->fragment,
    );
  }

  public function getScheme(): string {
    return $this->scheme;
  }

  public function getAuthority(): string {
    if ('' === $this->host) {
      return '';
    }

    $authority = $this->host;

    list($user, $password) = $this->userInfo;

    if ('' !== $user) {
      if ($password is nonnull) {
        $authority = Str\format('%s:%s@%s', $user, $password, $authority);
      } else {
        $authority = Str\format('%s@%s', $user, $authority);
      }
    }

    if ($this->port is nonnull) {
      $authority .= ':'.((string)$this->port);
    }

    return $authority;
  }

  public function getUserInfo(): (string, ?string) {
    return $this->userInfo;
  }

  public function getHost(): string {
    return $this->host;
  }

  public function getPort(): ?int {
    return $this->port;
  }

  public function getPath(): string {
    return $this->path;
  }

  public function getQuery(): string {
    return $this->query;
  }

  public function getFragment(): string {
    return $this->fragment;
  }

  public function withScheme(string $scheme): this {
    $scheme = Str\lowercase($scheme);

    if ($this->scheme === $scheme) {
      return $this;
    }

    $new = clone $this;
    $new->scheme = $scheme;
    $new->port = $new->filterPort($new->port);

    return $new;
  }

  public function withUserInfo(string $user, ?string $password = null): this {
    if ('' === $password) {
      $password = null;
    }
    $info = tuple($user, $password);

    if ($this->userInfo === $info) {
      return $this;
    }

    $new = clone $this;
    $new->userInfo = $info;

    return $new;
  }

  public function withHost(string $host): this {
    $host = Str\lowercase($host);

    if ($this->host === $host) {
      return $this;
    }

    $new = clone $this;
    $new->host = $host;

    return $new;
  }

  public function withPort(?int $port): this {
    $port = $this->filterPort($port);

    if ($this->port === $port) {
      return $this;
    }

    $new = clone $this;
    $new->port = $port;

    return $new;
  }

  public function withPath(string $path): this {
    $path = $this->filterPath($path);

    if ($this->path === $path) {
      return $this;
    }

    $new = clone $this;
    $new->path = $path;

    return $new;
  }

  public function withQuery(string $query): this {
    $query = $this->filterQueryAndFragment($query);
    if ($this->query === $query) {
      return $this;
    }

    $new = clone $this;
    $new->query = $query;

    return $new;
  }

  public function withFragment(string $fragment): this {
    $fragment = $this->filterQueryAndFragment($fragment);

    if ($this->fragment === $fragment) {
      return $this;
    }

    $new = clone $this;
    $new->fragment = $fragment;

    return $new;
  }

  /**
   * Apply parse_url parts to a URI.
   */
  private function applyParts(KeyedContainer<string, arraykey> $parts): void {
    $this->scheme = C\contains_key($parts, 'scheme')
      ? Str\lowercase((string)$parts['scheme'])
      : '';

    $this->host = C\contains_key($parts, 'host')
      ? Str\lowercase((string)$parts['host'])
      : '';

    $this->port = C\contains_key($parts, 'port')
      ? $this->filterPort((int)$parts['port'])
      : null;

    $this->path = C\contains_key($parts, 'path')
      ? $this->filterPath((string)$parts['path'])
      : '';

    $this->query = C\contains_key($parts, 'query')
      ? $this->filterQueryAndFragment((string)$parts['query'])
      : '';

    $this->fragment = C\contains_key($parts, 'fragment')
      ? $this->filterQueryAndFragment((string)$parts['fragment'])
      : '';

    if (C\contains_key($parts, 'user')) {

      $this->userInfo = tuple((string)$parts['user'], null);

      if (C\contains_key($parts, 'pass')) {
        $this->userInfo = tuple((string)$parts['user'], (string)$parts['pass']);
      }

    } else {
      $this->userInfo = tuple('', null);
    }
  }

  /**
   * Create a URI string from its various parts.
   */
  private static function createUriString(
    string $scheme,
    string $authority,
    string $path,
    string $query,
    string $fragment,
  ): string {
    $uri = '';

    if ('' !== $scheme) {
      $uri .= $scheme.':';
    }

    if ('' !== $authority) {
      $uri .= '//'.$authority;
    }

    if (Str\length($path) > 0) {
      if ('/' !== $path[0]) {
        if ('' !== $authority) {
          // If the path is rootless and an authority is present, the path MUST be prefixed by "/"
          $path = '/'.$path;
        }
      } else if (Str\length($path) > 1 && '/' === $path[1]) {
        if ('' === $authority) {
          // If the path is starting with more than one "/" and no authority is present, the
          // starting slashes MUST be reduced to one.
          $path = '/'.Str\trim_left($path, '/');
        }
      }

      $uri .= $path;
    }

    if ('' !== $query) {
      $uri .= '?'.$query;
    }

    if ('' !== $fragment) {
      $uri .= '#'.$fragment;
    }

    return $uri;
  }

  /**
   * Is a given port non-standard for the current scheme?
   */
  private static function isNonStandardPort(string $scheme, int $port): bool {
    return !C\contains_key(self::$schemes, $scheme) ||
      $port !== self::$schemes[$scheme];
  }

  private function filterPort(?int $port): ?int {
    if ($port is null) {
      return null;
    }

    if (!self::isNonStandardPort($this->scheme, $port)) {
      return null;
    }

    if (1 > $port || 0xffff < $port) {
      throw new Exception\InvalidArgumentException(
        Str\format('Invalid port: %d. Must be between 1 and 65535', $port),
      );
    }

    return $port;
  }

  private function filterPath(string $path): string {
    return Regex\replace_with(
      $path,
      re"/(?:[^a-zA-Z0-9_\-\.~!\$&\'\(\)\*\+,;=%:@\/]++|%(?![A-Fa-f0-9]{2}))/",
      ($match) ==> \rawurlencode($match[0]),
    );
  }

  private function filterQueryAndFragment(string $str): string {
    return Regex\replace_with(
      $str,
      re"/(?:[^a-zA-Z0-9_\-\.~!\$&\'\(\)\*\+,;=%:@\/\?]++|%(?![A-Fa-f0-9]{2}))/",
      ($match) ==> \rawurlencode($match[0]),
    );
  }
}
