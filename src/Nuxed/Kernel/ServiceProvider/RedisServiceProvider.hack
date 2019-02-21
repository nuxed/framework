namespace Nuxed\Kernel\ServiceProvider;

use type Nuxed\Container\Container;
use type Nuxed\Container\ServiceProvider\AbstractServiceProvider;
use type Redis;

class RedisServiceProvider extends AbstractServiceProvider {
  protected vec<string> $provides = vec[
    Redis::class,
  ];

  const type TConfig = shape(
    ?'host' => string,
    ?'port' => int,
    ?'database' => int,
    ?'password' => string,
    ?'timeout' => int,
    ...
  );

  <<__Override>>
  public function __construct(private this::TConfig $config = shape()) {
    parent::__construct();
  }

  <<__Override>>
  public function register(Container $container): void {
    $container->share(Redis::class, () ==> {
      $client = new Redis();
      $client->connect(
        $this->config['host'] ?? '127.0.0.1',
        $this->config['port'] ?? 6379,
        $this->config['timeout'] ?? 0,
      );

      $pw = $this->config['password'] ?? null;
      $db = $this->config['database'] ?? null;
      if ($pw is nonnull) {
        $client->auth($pw);
      }
      if ($db is nonnull) {
        $client->select($db);
      }

      return $client;
    });
  }
}
