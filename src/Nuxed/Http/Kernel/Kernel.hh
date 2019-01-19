<?hh // strict

namespace Nuxed\Http\Kernel;

use namespace Nuxed\Http\Router;
use type Nuxed\Contract\Http\Kernel\KernelInterface;
use type Nuxed\Contract\Http\Message\ServerRequestInterface;
use type Nuxed\Contract\Http\Message\ResponseInterface;
use type Nuxed\Contract\Http\Emitter\EmitterInterface;
use type Nuxed\Contract\Http\Server\MiddlewarePipeInterface;
use type Nuxed\Contract\Http\Server\RequestHandlerInterface;
use type Nuxed\Contract\Http\Router\RouteInterface;
use type Nuxed\Contract\Http\Router\RouterInterface;
use type Nuxed\Contract\Http\Router\RouteCollectorInterface;
use type Nuxed\Http\Router\RouteCollector;
use type Nuxed\Http\Server\MiddlewareFactory;
use type Nuxed\Http\Server\MiddlewarePipe;
use type Nuxed\Http\Message\Factory;
use type Nuxed\Http\Emitter\Emitter;

class Kernel implements KernelInterface {
  protected Factory $factory;
  protected RouteCollectorInterface $collector;

  public function __construct(
    protected MiddlewarePipeInterface $pipe = new MiddlewarePipe(),
    protected EmitterInterface $emitter = new Emitter(),
    protected RouterInterface $router = new Router\Router(),
    ?RouteCollectorInterface $collector = null,
    protected MiddlewareFactory $middleware = new MiddlewareFactory(),
  ) {
    $this->collector = $collector ?? new RouteCollector($router);
    $this->factory = new Factory();

    /*
     * Register the routing middleware in the middleware pipeline.
     * This middleware register the Nuxed\Router\RouteResult request attribute.
     */
    $this->pipe(new Router\Middleware\RouteMiddleware($router), -0x9500);

    /*
     * The following handle routing failures for common conditions:
     * - HEAD request but no routes answer that method
     * - OPTIONS request but no routes answer that method
     * - method not allowed
     * Order here maters; the
     */
    $this->pipe(
      new Router\Middleware\ImplicitHeadMiddleware($router, $this->factory),
      -0x9600,
    );
    $this->pipe(
      new Router\Middleware\ImplicitOptionsMiddleware($this->factory),
      -0x9700,
    );
    $this->pipe(
      new Router\Middleware\MethodNotAllowedMiddleware($this->factory),
      -0x9800,
    );

    /*
     * Register the dispatch middleware in the middleware pipeline.
     */
    $this->pipe(new Router\Middleware\DispatchMiddleware(), -0x09900);
  }

  /*
   * Pipe middleware like unix pipes.
   */
  public function pipe(mixed $middleware, int $priority = 0): void {
    $this->pipe->pipe($this->middleware->prepare($middleware), $priority);
  }

  /**
   * Process an incoming server request and return a response, optionally delegating
   * response creation to a handler.
   */
  public async function process(
    ServerRequestInterface $request,
    RequestHandlerInterface $handler,
  ): Awaitable<ResponseInterface> {
    return await $this->pipe->process($request, $handler);
  }

  /**
   * Handle the request and return a response.
   */
  public async function handle(
    ServerRequestInterface $request,
  ): Awaitable<ResponseInterface> {
    return await $this->pipe->handle($request);
  }

  /**
   * Emit a response.
   *
   * Emits a response, including status line, headers, and the message body,
   * according to the environment.
   */
  public function emit(ResponseInterface $response): bool {
    return $this->emitter->emit($response);
  }


  /**
   * Add a route for the route middleware to match.
   *
   * Accepts a combination of a path and middleware, and optionally the HTTP methods allowed.
   *
   * @param null|Set<string> $methods HTTP method to accept; null indicates any.
   * @param null|string $name The name of the route.
   * @throws Exception\DuplicateRouteException if specification represents an existing route.
   */
  public function route(
    string $path,
    mixed $middleware,
    ?Container<string> $methods = null,
    ?string $name = null,
  ): RouteInterface {
    $middleware = $this->middleware->prepare($middleware);
    return $this->collector->route($path, $middleware, $methods, $name);
  }

  /**
   * @param null|string $name The name of the route.
   */
  public function get(
    string $path,
    mixed $middleware,
    ?string $name = null,
  ): RouteInterface {
    return $this->route($path, $middleware, vec['GET'], $name);
  }

  /**
   * @param null|string $name The name of the route.
   */
  public function post(
    string $path,
    mixed $middleware,
    ?string $name = null,
  ): RouteInterface {
    return $this->route($path, $middleware, vec['POST'], $name);
  }

  /**
   * @param null|string $name The name of the route.
   */
  public function put(
    string $path,
    mixed $middleware,
    ?string $name = null,
  ): RouteInterface {
    return $this->route($path, $middleware, vec['PUT'], $name);
  }

  /**
   * @param null|string $name The name of the route.
   */
  public function patch(
    string $path,
    mixed $middleware,
    ?string $name = null,
  ): RouteInterface {
    return $this->route($path, $middleware, vec['PATCH'], $name);
  }

  /**
   * @param null|string $name The name of the route.
   */
  public function delete(
    string $path,
    mixed $middleware,
    ?string $name = null,
  ): RouteInterface {
    return $this->route($path, $middleware, vec['DELETE'], $name);
  }

  /**
   * @param null|string $name The name of the route.
   */
  public function any(
    string $path,
    mixed $middleware,
    ?string $name = null,
  ): RouteInterface {
    return $this->route($path, $middleware, null, $name);
  }

  public function getRoutes(): Container<RouteInterface> {
    return $this->collector->getRoutes();
  }

  /**
   * Perform any final actions for the request lifecycle.
   */
  public function terminate(
    ServerRequestInterface $request,
    ResponseInterface $response,
  ): void {
    $request->getBody()->close();
    $response->getBody()->close();
  }
}
