namespace Nuxed\Kernel\Extension;

use namespace Nuxed\{Container, EventDispatcher, Log};
use namespace HH\Lib\Vec;
use namespace Nuxed\Kernel\Event;

final class LogExtension extends AbstractExtension {
  const type TConfig = shape(
    #───────────────────────────────────────────────────────────────────────#
    # Log Handlers                                                          #
    #───────────────────────────────────────────────────────────────────────#
    # You may define as much log handlers as you want here.                 #
    #───────────────────────────────────────────────────────────────────────#
    ?'handlers' => Container<classname<Log\Handler\IHandler>>,

    #───────────────────────────────────────────────────────────────────────#
    # Log Processors                                                        #
    #───────────────────────────────────────────────────────────────────────#
    # Log processors process the log record before passing it to the        #
    # handlers, allowing you to add extra information to the record.        #
    #───────────────────────────────────────────────────────────────────────#
    ?'processors' => Container<classname<Log\Processor\IProcessor>>,

    #───────────────────────────────────────────────────────────────────────#
    # Handlers Options                                                      #
    #───────────────────────────────────────────────────────────────────────#
    # Here we define the options for all the log handlers.                  #
    #───────────────────────────────────────────────────────────────────────#
    ?'options' => shape(
      ?'syslog' => shape(
        ?'ident' => string,
        ?'facility' => Log\Handler\SysLogFacility,
        ?'level' => Log\LogLevel,
        ?'bubble' => bool,
        ?'options' => int,
        ?'formatter' => classname<Log\Formatter\IFormatter>,
        ...
      ),
      ?'rotating-file' => shape(
        ?'filename' => string,
        ?'max-files' => int,
        ?'level' => Log\LogLevel,
        ?'bubble' => bool,
        ?'file-permission' => ?int,
        ?'use-lock' => bool,
        ?'formatter' => classname<Log\Formatter\IFormatter>,
        ...
      ),
      ?'stream' => shape(
        ?'url' => string,
        ?'level' => Log\LogLevel,
        ?'bubble' => bool,
        ?'file-permission' => ?int,
        ?'use-lock' => bool,
        ?'formatter' => classname<Log\Formatter\IFormatter>,
        ...
      ),
      ...
    ),
    ...
  );

  public function __construct(private this::TConfig $config = shape()) {
  }

  <<__Override>>
  public function register(Container\ContainerBuilder $builder): void {
    $builder->add(
      Log\ILogger::class,
      Container\factory(
        ($container) ==> new Log\Logger(
          Vec\map(
            Shapes::idx(
              $this->config,
              'handlers',
              vec[Log\Handler\SysLogHandler::class],
            ),
            ($handler) ==> $container->get($handler),
          ),
          Vec\map(
            Shapes::idx(
              $this->config,
              'processors',
              vec[Log\Processor\ContextProcessor::class],
            ),
            ($processor) ==> $container->get($processor),
          ),
        ),
      ),
      true,
    );

    $options = Shapes::idx($this->config, 'options', shape());

    $builder->add(
      Log\Handler\RotatingFileHandler::class,
      Container\factory(
        ($container) ==> {
          $options = Shapes::idx($options, 'rotating-file', shape());
          return new Log\Handler\RotatingFileHandler(
            $options['filename'] ?? \sys_get_temp_dir().'/nuxed.log',
            $options['max-files'] ?? 0,
            $options['level'] ?? Log\LogLevel::INFO,
            $options['bubble'] ?? true,
            $options['file-permission'] ?? null,
            $options['use-lock'] ?? false,
          );
        },
      ),
      true,
    );

    $builder->add(
      Log\Handler\StreamHandler::class,
      Container\factory(
        ($container) ==> {
          $options = Shapes::idx($options, 'stream', shape());
          return new Log\Handler\StreamHandler(
            $options['url'] ?? \sys_get_temp_dir().'/nuxed.log',
            $options['level'] ?? Log\LogLevel::INFO,
            $options['bubble'] ?? true,
            $options['file-permission'] ?? null,
            $options['use-lock'] ?? false,
          );
        },
      ),
      true,
    );

    $builder->add(
      Log\Handler\SysLogHandler::class,
      Container\factory(
        ($container) ==> {
          $options = Shapes::idx($options, 'syslog', shape());
          return new Log\Handler\SysLogHandler(
            $options['ident'] ?? 'nuxed',
            $options['facility'] ?? Log\Handler\SysLogFacility::USER,
            $options['level'] ?? Log\LogLevel::INFO,
            $options['bubble'] ?? true,
            $options['options'] ?? \LOG_PID,
          );
        },
      ),
      true,
    );

    $builder->add(
      Log\Processor\MessageLengthProcessor::class,
      Container\factory(
        ($container) ==> new Log\Processor\MessageLengthProcessor(),
      ),
      true,
    );

    $builder->add(
      Log\Processor\ContextProcessor::class,
      Container\factory(($container) ==> new Log\Processor\ContextProcessor()),
      true,
    );
  }

  <<__Override>>
  public function subscribe(
    EventDispatcher\IEventDispatcher $events,
    Container\IServiceContainer $container,
  ): void {
    $events->on(Event\TerminateEvent::class, async ($event) ==> {
      /**
       * Close Logger after sending the response.
       */
      if ($container->has(Log\ILogger::class)) {
        $logger = $container->get(Log\ILogger::class);

        if ($logger is Log\Logger) {
          $logger->debug('closing logger instance.');
          $logger->close();
        }
      }
    });
  }
}
