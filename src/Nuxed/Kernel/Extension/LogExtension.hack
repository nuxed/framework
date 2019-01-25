namespace Nuxed\Kernel\Extension;

use namespace Nuxed\Kernel\ServiceProvider;
use type Nuxed\Container\ServiceProvider\ServiceProviderInterface;
use type Nuxed\Contract\Event\EventDispatcherInterface;
use type Nuxed\Kernel\Configuration;
use type Nuxed\Kernel\Event\TerminateEvent;
use type Nuxed\Contract\Log\LoggerInterface;
use type Nuxed\Log\Logger;

class LogExtension extends AbstractExtension {
  <<__Override>>
  public function services(
    Configuration $_configuration,
  ): Container<ServiceProviderInterface> {
    return vec[
      new ServiceProvider\LoggerServiceProvider(),
    ];
  }

  <<__Override>>
  public function subscribe(EventDispatcherInterface $events): void {
    $events->on(TerminateEvent::class, ($event): void ==> {
      /**
       * Close Logger after sending the response.
       */
      if ($this->getContainer()->has(LoggerInterface::class)) {
        $logger =
          $this->getContainer()->get(LoggerInterface::class) as LoggerInterface;
        if ($logger is Logger) {
          $logger->debug('closing logger instance.');
          $logger->close();
        }
      }
    });
  }
}
