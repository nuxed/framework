namespace Nuxed\Kernel\ServiceProvider;

use namespace Nuxed\Container;
use type SQLite3;
use const SQLITE3_OPEN_CREATE;
use const SQLITE3_OPEN_READWRITE;

class SqliteServiceProvider implements Container\ServiceProviderInterface {
  const type TConfig = shape(
    ?'filename' => string,
    ?'flags' => int,
    ?'encryption_key' => string,
    ...
  );

  public function __construct(private this::TConfig $config = shape()) {}

  public function register(Container\ContainerBuilder $builder): void {
    $builder->add(
      SQLite3::class,
      Container\factory(
        ($container) ==> new SQLite3(
          $this->config['filename'] ?? ':memory:',
          $this->config['flags'] ??
            SQLITE3_OPEN_READWRITE | SQLITE3_OPEN_CREATE,
          $this->config['encryption_key'] ?? null,
        ),
      ),
      true,
    );
  }
}
