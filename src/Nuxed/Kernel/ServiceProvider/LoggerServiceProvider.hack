namespace Nuxed\Kernel\ServiceProvider;

use namespace HH\Lib\Vec;
use namespace Nuxed\Contract\Log as Contract;
use namespace Nuxed\Log;
use type Nuxed\Container\Container as ServiceContainer;
use type Nuxed\Container\ServiceProvider\AbstractServiceProvider;
use function sys_get_temp_dir;
use const LOG_PID;

class LoggerServiceProvider extends AbstractServiceProvider {
  protected vec<string> $provides = vec[
    Contract\LoggerInterface::class,
    Log\Handler\RotatingFileHandler::class,
    Log\Handler\StreamHandler::class,
    Log\Handler\SysLogHandler::class,
    Log\Processor\ContextProcessor::class,
    Log\Processor\MessageLengthProcessor::class,
  ];

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

  <<__Override>>
  public function __construct(private this::TConfig $config = shape()) {
    parent::__construct();
  }

  <<__Override>>
  public function register(ServiceContainer $container): void {
    $container->share(Contract\LoggerInterface::class, () ==> {
      $handlers = Vec\map(
        Shapes::idx(
          $this->config,
          'handlers',
          vec[
            Log\Handler\SysLogHandler::class,
          ],
        ),
        (classname<Log\Handler\HandlerInterface> $class) ==>
          $container->get($class) as Log\Handler\HandlerInterface,
      );
      $processors = Vec\map(
        Shapes::idx(
          $this->config,
          'processors',
          vec[
            Log\Processor\ContextProcessor::class,
          ],
        ),
        (classname<Log\Processor\ProcessorInterface> $class) ==> $container
          ->get($class) as Log\Processor\ProcessorInterface,
      );
      return new Log\Logger($handlers, $processors);
    });

    $options = Shapes::idx($this->config, 'options', shape());
    $container->share(Log\Handler\RotatingFileHandler::class, () ==> {
      $options = Shapes::idx($options, 'rotating-file', shape());
      return new Log\Handler\RotatingFileHandler(
        $options['filename'] ?? sys_get_temp_dir().'/nuxed.log',
        $options['max-files'] ?? 0,
        $options['level'] ?? Contract\LogLevel::INFO,
        $options['bubble'] ?? true,
        $options['file-permission'] ?? null,
        $options['use-lock'] ?? false,
      );
    });
    $container->share(Log\Handler\StreamHandler::class, () ==> {
      $options = Shapes::idx($options, 'stream', shape());
      return new Log\Handler\StreamHandler(
        $options['url'] ?? sys_get_temp_dir().'/nuxed.log',
        $options['level'] ?? Contract\LogLevel::INFO,
        $options['bubble'] ?? true,
        $options['file-permission'] ?? null,
        $options['use-lock'] ?? false,
      );
    });
    $container->share(Log\Handler\SysLogHandler::class, () ==> {
      $options = Shapes::idx($options, 'syslog', shape());
      return new Log\Handler\SysLogHandler(
        $options['ident'] ?? 'nuxed',
        $options['facility'] ?? Log\Handler\SysLogFacility::USER,
        $options['level'] ?? Contract\LogLevel::INFO,
        $options['bubble'] ?? true,
        $options['options'] ?? LOG_PID,
      );
    });
    $container->share(Log\Processor\MessageLengthProcessor::class);
    $container->share(Log\Processor\ContextProcessor::class);
  }
}
