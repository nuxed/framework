namespace Nuxed\Kernel;

use namespace HH\Asio;
use type His\Container\ContainerInterface;
use type Nuxed\Contract\Event\EventDispatcherInterface;
use type Nuxed\Contract\Kernel\KernelInterface;
use type Nuxed\Contract\Http\Message\ServerRequestInterface;
use type Nuxed\Contract\Http\Message\ResponseInterface;
use type Nuxed\Contract\Http\Emitter\EmitterInterface;
use type Nuxed\Contract\Http\Server\MiddlewareInterface;
use type Nuxed\Contract\Http\Server\MiddlewarePipeInterface;
use type Nuxed\Contract\Http\Server\RequestHandlerInterface;
use type Nuxed\Contract\Http\Router\RouteInterface;
use type Nuxed\Contract\Http\Router\RouteCollectorInterface;
use type Nuxed\Contract\Log\LoggerAwareTrait;
use type Nuxed\Contract\Event\EventSubscriberInterface;
use type Nuxed\Contract\Event\EventInterface;
use type Nuxed\Http\Message\ServerRequest;

final class Kernel implements KernelInterface {
  use LoggerAwareTrait;

  public function __construct(
    private ContainerInterface $container,
    private MiddlewarePipeInterface $pipe,
    private EmitterInterface $emitter,
    private EventDispatcherInterface $events,
    private RouteCollectorInterface $collector,
  ) {}

  public function use(
    classname<Extension\ExtensionInterface> $extension,
  ): void {
    $extension = new $extension($this->container);
    $extension->route($this);
    $extension->pipe($this);
    $extension->subscribe($this->events);
  }

  public function subscribe(EventSubscriberInterface $subscriber): void {
    $event =
      Asio\join($this->events->dispatch(new Event\SubscribeEvent($subscriber)));
    $this->events->subscribe($event->subscriber);
  }

  public function on<TEvent as EventInterface>(
    classname<TEvent> $event,
    (function(TEvent): Awaitable<void>) $listener,
    int $priority = 0,
  ): void {
    $this->events->on($event, $listener, $priority);
  }

  /*
   * Pipe middleware like unix pipes.
   */
  public function pipe(
    MiddlewareInterface $middleware,
    int $priority = 0,
  ): void {
    $event = Asio\join(
      $this->events
        ->dispatch(new Event\PipeEvent($middleware, $priority)),
    );
    $this->pipe->pipe($event->middleware, $event->priority);
  }

  /**
   * Process an incoming server request and return a response, optionally delegating
   * response creation to a handler.
   */
  public async function process(
    ServerRequestInterface $request,
    RequestHandlerInterface $handler,
  ): Awaitable<ResponseInterface> {
    $event = await $this->events
      ->dispatch(new Event\ProcessEvent($request, $handler));

    return await $this->pipe->process($event->request, $event->handler);
  }

  /**
   * Handle the request and return a response.
   */
  public async function handle(
    ServerRequestInterface $request,
  ): Awaitable<ResponseInterface> {
    $event = await $this->events->dispatch(new Event\HandleEvent($request));

    return await $this->pipe->handle($event->request);
  }

  /**
   * Emit a response.
   *
   * Emits a response, including status line, headers, and the message body,
   * according to the environment.
   */
  public async function emit(ResponseInterface $response): Awaitable<bool> {
    $event = await $this->events->dispatch(new Event\EmitEvent($response));

    return await $this->emitter->emit($event->response);
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
    MiddlewareInterface $middleware,
    ?Container<string> $methods = null,
    ?string $name = null,
  ): RouteInterface {
    return $this->collector->route($path, $middleware, $methods, $name);
  }

  /**
   * Register fallback middleware.
   */
  public function fallback(MiddlewareInterface $middleware): void {
    $this->pipe($middleware, -0x9950);
  }

  /**
   * @param null|string $name The name of the route.
   */
  public function get(
    string $path,
    MiddlewareInterface $middleware,
    ?string $name = null,
  ): RouteInterface {
    return $this->route($path, $middleware, vec['GET'], $name);
  }

  /**
   * @param null|string $name The name of the route.
   */
  public function post(
    string $path,
    MiddlewareInterface $middleware,
    ?string $name = null,
  ): RouteInterface {
    return $this->route($path, $middleware, vec['POST'], $name);
  }

  /**
   * @param null|string $name The name of the route.
   */
  public function put(
    string $path,
    MiddlewareInterface $middleware,
    ?string $name = null,
  ): RouteInterface {
    return $this->route($path, $middleware, vec['PUT'], $name);
  }

  /**
   * @param null|string $name The name of the route.
   */
  public function patch(
    string $path,
    MiddlewareInterface $middleware,
    ?string $name = null,
  ): RouteInterface {
    return $this->route($path, $middleware, vec['PATCH'], $name);
  }

  /**
   * @param null|string $name The name of the route.
   */
  public function delete(
    string $path,
    MiddlewareInterface $middleware,
    ?string $name = null,
  ): RouteInterface {
    return $this->route($path, $middleware, vec['DELETE'], $name);
  }

  /**
   * @param null|string $name The name of the route.
   */
  public function any(
    string $path,
    MiddlewareInterface $middleware,
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
  public async function terminate(
    ServerRequestInterface $request,
    ResponseInterface $response,
  ): Awaitable<void> {
    $event = await $this->events
      ->dispatch(new Event\TerminateEvent($request, $response));
    $event->request->getBody()->close();
    $event->response->getBody()->close();
  }

  /**
   * Run the Http Kernel.
   */
  public async function run(): Awaitable<noreturn> {
    $request = ServerRequest::capture();
    $response = await $this->handle($request);
    $emitted = await $this->emit($response);
    if ($emitted) {
      await $this->terminate($request, $response);
    }

    exit($emitted ? $this->getTerminationStatusCode($response) : 1);
  }

  /**
   * Get the termination exit code.
   *
   * Exit statuses should be in the range 0 to 254,
   * the exit status 255 is reserved by HHVM and shall not be used.
   * The status 0 is used to terminate the program successfully.
   */
  private function getTerminationStatusCode(ResponseInterface $response): int {
    $code = $response->getStatusCode();
    if ($code >= 200 && $code < 400) {
      return 0;
    } elseif ($code <= 255 && $code > 0) {
      // even that 0 is an error, we don't return it
      // otherwise the script exits successfully
      // and that's not true in this case
      return $code;
    } else {
      return 1;
    }
  }
}
