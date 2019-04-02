namespace Nuxed\Kernel\ServiceProvider;

use namespace Nuxed\Http;
use type Nuxed\Container\ServiceProvider\AbstractServiceProvider;
use type Nuxed\Contract\Http\Emitter\EmitterInterface;
use type Nuxed\Contract\Http\Message\ResponseFactoryInterface;
use type Nuxed\Contract\Http\Message\RequestFactoryInterface;
use type Nuxed\Contract\Http\Message\ServerRequestFactoryInterface;
use type Nuxed\Contract\Http\Message\StreamFactoryInterface;
use type Nuxed\Contract\Http\Message\UploadedFileFactoryInterface;
use type Nuxed\Contract\Http\Message\CookieFactoryInterface;
use type Nuxed\Contract\Http\Message\UriFactoryInterface;
use type Nuxed\Contract\Http\Server\MiddlewarePipeInterface;
use type Nuxed\Contract\Http\Router\RouterInterface;
use type Nuxed\Contract\Http\Router\RouteCollectorInterface;
use type Nuxed\Container\Container;

class HttpServiceProvider extends AbstractServiceProvider {
  protected vec<string> $provides = vec[
    EmitterInterface::class,
    ResponseFactoryInterface::class,
    RequestFactoryInterface::class,
    ServerRequestFactoryInterface::class,
    StreamFactoryInterface::class,
    UploadedFileFactoryInterface::class,
    CookieFactoryInterface::class,
    UriFactoryInterface::class,
    MiddlewarePipeInterface::class,
    RouterInterface::class,
    RouteCollectorInterface::class,
    Http\Router\Middleware\DispatchMiddleware::class,
    Http\Router\Middleware\ImplicitHeadMiddleware::class,
    Http\Router\Middleware\ImplicitOptionsMiddleware::class,
    Http\Router\Middleware\MethodNotAllowedMiddleware::class,
    Http\Router\Middleware\RouteMiddleware::class,
  ];

  <<__Override>>
  public function register(Container $container): void {
    // Emitter
    $container->share(EmitterInterface::class, Http\Emitter\Emitter::class);
    // Messages
    $container->share(
      ResponseFactoryInterface::class,
      Http\Message\Factory::class,
    );
    $container->share(
      RequestFactoryInterface::class,
      Http\Message\Factory::class,
    );
    $container->share(
      ServerRequestFactoryInterface::class,
      Http\Message\Factory::class,
    );
    $container->share(
      StreamFactoryInterface::class,
      Http\Message\Factory::class,
    );
    $container->share(
      UploadedFileFactoryInterface::class,
      Http\Message\Factory::class,
    );
    $container->share(
      CookieFactoryInterface::class,
      Http\Message\Factory::class,
    );
    $container->share(UriFactoryInterface::class, Http\Message\Factory::class);
    // Server
    $container->share(
      MiddlewarePipeInterface::class,
      Http\Server\MiddlewarePipe::class,
    );
    // Router
    $container->share(RouterInterface::class, Http\Router\Router::class);
    $container
      ->share(RouteCollectorInterface::class, Http\Router\RouteCollector::class)
      ->addArgument(RouterInterface::class);
    $container->share(Http\Router\Middleware\DispatchMiddleware::class);
    $container->share(Http\Router\Middleware\ImplicitHeadMiddleware::class)
      ->addArgument(RouterInterface::class)
      ->addArgument(StreamFactoryInterface::class);
    $container->share(Http\Router\Middleware\ImplicitOptionsMiddleware::class)
      ->addArgument(ResponseFactoryInterface::class);
    $container->share(Http\Router\Middleware\MethodNotAllowedMiddleware::class)
      ->addArgument(ResponseFactoryInterface::class);
    $container->share(Http\Router\Middleware\RouteMiddleware::class)
      ->addArgument(RouterInterface::class);
  }
}
