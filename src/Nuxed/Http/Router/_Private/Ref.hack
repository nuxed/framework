namespace Nuxed\Http\Router\_Private;

use namespace HH\Lib\Vec;
use namespace Facebook\HackRouter;
use namespace Nuxed\Contract\Http\Server;
use namespace Nuxed\Contract\Http\Router;

final class Ref<T> {
  public function __construct(
    public T $value
  ) {}
}
