namespace Nuxed\Kernel\ServiceProvider;

use namespace HH\Asio;
use type Nuxed\Container\Argument\RawArgument;
use type AsyncMysqlConnectionPool;
use type AsyncMysqlConnection;

class MysqlServiceProvider extends AbstractServiceProvider {
  protected vec<string> $provides = vec[
    AsyncMysqlConnection::class,
    AsyncMysqlConnectionPool::class,
  ];

  <<__Override>>
  public function register(): void {
    $config = $this->config()['services']['mysql'];

    $this->share(AsyncMysqlConnectionPool::class)
      ->addArgument(new RawArgument($config['pool']));

    $this->add(
      AsyncMysqlConnection::class,
      () ==> {
        $pool = $this->getContainer()
          ->get(AsyncMysqlConnectionPool::class) as AsyncMysqlConnectionPool;

        return Asio\join(
          $pool->connect(
            $config['host'],
            $config['port'],
            $config['database'],
            $config['username'],
            $config['password'],
            $config['timeout-micros'],
            $config['extra-key'],
          ),
        );
      },
      false,
    );
  }
}
