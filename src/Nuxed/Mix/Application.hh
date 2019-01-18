<?hh // strict

namespace Nuxed\Mix;

use namespace Nuxed;
use type Nuxed\Contract\Event\EventDispatcherInterface;
use type Nuxed\Contract\Event\EventSubscriberInterface;
use type Nuxed\Contract\Event\EventInterface;
use type Nuxed\Contract\Event\EventListener;
use type Nuxed\Contract\Http\Message\ServerRequestInterface;
use type Nuxed\Contract\Http\Message\ResponseInterface;
use type Nuxed\Contract\Http\Kernel\KernelInterface;
use type Nuxed\Contract\Http\Server\RequestHandlerInterface;
use type Nuxed\Contract\Http\Router\RouteCollectorInterface;
use type Nuxed\Contract\Http\Router\RouteInterface;
use type Nuxed\Contract\Service\ResetInterface;
use type Nuxed\Container\ServiceProvider\ServiceProviderInterface;
use type Nuxed\Container\Container;
use type Nuxed\Http\Message\ServerRequest;
use type Nuxed\Http\Server\MiddlewareFactory;
use type Container as C;

class Application implements KernelInterface, ResetInterface {
  protected KernelInterface $kernel;
  protected RouteCollectorInterface $collector;
  protected EventDispatcherInterface $events;
  protected MiddlewareFactory $middlewares;
  protected Configuration $configuration;
  protected vec<Extension\ExtensionInterface> $extensions = vec[];

  public function __construct(
    KeyedContainer<string, mixed> $configuration = dict[],
    public Container $container = new Container(),
  ) {
    $this->configuration = Config::load($configuration);

    $container->share('config', () ==> $this->configuration);

    $providers = vec[
      new ServiceProvider\LoggerServiceProvider($this->configuration),
      new ServiceProvider\EventServiceProvider($this->configuration),
      new ServiceProvider\HttpServiceProvider($this->configuration),
      new ServiceProvider\ErrorServiceProvider($this->configuration),
      new ServiceProvider\MysqlServiceProvider($this->configuration),
      new ServiceProvider\RedisServiceProvider($this->configuration),
      new ServiceProvider\CacheServiceProvider($this->configuration),
    ];

    foreach ($providers as $provider) {
      $container->addServiceProvider($provider);
    }

    $this->middlewares = new MiddlewareFactory($container);

    $this->kernel = $this->getService(KernelInterface::class);
    $this->collector = $this->getService(RouteCollectorInterface::class);
    $this->events = $this->getService(EventDispatcherInterface::class);

    $this->use(new Extension\FrameworkExtension());
  }

  public function use(Extension\ExtensionInterface $extension): void {
    $this->extensions[] = $extension;
    $extension->setContainer($this->container);
    foreach ($extension->services($this->configuration) as $service) {
      $this->container->addServiceProvider($service);
    }
    $extension->route($this->collector, $this->middlewares);
    $extension->pipe($this, $this->middlewares);
    $extension->subscribe($this->events);
  }

  public function on(
    classname<EventInterface> $event,
    EventListener $listener,
    int $priority = 0,
  ): void {
    $this->events->on($event, $listener, $priority);
  }

  /**
   * Add a service provider.
   */
  public function register(ServiceProviderInterface $service): void {
    $event = $this->events->dispatch(new Event\RegisterEvent($service)) as
      Event\RegisterEvent;

    $this->container->addServiceProvider($event->service);
  }

  /**
   * Register an event subscriber with the dispatcher.
   */
  public function subscribe(EventSubscriberInterface $subscriber): void {
    $event = $this->events->dispatch(new Event\SubscribeEvent($subscriber)) as
      Event\SubscribeEvent;

    $this->events->subscribe($event->subscriber);
  }

  /*
   * Pipe middleware like unix pipes.
   */
  public function pipe(mixed $middleware, int $priority = 0): void {
    $middleware = $this->middlewares->prepare($middleware);

    $event = $this->events
      ->dispatch(new Event\PipeEvent($middleware, $priority)) as
      Event\PipeEvent;

    $this->kernel->pipe($event->middleware, $event->priority);
  }

