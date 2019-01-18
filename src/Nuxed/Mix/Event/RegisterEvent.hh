<?hh // strict

namespace Nuxed\Mix\Event;

use type Nuxed\Contract\Event\EventInterface;
use type Nuxed\Container\ServiceProvider\ServiceProviderInterface;

class RegisterEvent implements EventInterface {
  public function __construct(public ServiceProviderInterface $service) {}
}
