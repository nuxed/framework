namespace Nuxed\Http\Message;

use namespace His\Container;
use namespace Nuxed\Contract\Service;

final class MessageFactoryFactory
  implements Service\FactoryInterface<MessageFactory> {
  public function create(
    Container\ContainerInterface $_container,
  ): MessageFactory {
    return new MessageFactory();
  }
}
