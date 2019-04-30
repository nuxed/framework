namespace Nuxed\Kernel\ServiceProvider;

use namespace Nuxed\Http;
use namespace Nuxed\Container;
use namespace Nuxed\Contract\Http\Server;
use namespace Nuxed\Contract\Http\Emitter;
use namespace Nuxed\Contract\Http\Message;
use type Nuxed\Contract\Http\Router\RouterInterface;
use type Nuxed\Contract\Http\Router\RouteCollectorInterface;

class HttpServiceProvider implements Container\ServiceProviderInterface {
  public function register(Container\ContainerBuilder $builder): void {
    $builder->add(
      Emitter\EmitterInterface::class,
      new Http\Emitter\EmitterFactory(),
      true,
    );

    $builder->add(
      Http\Message\MessageFactory::class,
      new Http\Message\MessageFactoryFactory(),
      true,
    );

    $builder->add(
      Message\ResponseFactoryInterface::class,
      Container\factory(
        ($container) ==> $container->get(Http\Message\MessageFactory::class),
      ),
      true,
    );

    $builder->add(
      Message\RequestFactoryInterface::class,
      Container\factory(
        ($container) ==> $container->get(Http\Message\MessageFactory::class),
      ),
      true,
    );

    $builder->add(
      Message\ServerRequestFactoryInterface::class,
      Container\factory(
        ($container) ==> $container->get(Http\Message\MessageFactory::class),
      ),
      true,
    );

    $builder->add(
      Message\StreamFactoryInterface::class,
      Container\factory(
        ($container) ==> $container->get(Http\Message\MessageFactory::class),
      ),
      true,
    );

    $builder->add(
      Message\UploadedFileFactoryInterface::class,
      Container\factory(
        ($container) ==> $container->get(Http\Message\MessageFactory::class),
      ),
      true,
    );

    $builder->add(
      Message\CookieFactoryInterface::class,
      Container\factory(
        ($container) ==> $container->get(Http\Message\MessageFactory::class),
      ),
      true,
    );

    $builder->add(
      Message\UriFactoryInterface::class,
      Container\factory(
        ($container) ==> $container->get(Http\Message\MessageFactory::class),
      ),
      true,
    );

    $builder->add(
      Server\MiddlewarePipeInterface::class,
      new Http\Server\MiddlewarePipeFactory(),
      true,
    );

    $builder->add(
      RouterInterface::class,
      new Http\Router\RouterFactory(),
      true,
    );

    $builder->add(
      Http\Router\Middleware\DispatchMiddleware::class,
      new Http\Router\Middleware\DispatchMiddlewareFactory(),
      true,
    );

    $builder->add(
      Http\Router\Middleware\ImplicitHeadMiddleware::class,
      new Http\Router\Middleware\ImplicitHeadMiddlewareFactory(),
      true,
    );

    $builder->add(
      Http\Router\Middleware\ImplicitOptionsMiddleware::class,
      new Http\Router\Middleware\ImplicitOptionsMiddlewareFactory(),
      true,
    );

    $builder->add(
      Http\Router\Middleware\MethodNotAllowedMiddleware::class,
      new Http\Router\Middleware\MethodNotAllowedMiddlewareFactory(),
      true,
    );

    $builder->add(
      Http\Router\Middleware\RouteMiddleware::class,
      new Http\Router\Middleware\RouteMiddlewareFactory(),
      true,
    );
  }
}
