namespace Nuxed\Kernel\ServiceProvider;

use type Nuxed\Container\Argument\RawArgument;
use type SQLite3;

class SqliteServiceProvider extends AbstractServiceProvider {

  protected vec<string> $provides = vec[
    SQLite3::class,
  ];

  <<__Override>>
  public function register(): void {
    $config = $this->config()['services']['sqlite'];

    $this->share(SQLite3::class)
      ->addArguments(vec[
        new RawArgument($config['filename']),
        new RawArgument($config['flags']),
        new RawArgument($config['encryption_key']),
      ]);
  }
}
