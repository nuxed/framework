<?hh // strict

namespace Nuxed\Mix\ServiceProvider;

use namespace Nuxed\Contract\Log as Contract;
use namespace Nuxed\Log;

class LoggerServiceProvider extends AbstractServiceProvider {
  protected vec<string> $provides = vec[
    Contract\LoggerInterface::class,
    Log\Handler\RotatingFileHandler::class,
    Log\Handler\StreamHandler::class,
    Log\Handler\SysLogHandler::class,
    Log\Processor\ContextProcessor::class,
    Log\Processor\MessageLengthProcessor::class,
  ];

  <<__Override>>
  public function register(): void {
    $config = $this->config['log'];

    $this->share(Contract\LoggerInterface::class, () ==> {
      $handlers = vec[];
      $processors = vec[];
      foreach ($config['handlers'] as $handler) {
        $handlers[] =
          $this->getContainer()->get($handler) as Log\Handler\HandlerInterface;
      }
      foreach ($config['processors'] as $processor) {
        $processors[] = $this->getContainer()->get($processor) as
          Log\Processor\ProcessorInterface;
      }

      return new Log\Logger($handlers, $processors);
    });

    $this->share(Log\Handler\RotatingFileHandler::class, () ==> {
      $options = $config['options']['rotating-file'];
      return new Log\Handler\RotatingFileHandler(
        $options['filename'],
        $options['max-files'],
        $options['level'],
        $options['bubble'],
        $options['file-permission'],
        $options['use-lock'],
      );
    });
    $this->share(Log\Handler\StreamHandler::class, () ==> {
      $options = $config['options']['stream'];
      return new Log\Handler\StreamHandler(
        $options['url'],
        $options['level'],
        $options['bubble'],
        $options['file-permission'],
        $options['use-lock'],
      );
    });
    $this->share(Log\Handler\SysLogHandler::class, () ==> {
      $options = $config['options']['syslog'];
      return new Log\Handler\SysLogHandler(
        $options['ident'],
        $options['facility'],
        $options['level'],
        $options['bubble'],
        $options['options'],
      );
    });

    $this->share(Log\Processor\MessageLengthProcessor::class);
    $this->share(Log\Processor\ContextProcessor::class);
  }
}