  public function route(
    string $path,
    mixed $middleware,
    ?C<string> $methods = null,
    ?string $name = null,
  ): RouteInterface {
    return $this->collector
      ->route($path, $this->middlewares->prepare($middleware), $methods, $name);
  }

  public function get(
    string $path,
    mixed $middleware,
    ?string $name = null,
  ): RouteInterface {
    return $this->route($path, $middleware, vec['GET'], $name);
  }

  public function post(
    string $path,
    mixed $middleware,
    ?string $name = null,
  ): RouteInterface {
    return $this->route($path, $middleware, vec['POST'], $name);
  }

  public function put(
    string $path,
    mixed $middleware,
    ?string $name = null,
  ): RouteInterface {
    return $this->route($path, $middleware, vec['PUT'], $name);
  }

  public function patch(
    string $path,
    mixed $middleware,
    ?string $name = null,
  ): RouteInterface {
    return $this->route($path, $middleware, vec['PATCH'], $name);
  }

  public function delete(
    string $path,
    mixed $middleware,
    ?string $name = null,
  ): RouteInterface {
    return $this->route($path, $middleware, vec['DELETE'], $name);
  }

  public function any(
    string $path,
    mixed $middleware,
    ?string $name = null,
  ): RouteInterface {
    return $this->route($path, $middleware, null, $name);
  }

  public function fallback(mixed $middleware): void {
    $this->pipe($middleware, -0x9950);
  }

  /**
   * Process an incoming server request and return a response, optionally delegating
   * response creation to a handler.
   */
  public function process(
    ServerRequestInterface $request,
    RequestHandlerInterface $handler,
  ): ResponseInterface {
    $event = $this->events
      ->dispatch(new Event\ProcessEvent($request, $handler)) as
      Event\ProcessEvent;

    return $this->kernel->process($event->request, $event->handler);
  }

  /**
   * Handle the request and return a response.
   */
  public function handle(ServerRequestInterface $request): ResponseInterface {
    $event = $this->events->dispatch(new Event\HandleEvent($request)) as
      Event\HandleEvent;

    return $this->kernel->handle($event->request);
  }

  /**
   * Emit a response.
   *
   * Emits a response, including status line, headers, and the message body,
   * according to the environment.
   */
  public function emit(ResponseInterface $response): bool {
    $event = $this->events->dispatch(new Event\EmitEvent($response)) as
      Event\EmitEvent;

    return $this->kernel->emit($event->response);
  }

  /**
   * Perform any final actions for the request lifecycle.
   */
  public function terminate(
    ServerRequestInterface $request,
    ResponseInterface $response,
  ): void {
    $event = $this->events
      ->dispatch(new Event\TerminateEvent($request, $response)) as
      Event\TerminateEvent;

    $this->kernel->terminate($event->request, $event->response);

    $this->reset();
  }

  public function run(): void {
    $request = ServerRequest::capture();
    $response = $this->handle($request);
    $this->emit($response);
    $this->terminate($request, $response);
  }


  /**
   * Retrieve all directly registered routes with the application.
   */
  public function getRoutes(): C<RouteInterface> {
    return $this->collector->getRoutes();
  }

  /**
   * Reset the application to its initial status.
   */
  public function reset(): void {
    $this->container->reset();
    $this->middlewares = new MiddlewareFactory($this->container);

    $this->kernel = $this->getService(KernelInterface::class);
    $this->collector = $this->getService(RouteCollectorInterface::class);
    $this->events = $this->getService(EventDispatcherInterface::class);

    foreach ($this->extensions as $extension) {
      $extension->pipe($this, $this->middlewares);
      $extension->route($this->collector, $this->middlewares);
      $extension->subscribe($this->events);
    }
  }

  private function getService<T>(classname<T> $service): T {
    /* HH_IGNORE_ERROR[4110] */
    return $this->container->get($service, true);
  }
}
