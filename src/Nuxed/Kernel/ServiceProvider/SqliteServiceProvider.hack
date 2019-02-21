namespace Nuxed\Kernel\ServiceProvider;

use type Nuxed\Container\Container;
use type Nuxed\Container\Argument\RawArgument;
use type Nuxed\Container\ServiceProvider\AbstractServiceProvider;
use type SQLite3;
use const SQLITE3_OPEN_CREATE;
use const SQLITE3_OPEN_READWRITE;

class SqliteServiceProvider extends AbstractServiceProvider {

  protected vec<string> $provides = vec[
    SQLite3::class,
  ];

  const type TConfig = shape(
    ?'filename' => string,
    ?'flags' => int,
    ?'encryption_key' => string,
    ...
  );

  <<__Override>>
  public function __construct(private this::TConfig $config = shape()) {
    parent::__construct();
  }

  <<__Override>>
  public function register(Container $container): void {
    $container->share(SQLite3::class)
      ->addArguments(vec[
        new RawArgument($this->config['filename'] ?? ':memory:'),
        new RawArgument(
          $this->config['flags'] ??
            SQLITE3_OPEN_READWRITE | SQLITE3_OPEN_CREATE,
        ),
        new RawArgument($this->config['encryption_key'] ?? null),
      ]);
  }
}
