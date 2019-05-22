namespace Nuxed\Http\Flash;

use namespace Nuxed\Container;
use namespace Nuxed\Contract;

final class FlashMessagesMiddlewareFactory
  implements Container\IFactory<FlashMessagesMiddleware> {
  public function __construct(
    private string $key = FlashMessages::FLASH_NEXT,
  ) {}

  public function create(
    Container\IServiceContainer $_container,
  ): FlashMessagesMiddleware {
    return new FlashMessagesMiddleware($this->key);
  }
}
