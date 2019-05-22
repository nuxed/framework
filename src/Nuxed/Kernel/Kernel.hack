namespace Nuxed\Kernel;

use namespace Nuxed\Container;
use namespace Nuxed\Http\Message;
use namespace Nuxed\Http\Emitter;
use namespace Nuxed\Http\Server;
use namespace Nuxed\Http\Router;
use namespace Nuxed\EventDispatcher;

final class Kernel implements IKernel {
  private ?Container\IServiceContainer $container;
  private ?Emitter\IEmitter $emitter = null;
  private ?EventDispatcher\IEventDispatcher $dispatcher = null;
  private ?Server\MiddlewareStack $stack = null;
  private ?Router\IRouter $router = null;

  private vec<Extension\IExtension> $extensions = vec[];

  private bool $booted = false;

  public function use(Extension\IExtension $extension): void {
    if ($this->booted) {
      throw new Exception\BootedKernelException(
        'You cannot register more extensions. kernel has already been booted.',
      );
    }

    $this->extensions[] = $extension;
  }

  private function boot(): void {
    if ($this->booted) {
      return;
    }

    $builder = new Container\ContainerBuilder();
    foreach ($this->extensions as $extension) {
      $extension->register($builder);
    }

    $container = $builder->build();
    $dispatcher = $container->get(EventDispatcher\IEventDispatcher::class);
    $stack = $container->get(Server\MiddlewareStack::class);
    $router = $container->get(Router\IRouter::class);

    foreach ($this->extensions as $extension) {
      $extension->subscribe($dispatcher, $container);
      $extension->stack($stack, $container);
      $extension->route($router, $container);
    }

    $this->container = $container;
    $this->stack = $stack;
    $this->dispatcher = $dispatcher;
    $this->router = $router;
    $this->emitter = $this->container->get(Emitter\IEmitter::class);

    $this->booted = true;
  }

  /**
   * Process an incoming server request and return a response, optionally delegating
   * response creation to a handler.
   */
  public async function process(
    Message\ServerRequest $request,
    Server\IRequestHandler $handler,
  ): Awaitable<Message\Response> {
    $this->boot();

    $event = await ($this->dispatcher as nonnull)
      ->dispatch(new Event\ProcessEvent($request, $handler));

    return await ($this->stack as nonnull)->process(
      $event->request,
      $event->handler,
    );
  }

  /**
   * Handle the request and return a response.
   */
  public async function handle(
    Message\ServerRequest $request,
  ): Awaitable<Message\Response> {
    $this->boot();

    $event = await ($this->dispatcher as nonnull)
      ->dispatch(new Event\HandleEvent($request));

    return await ($this->stack as nonnull)->handle($event->request);
  }

  /**
   * Emit a response.
   *
   * Emits a response, including status line, headers, and the message body,
   * according to the environment.
   */
  public async function emit(Message\Response $response): Awaitable<bool> {
    $this->boot();

    $event = await ($this->dispatcher as nonnull)
      ->dispatch(new Event\EmitEvent($response));

    return await ($this->emitter as nonnull)->emit($event->response);
  }

  /**
   * Perform any final actions for the request lifecycle.
   */
  public async function terminate(
    Message\ServerRequest $request,
    Message\Response $response,
  ): Awaitable<void> {
    $event = await ($this->dispatcher as nonnull)
      ->dispatch(new Event\TerminateEvent($request, $response));

    await $event->request->getBody()->closeAsync();
    await $event->response->getBody()->closeAsync();
  }
}
