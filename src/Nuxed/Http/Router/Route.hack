namespace Nuxed\Http\Router;

use namespace HH\Lib\{C, Regex, Str, Vec};
use namespace Nuxed\Http\Server;

class Route {
  const HTTP_METHOD_SEPARATOR = ':';

  private KeyedContainer<string, mixed> $options = dict[];

  private ?Container<string> $methods = null;

  private string $name;

  /**
   * @param string $path Path to match.
   * @param Server\IMiddleware $middleware Middleware to use when this route is matched.
   * @param null|string[] $methods Allowed HTTP methods; defaults to HTTP_METHOD_ANY.
   * @param null|string $name the route name
   */
  public function __construct(
    private string $path,
    private Server\IMiddleware $middleware,
    ?Container<string> $methods = null,
    ?string $name = null,
  ) {
    if ($methods is nonnull) {
      $this->methods = $this->validateHttpMethods($methods);
    }

    if ($name is null) {
      $name = $this->methods is null
        ? $path
        : $path.'^'.Str\join($this->methods, self::HTTP_METHOD_SEPARATOR);
    }

    $this->name = $name;
  }

  public function getPath(): string {
    return $this->path;
  }

  /**
   * Set the route name.
   */
  public function setName(string $name): void {
    $this->name = $name;
  }

  public function getName(): string {
    return $this->name;
  }

  public function getMiddleware(): Server\IMiddleware {
    return $this->middleware;
  }

  /**
   * @return null|Container<string> Returns null or set of allowed methods.
   */
  public function getAllowedMethods(): ?Container<string> {
    return $this->methods;
  }

  /**
   * Indicate whether the specified method is allowed by the route.
   *
   * @param string $method HTTP method to test.
   */
  public function allowsMethod(string $method): bool {
    $method = Str\uppercase($method);

    if ($this->methods is null || C\contains($this->methods, $method)) {
      return true;
    }

    return false;
  }

  public function setOptions(KeyedContainer<string, mixed> $options): void {
    $this->options = $options;
  }

  public function getOptions(): KeyedContainer<string, mixed> {
    return $this->options;
  }

  /**
   * Validate the provided HTTP method names.
   *
   * Validates, and then normalizes to upper case.
   *
   * @param Container<string> A Container of HTTP method names.
   *
   * @throws Exception\InvalidArgumentException for any invalid method names.
   */
  private function validateHttpMethods(
    Container<string> $methods,
  ): Container<string> {
    if (0 === C\count($methods)) {
      throw new Exception\InvalidArgumentException(
        'HTTP methods argument was empty; must contain at least one method',
      );
    }

    $valid = true;
    foreach ($methods as $method) {
      if (!Regex\matches($method, re"/^[!#$%&'*+.^_`\|~0-9a-z-]+$/i")) {
        $valid = false;
      }
    }

    if (!$valid) {
      throw new Exception\InvalidArgumentException(
        'One or more HTTP methods were invalid',
      );
    }

    return Vec\map($methods, ($method) ==> Str\uppercase($method));
  }
}
