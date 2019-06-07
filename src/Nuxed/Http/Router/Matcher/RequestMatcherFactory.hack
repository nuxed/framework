namespace Nuxed\Http\Router\Matcher;

use namespace Nuxed\Container;
use namespace Nuxed\Http\Router;

final class RequestMatcherFactory
  implements Container\IFactory<IRequestMatcher> {
  public function create(
    Container\IServiceContainer $container,
  ): IRequestMatcher {
    return new RequestMatcher(
      $container->get(Router\IRouteCollector::class),
    );
  }
}
