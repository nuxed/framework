namespace Nuxed\Kernel\Extension;

use namespace Nuxed\Container;

final class SqliteExtension extends AbstractExtension {
  const type TConfig = shape(
    ?'filename' => string,
    ?'flags' => int,
    ?'encryption_key' => string,
    ...
  );

  public function __construct(private this::TConfig $config = shape()) {}

  <<__Override>>
  public function register(Container\ContainerBuilder $builder): void {
    $builder->add(
      \SQLite3::class,
      Container\factory(
        ($container) ==> new \SQLite3(
          $this->config['filename'] ?? ':memory:',
          $this->config['flags'] ??
            \SQLITE3_OPEN_READWRITE | \SQLITE3_OPEN_CREATE,
          $this->config['encryption_key'] ?? null,
        ),
      ),
      true,
    );
  }
}
