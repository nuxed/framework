namespace Nuxed\Http\Router\Matcher;

use namespace Nuxed\Cache;
use namespace Nuxed\Container;
use namespace Nuxed\Http\Router;

final class RequestMatcherFactory
  implements Container\IFactory<IRequestMatcher> {
  public function create(
    Container\IServiceContainer $container,
  ): IRequestMatcher {
    $cache = $container->has(Cache\ICache::class)
      ? $container->get(Cache\ICache::class)
      : null;

    return new RequestMatcher(
      $container->get(Router\IRouteCollector::class),
      $cache,
    );
  }
}
