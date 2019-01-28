<?hh // strict

namespace Nuxed\Kernel\ServiceProvider;

use namespace Nuxed\Event;
use type Nuxed\Contract\Event\EventDispatcherInterface;
use type Nuxed\Container\ServiceProvider\AbstractServiceProvider;

class EventServiceProvider extends AbstractServiceProvider {
  protected vec<string> $provides = vec[
    EventDispatcherInterface::class,
  ];

  <<__Override>>
  public function register(): void {
    $this->share(EventDispatcherInterface::class, Event\EventDispatcher::class);
  }
}
