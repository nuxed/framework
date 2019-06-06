namespace Nuxed\Http\Router\Generator;

use namespace Nuxed\Container;
use namespace Nuxed\Http\Router;

final class UriGeneratorFactory implements Container\IFactory<IUriGenerator> {
  public function create(
    Container\IServiceContainer $container
  ): IUriGenerator {
    return new UriGenerator(
      $container->get(Router\IRouteCollector::class)
    );
  }
}