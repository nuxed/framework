namespace Nuxed\Http\Router;

use namespace Nuxed\Container;

final class RouterFactory implements Container\IFactory<IRouter> {
  public function create(Container\IServiceContainer $container): Router {
    return new Router(
      $container->get(Matcher\IRequestMatcher::class),
      $container->get(Generator\IUriGenerator::class),
    );
  }
}
