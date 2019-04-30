namespace Nuxed\Http\Router\_Private;

use namespace HH\Lib\Vec;
use namespace HH\Lib\Dict;
use namespace Facebook\HackRouter;
use namespace Nuxed\Contract\Http\Router;

function map(
  Container<Router\RouteInterface> $routes,
): KeyedContainer<
  HackRouter\HttpMethod,
  HackRouter\PrefixMatching\PrefixMap<Router\RouteInterface>,
> {
  $result = new Ref(dict[]);
  Vec\map($routes, ($route) ==> {
    $methods = $route->getAllowedMethods();
    if ($methods is null) {
      $methods = HackRouter\HttpMethod::getValues();
    } else {
      $methods = HackRouter\HttpMethod::assertAll($methods);
    }

    Vec\map($methods, ($method) ==> {
      $result->value[$method] ??= dict[];
      $result->value[$method][$route->getPath()] = $route;
    });
  });

  return Dict\map(
    $result->value,
    ($map) ==> HackRouter\PrefixMatching\PrefixMap::fromFlatMap($map),
  );
}
