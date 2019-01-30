namespace Nuxed\Kernel\ServiceProvider;

use namespace HH\Asio;
use type Nuxed\Container\Container;
use type Nuxed\Container\Argument\RawArgument;
use type Nuxed\Container\ServiceProvider\AbstractServiceProvider;
use type AsyncMysqlConnectionPool;
use type AsyncMysqlConnection;

class MysqlServiceProvider extends AbstractServiceProvider {
  protected vec<string> $provides = vec[
    AsyncMysqlConnection::class,
    AsyncMysqlConnectionPool::class,
  ];

  <<__Override>>
  public function __construct(
    private shape(
      ?'pool' => shape(
        ?'per_key_connection_limit' => int,
        ?'pool_connection_limit' => int,
        ?'idle_timeout_micros' => int,
        ?'age_timeout_micros' => int,
        ?'expiration_policy' => string,
        ...
      ),
      ?'host' => string,
      ?'port' => int,
      ?'database' => string,
      ?'username' => string,
      ?'password' => string,
      ?'timeout-micros' => int,
      ?'extra-key' => string,
      ...
    ) $config = shape(),
  ) {
    parent::__construct();
  }

  <<__Override>>
  public function register(Container $container): void {
    $container->share(AsyncMysqlConnectionPool::class)
      ->addArgument(
        new RawArgument(Shapes::idx($this->config, 'pool', shape())),
      );

    $container->add(
      AsyncMysqlConnection::class,
      () ==> {
        $pool = $container
          ->get(AsyncMysqlConnectionPool::class) as AsyncMysqlConnectionPool;

        return Asio\join(
          $pool->connect(
            $this->config['host'] ?? '127.0.0.1',
            $this->config['port'] ?? 3306,
            $this->config['database'] ?? 'nuxed',
            $this->config['username'] ?? 'nuxed',
            $this->config['password'] ?? '',
            $this->config['timeout-micros'] ?? -1,
            $this->config['extra-key'] ?? '',
          ),
        );
      },
      false,
    );
  }
}
