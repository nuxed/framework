namespace Nuxed\Kernel;

use type Nuxed\Contract\Event\EventDispatcherInterface;
use type Nuxed\Contract\Kernel\KernelInterface;
use type Nuxed\Container\Container as ServiceContainer;
use type Nuxed\Container\ReflectionContainer;
use type Nuxed\Container\ServiceProvider\ServiceProviderInterface;
use type Nuxed\Contract\Http\Message\ServerRequestInterface;
use type Nuxed\Contract\Http\Message\ResponseInterface;
use type Nuxed\Contract\Http\Emitter\EmitterInterface;
use type Nuxed\Contract\Http\Server\MiddlewarePipeInterface;
use type Nuxed\Contract\Http\Server\RequestHandlerInterface;
use type Nuxed\Contract\Http\Router\RouteInterface;
use type Nuxed\Contract\Http\Router\RouterInterface;
use type Nuxed\Contract\Http\Router\RouteCollectorInterface;
use type Nuxed\Http\Server\MiddlewareFactory;
use type Nuxed\Http\Message\ServerRequest;
use type Nuxed\Contract\Log\LoggerAwareTrait;
use type Nuxed\Contract\Event\EventSubscriberInterface;
use type Nuxed\Contract\Event\EventListener;
use type Nuxed\Contract\Event\EventInterface;

class Kernel implements KernelInterface {
  use LoggerAwareTrait;

  protected MiddlewarePipeInterface $pipe;
  protected EmitterInterface $emitter;
  protected RouterInterface $router;
  protected EventDispatcherInterface $events;
  protected MiddlewareFactory $middleware;
  protected RouteCollectorInterface $collector;
  protected Configuration $configuration;

  public function __construct(
    KeyedContainer<string, mixed> $configuration = dict[],
    protected ServiceContainer $container = new ServiceContainer(),
  ) {
    $container->delegate(new ReflectionContainer());
    $this->configuration = Config::load($configuration);

    $container->share('config', () ==> $this->configuration);

    $providers = vec[
      ServiceProvider\HttpServiceProvider::class,
      ServiceProvider\EventServiceProvider::class,
      ServiceProvider\ErrorServiceProvider::class,
      ServiceProvider\LoggerServiceProvider::class,
      ServiceProvider\CacheServiceProvider::class,
    ];

    foreach ($providers as $provider) {
      $container->addServiceProvider($provider);
    }

    $this->pipe = $this->getService(MiddlewarePipeInterface::class);
    $this->emitter = $this->getService(EmitterInterface::class);
    $this->router = $this->getService(RouterInterface::class);
    $this->events = $this->getService(EventDispatcherInterface::class);
    $this->middleware = $this->getService(MiddlewareFactory::class);
    $this->collector = $this->getService(RouteCollectorInterface::class);

    $this->use(new Extension\HttpExtension());
    foreach ($this->configuration['app']['extensions'] as $extension) {
      $this->use(
        $this->container->get($extension) as Extension\ExtensionInterface,
      );
    }
  }

  /**
   * Register a service provider with the container.
   */
  public function register(ServiceProviderInterface $service): void {
    $event = $this->events->dispatch(new Event\RegisterEvent($service));
    $this->container->addServiceProvider($event->service);
  }

  public function use(Extension\ExtensionInterface $extension): void {
    $extension->setContainer($this->container);
    foreach ($extension->services($this->configuration) as $service) {
      $this->container->addServiceProvider($service);
    }

    $extension->route($this, $this->middleware);
    $extension->pipe($this, $this->middleware);
    $extension->subscribe($this->events);
  }

  public function subscribe(EventSubscriberInterface $subscriber): void {
    $event = $this->events->dispatch(new Event\SubscribeEvent($subscriber));
    $this->events->subscribe($event->subscriber);
  }

  public function on(
    classname<EventInterface> $event,
    EventListener $listener,
    int $priority = 0,
  ): void {
    $this->events->on($event, $listener, $priority);
  }

  /*
   * Pipe middleware like unix pipes.
   */
  public function pipe(mixed $middleware, int $priority = 0): void {
    $middleware = $this->middleware->prepare($middleware);
    $event = $this->events
      ->dispatch(new Event\PipeEvent($middleware, $priority));
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
    $event = $this->events
      ->dispatch(new Event\ProcessEvent($request, $handler));

    return await $this->pipe->process($event->request, $event->handler);
  }

  /**
   * Handle the request and return a response.
   */
  public async function handle(
    ServerRequestInterface $request,
  ): Awaitable<ResponseInterface> {
    $event = $this->events->dispatch(new Event\HandleEvent($request));

    return await $this->pipe->handle($event->request);
  }

  /**
   * Emit a response.
   *
   * Emits a response, including status line, headers, and the message body,
   * according to the environment.
   */
  public async function emit(ResponseInterface $response): Awaitable<bool> {
    $event = $this->events->dispatch(new Event\EmitEvent($response));

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
    mixed $middleware,
    ?Container<string> $methods = null,
    ?string $name = null,
  ): RouteInterface {
    $middleware = $this->middleware->prepare($middleware);

    return $this->collector->route($path, $middleware, $methods, $name);
  }

  /**
   * Register fallback middleware.
   */
  public function fallback(mixed $middleware): void {
    $this->pipe($middleware, -0x9950);
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
  public async function terminate(
    ServerRequestInterface $request,
    ResponseInterface $response,
  ): Awaitable<void> {
    $event =
      $this->events->dispatch(new Event\TerminateEvent($request, $response));
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
    if ($code >= 200 && $code < 300) {
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

  private function getService<T>(classname<T> $service): T {
    // UNSAFE
    return $this->container->get($service);
  }
}
