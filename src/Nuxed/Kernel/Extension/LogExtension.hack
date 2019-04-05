namespace Nuxed\Kernel\Extension;

use type Nuxed\Contract\Event\EventDispatcherInterface;
use type Nuxed\Kernel\Event\TerminateEvent;
use type Nuxed\Contract\Log\LoggerInterface;
use type Nuxed\Log\Logger;

class LogExtension extends AbstractExtension {
  <<__Override>>
  public function subscribe(EventDispatcherInterface $events): void {
    $events->on(TerminateEvent::class, async ($event) ==> {
      /**
       * Close Logger after sending the response.
       */
      if ($this->container->has(LoggerInterface::class)) {
        $logger = $this->container->get(LoggerInterface::class);

        if ($logger is Logger) {
          $logger->debug('closing logger instance.');
          $logger->close();
        }
      }
    });
  }
}
