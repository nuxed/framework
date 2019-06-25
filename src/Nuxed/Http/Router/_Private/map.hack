namespace Nuxed\Http\Router\_Private;

use namespace HH\Lib\{Dict, Vec};
use namespace Facebook\HackRouter;
use namespace Nuxed\Http\Router;

function map(
  Container<Router\Route> $routes,
): KeyedContainer<
  HackRouter\HttpMethod,
  HackRouter\PrefixMatching\PrefixMap<Router\Route>,
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
