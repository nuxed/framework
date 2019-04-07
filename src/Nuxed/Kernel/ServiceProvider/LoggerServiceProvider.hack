namespace Nuxed\Kernel\ServiceProvider;

use namespace HH\Lib\Vec;
use namespace Nuxed\Contract\Log as Contract;
use namespace Nuxed\Log;
use namespace Nuxed\Container;
use function sys_get_temp_dir;
use const LOG_PID;

class LoggerServiceProvider implements Container\ServiceProviderInterface {
  const type TConfig = shape(
    #───────────────────────────────────────────────────────────────────────#
    # Log Handlers                                                          #
    #───────────────────────────────────────────────────────────────────────#
    # You may define as much log handlers as you want here.                 #
    #───────────────────────────────────────────────────────────────────────#
    ?'handlers' => Container<classname<Log\Handler\HandlerInterface>>,

    #───────────────────────────────────────────────────────────────────────#
    # Log Processors                                                        #
    #───────────────────────────────────────────────────────────────────────#
    # Log processors process the log record before passing it to the        #
    # handlers, allowing you to add extra information to the record.        #
    #───────────────────────────────────────────────────────────────────────#
    ?'processors' => Container<classname<Log\Processor\ProcessorInterface>>,

    #───────────────────────────────────────────────────────────────────────#
    # Handlers Options                                                      #
    #───────────────────────────────────────────────────────────────────────#
    # Here we define the options for all the log handlers.                  #
    #───────────────────────────────────────────────────────────────────────#
    ?'options' => shape(
      ?'syslog' => shape(
        ?'ident' => string,
        ?'facility' => Log\Handler\SysLogFacility,
        ?'level' => Contract\LogLevel,
        ?'bubble' => bool,
        ?'options' => int,
        ?'formatter' => classname<Log\Formatter\FormatterInterface>,
        ...
      ),
      ?'rotating-file' => shape(
        ?'filename' => string,
        ?'max-files' => int,
        ?'level' => Contract\LogLevel,
        ?'bubble' => bool,
        ?'file-permission' => ?int,
        ?'use-lock' => bool,
        ?'formatter' => classname<Log\Formatter\FormatterInterface>,
        ...
      ),
      ?'stream' => shape(
        ?'url' => string,
        ?'level' => Contract\LogLevel,
        ?'bubble' => bool,
        ?'file-permission' => ?int,
        ?'use-lock' => bool,
        ?'formatter' => classname<Log\Formatter\FormatterInterface>,
        ...
      ),
      ...
    ),
    ...
  );

  public function __construct(private this::TConfig $config = shape()) {
  }

  public function register(Container\ContainerBuilder $builder): void {
    $builder->add(
      Contract\LoggerInterface::class,
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
            $options['filename'] ?? sys_get_temp_dir().'/nuxed.log',
            $options['max-files'] ?? 0,
            $options['level'] ?? Contract\LogLevel::INFO,
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
            $options['url'] ?? sys_get_temp_dir().'/nuxed.log',
            $options['level'] ?? Contract\LogLevel::INFO,
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
            $options['level'] ?? Contract\LogLevel::INFO,
            $options['bubble'] ?? true,
            $options['options'] ?? LOG_PID,
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
}
