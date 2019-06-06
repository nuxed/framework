namespace Nuxed\Http\Router;

use namespace Nuxed\Container;

final class RouterServiceProvider implements Container\IServiceProvider {
  public function register(Container\ContainerBuilder $builder): void {
    $builder->add(IRouter::class, new RouterFactory(), true);
    $builder->add(IRouteCollector::class, new RouteCollectorFactory(), true);
    $builder->add(
      Matcher\IRequestMatcher::class,
      new Matcher\RequestMatcherFactory(),
      true,
    );
    $builder->add(
      Generator\IUriGenerator::class,
      new Generator\UriGeneratorFactory(),
      true,
    );
    $builder->add(
      Middleware\DispatchMiddleware::class,
      new Middleware\DispatchMiddlewareFactory(),
      true,
    );
    $builder->add(
      Middleware\ImplicitHeadMiddleware::class,
      new Middleware\ImplicitHeadMiddlewareFactory(),
      true,
    );
    $builder->add(
      Middleware\ImplicitOptionsMiddleware::class,
      new Middleware\ImplicitOptionsMiddlewareFactory(),
      true,
    );
    $builder->add(
      Middleware\MethodNotAllowedMiddleware::class,
      new Middleware\MethodNotAllowedMiddlewareFactory(),
      true,
    );
    $builder->add(
      Middleware\RouteMiddleware::class,
      new Middleware\RouteMiddlewareFactory(),
      true,
    );
  }
}
