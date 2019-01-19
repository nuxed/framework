<?hh // strict

namespace Nuxed\Http\Server\Middleware;

use type Nuxed\Contract\Http\Message\ResponseInterface;
use type Nuxed\Contract\Http\Message\ServerRequestInterface;
use type Nuxed\Contract\Http\Server\MiddlewareInterface;
use type Nuxed\Contract\Http\Server\RequestHandlerInterface;
use type Nuxed\Contract\Container\ContainerInterface;
use type Nuxed\Http\Server\MiddlewareFactory;

class LazyMiddlewareDecorator implements MiddlewareInterface {
  public function __construct(
    private ContainerInterface $container,
    private MiddlewareFactory $factory,
    private mixed $middleware,
  ) {}

  public async function process(
    ServerRequestInterface $request,
    RequestHandlerInterface $handler,
  ): Awaitable<ResponseInterface> {
    if (
      $this->middleware is string && $this->container->has($this->middleware)
    ) {
      $this->middleware = $this->container->get($this->middleware as string);
    }
    return await $this->factory
      ->prepare($this->middleware)
      ->process($request, $handler);
  }
}
