namespace Nuxed\Http\Flash;

use namespace His\Container;
use namespace Nuxed\Contract\Service;

final class FlashMessagesMiddlewareFactory
  implements Service\FactoryInterface<FlashMessagesMiddleware> {
  public function __construct(
    private string $key = FlashMessages::FLASH_NEXT,
  ) {}

  public function create(
    Container\ContainerInterface $_container,
  ): FlashMessagesMiddleware {
    return new FlashMessagesMiddleware($this->key);
  }
}
