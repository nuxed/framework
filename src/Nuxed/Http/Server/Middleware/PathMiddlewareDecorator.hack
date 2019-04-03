namespace Nuxed\Http\Server\Middleware;

use namespace HH\Lib\Str;
use type Nuxed\Contract\Http\Message\ResponseInterface;
use type Nuxed\Contract\Http\Message\ServerRequestInterface;
use type Nuxed\Contract\Http\Server\MiddlewareInterface;
use type Nuxed\Contract\Http\Server\RequestHandlerInterface;
use type Nuxed\Http\Server\RequestHandler\CallableRequestHandlerDecorator;

final class PathMiddlewareDecorator implements MiddlewareInterface {
  private string $prefix;

  public function __construct(
    string $prefix,
    private MiddlewareInterface $middleware,
  ) {
    $this->prefix = $this->normalizePrefix($prefix);
  }

  public async function process(
    ServerRequestInterface $request,
    RequestHandlerInterface $handler,
  ): Awaitable<ResponseInterface> {
    $path = $request->getUri()->getPath();
    $path = $path === '' ? '/' : $path;

    // Current path is shorter than decorator path
    if (Str\length($path) < Str\length($this->prefix)) {
      return await $handler->handle($request);
    }

    // Current path does not match decorator path
    if (0 !== Str\search_ci($path, $this->prefix)) {
      return await $handler->handle($request);
    }

    // Skip if match is not at a border ('/' or end)
    $border = $this->getBorder($path);
    if ('' !== $border && '/' !== $border) {
      return await $handler->handle($request);
    }

    // Trim off the part of the url that matches the prefix if it is not / only
    if ($this->prefix !== '/') {
      $requestToProcess = $this->prepareRequestWithTruncatedPrefix($request);
    } else {
      $requestToProcess = $request;
    }

    // Process our middleware.
    // If the middleware calls on the handler, the handler should be provided
    // the original request, as this indicates we've left the path-segregated
    // layer.
    $handler = $this->prepareHandlerForOriginalRequest($handler);
    return await $this->middleware
      ->process($requestToProcess, $handler);
  }

  private function getBorder(string $path): string {
    if ($this->prefix === '/') {
      return '/';
    }

    $length = Str\length($this->prefix);

    return Str\length($path) > $length ? $path[$length] : '';
  }

  private function prepareRequestWithTruncatedPrefix(
    ServerRequestInterface $request,
  ): ServerRequestInterface {
    $uri = $request->getUri();
    $path = $this->getTruncatedPath($this->prefix, $uri->getPath());
    $new = $uri->withPath($path);
    return $request->withUri($new);
  }

  private function getTruncatedPath(string $segment, string $path): string {
    if ($segment === $path) {
      // Decorated path and current path are the same; return empty string
      return '';
    }

    // Strip decorated path from start of current path
    return Str\slice($path, Str\length($segment));
  }

  private function prepareHandlerForOriginalRequest(
    RequestHandlerInterface $handler,
  ): RequestHandlerInterface {
    $callable = async ($request) ==> {
      $uri = $request->getUri();
      $uri = $uri->withPath($this->prefix.$uri->getPath());
      return await $handler->handle($request->withUri($uri));
    };

    return new CallableRequestHandlerDecorator($callable);
  }

  /**
   * Ensures that the right-most slash is trimmed for prefixes of more than
   * one character, and that the prefix begins with a slash.
   */
  private function normalizePrefix(string $prefix): string {
    $prefix = Str\length($prefix) > 1 ? Str\trim_right($prefix, '/') : $prefix;

    if (0 !== Str\search($prefix, '/')) {
      $prefix = '/'.$prefix;
    }

    return $prefix;
  }
}
