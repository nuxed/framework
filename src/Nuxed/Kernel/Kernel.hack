namespace Nuxed\Kernel;

use namespace HH\Asio;
use namespace Nuxed\Kernel;
use namespace His\Container;
use namespace Nuxed\Contract;
use namespace Nuxed\Contract\Http\Message;
use namespace Nuxed\Contract\Http\Emitter;
use namespace Nuxed\Contract\Http\Server;
use namespace Nuxed\Contract\Http\Router;
use namespace Nuxed\Contract\Log;
use namespace Nuxed\Contract\Event;
use namespace Nuxed\Http;

final class Kernel implements Contract\Kernel\KernelInterface {
  use Http\Router\RouteCollectorTrait;
  use Log\LoggerAwareTrait;

  public function __construct(
    private Container\ContainerInterface $container,
    private Server\MiddlewarePipeInterface $pipe,
    private Emitter\EmitterInterface $emitter,
    private Event\EventDispatcherInterface $events,
    private Router\RouterInterface $router,
  ) {}

  public function use(
    classname<Extension\ExtensionInterface> $extension,
  ): void {
    $extension = new $extension($this->container);
    $extension->route($this);
    $extension->pipe($this);
    $extension->subscribe($this->events);
  }

  public function subscribe(Event\EventSubscriberInterface $subscriber): void {
    $event = Asio\join(
      $this->events->dispatch(new Kernel\Event\SubscribeEvent($subscriber)),
    );
    $this->events->subscribe($event->subscriber);
  }

  public function on<TEvent as Event\EventInterface>(
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
    Server\MiddlewareInterface $middleware,
    int $priority = 0,
  ): void {
    $event = Asio\join(
      $this->events
        ->dispatch(new Kernel\Event\PipeEvent($middleware, $priority)),
    );
    $this->pipe->pipe($event->middleware, $event->priority);
  }

  /**
   * Process an incoming server request and return a response, optionally delegating
   * response creation to a handler.
   */
  public async function process(
    Message\ServerRequestInterface $request,
    Server\RequestHandlerInterface $handler,
  ): Awaitable<Message\ResponseInterface> {
    $event = await $this->events
      ->dispatch(new Kernel\Event\ProcessEvent($request, $handler));

    return await $this->pipe->process($event->request, $event->handler);
  }

  /**
   * Handle the request and return a response.
   */
  public async function handle(
    Message\ServerRequestInterface $request,
  ): Awaitable<Message\ResponseInterface> {
    $event = await $this->events
      ->dispatch(new Kernel\Event\HandleEvent($request));

    return await $this->pipe->handle($event->request);
  }

  /**
   * Emit a response.
   *
   * Emits a response, including status line, headers, and the message body,
   * according to the environment.
   */
  public async function emit(
    Message\ResponseInterface $response,
  ): Awaitable<bool> {
    $event = await $this->events
      ->dispatch(new Kernel\Event\EmitEvent($response));

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
    Server\MiddlewareInterface $middleware,
    ?Container<string> $methods = null,
    ?string $name = null,
  ): Router\RouteInterface {
    return $this->router->route($path, $middleware, $methods, $name);
  }

  /**
   * Retrieve all directly registered routes with the application.
   */
  public function getRoutes(): Container<Router\RouteInterface> {
    return $this->router->getRoutes();
  }

  /**
   * Register fallback middleware.
   */
  public function fallback(Server\MiddlewareInterface $middleware): void {
    $this->pipe($middleware, -0x9950);
  }

  /**
   * Perform any final actions for the request lifecycle.
   */
  public async function terminate(
    Message\ServerRequestInterface $request,
    Message\ResponseInterface $response,
  ): Awaitable<void> {
    $event = await $this->events
      ->dispatch(new Kernel\Event\TerminateEvent($request, $response));

    await $event->request->getBody()->closeAsync();
    await $event->response->getBody()->closeAsync();
  }

  /**
   * Run the Http Kernel.
   */
  public async function run(): Awaitable<noreturn> {
    $request = Http\Message\ServerRequest::capture();
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
  private function getTerminationStatusCode(
    Message\ResponseInterface $response,
  ): int {
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
