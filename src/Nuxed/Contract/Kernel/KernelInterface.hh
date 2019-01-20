<?hh // strict

namespace Nuxed\Contract\Kernel;

use type Nuxed\Contract\Http\Server\MiddlewareInterface;
use type Nuxed\Contract\Http\Server\MiddlewarePipeInterface;
use type Nuxed\Contract\Http\Emitter\EmitterInterface;
use type Nuxed\Contract\Http\Message\ServerRequestInterface;
use type Nuxed\Contract\Http\Message\ResponseInterface;
use type Nuxed\Contract\Http\Router\RouteCollectorInterface;
use type Nuxed\Contract\Log\LoggerAwareInterface;
use type Nuxed\Contract\Event\EventSubscriberInterface;
use type Nuxed\Contract\Event\EventInterface;
use type Nuxed\Contract\Event\EventListener;

interface KernelInterface
  extends
    MiddlewarePipeInterface,
    EmitterInterface,
    RouteCollectorInterface,
    LoggerAwareInterface {

  /**
   * Register an event listener with the kernel.
   */
  public function on(
    classname<EventInterface> $event,
    EventListener $listener,
    int $priority = 0,
  ): void;

  /**
   * Register an event subscriber with the kernel.
   */
  public function subscribe(EventSubscriberInterface $subscriber): void;

  /**
   * Register fallback middleware.
   *
   * this middleware MUST be called in case there's no match route.
   */
  public function fallback(MiddlewareInterface $middleware): void;

  /**
   * Perform any final actions for the request lifecycle.
   */
  public function terminate(
    ServerRequestInterface $request,
    ResponseInterface $response,
  ): Awaitable<void>;

  /**
   * Run the Http Kernel.
   *
   * the method usually does the following :
   *   - create a server request based on the environment.
   *   - handle the request
   *   - emit the response
   *   - terminate the request lifecycle.
   *   - exit with the correct status code.
   *
   * example :
   * <code>
   *   $request = createServerRequestBasedOnTheEnvironment();
   *   $response = await $this->handle($request);
   *   $emitted = await $this->emit($response);
   *   if ($emitted) {
   *      await $this->terminate($request, $response);
   *      exit(0);
   *    } else {
   *      // log error or throw an exception.
   *      exit(1);
   *    }
   * </code>
   */
  public function run(): Awaitable<noreturn>;
}
