<?hh // strict

namespace Nuxed\Mix\Event;

use type Nuxed\Contract\Event\EventInterface;
use type Nuxed\Contract\Event\EventSubscriberInterface;

class SubscribeEvent implements EventInterface {
  public function __construct(public EventSubscriberInterface $subscriber) {}
}
