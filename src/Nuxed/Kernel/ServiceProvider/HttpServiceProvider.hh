<?hh // strict

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
    Http\Server\MiddlewareFactory::class,
    RouterInterface::class,
    RouteCollectorInterface::class,
    Http\Router\Middleware\DispatchMiddleware::class,
    Http\Router\Middleware\ImplicitHeadMiddleware::class,
    Http\Router\Middleware\ImplicitOptionsMiddleware::class,
    Http\Router\Middleware\MethodNotAllowedMiddleware::class,
    Http\Router\Middleware\RouteMiddleware::class,
  ];

  <<__Override>>
  public function register(): void {
    // Emitter
    $this->registerEmitter();
    // Messages
    $this->registerMessagesFactories();
    // Server
    $this->registerServer();
    // Router
    $this->registerRouter();
  }

  private function registerEmitter(): void {
    $this->share(EmitterInterface::class, Http\Emitter\Emitter::class);
  }

  private function registerMessagesFactories(): void {
    $this->share(ResponseFactoryInterface::class, Http\Message\Factory::class);
    $this->share(RequestFactoryInterface::class, Http\Message\Factory::class);
    $this->share(
      ServerRequestFactoryInterface::class,
      Http\Message\Factory::class,
    );
    $this->share(StreamFactoryInterface::class, Http\Message\Factory::class);
    $this->share(
      UploadedFileFactoryInterface::class,
      Http\Message\Factory::class,
    );
    $this->share(CookieFactoryInterface::class, Http\Message\Factory::class);
    $this->share(UriFactoryInterface::class, Http\Message\Factory::class);
  }

  private function registerServer(): void {
    $this->share(
      MiddlewarePipeInterface::class,
      Http\Server\MiddlewarePipe::class,
    );

    $this->share(
      Http\Server\MiddlewareFactory::class,
      () ==> new Http\Server\MiddlewareFactory($this->container),
    );
  }

  private function registerRouter(): void {
    $this->share(RouterInterface::class, Http\Router\Router::class);
    $this
      ->share(RouteCollectorInterface::class, Http\Router\RouteCollector::class)
      ->addArgument(RouterInterface::class);

    $this->share(Http\Router\Middleware\DispatchMiddleware::class);
    $this->share(Http\Router\Middleware\ImplicitHeadMiddleware::class)
      ->addArgument(RouterInterface::class)
      ->addArgument(StreamFactoryInterface::class);
    $this->share(Http\Router\Middleware\ImplicitOptionsMiddleware::class)
      ->addArgument(ResponseFactoryInterface::class);
    $this->share(Http\Router\Middleware\MethodNotAllowedMiddleware::class)
      ->addArgument(ResponseFactoryInterface::class);
    $this->share(Http\Router\Middleware\RouteMiddleware::class)
      ->addArgument(RouterInterface::class);
  }
}
