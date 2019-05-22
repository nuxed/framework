namespace Nuxed\Kernel\Extension;

use namespace Nuxed\Container;

final class RedisExtension extends AbstractExtension {
  const type TConfig = shape(
    ?'host' => string,
    ?'port' => int,
    ?'database' => int,
    ?'password' => string,
    ?'timeout' => int,
    ...
  );

  public function __construct(private this::TConfig $config = shape()) {}

  <<__Override>>
  public function register(Container\ContainerBuilder $builder): void {
    $builder->add(
      \Redis::class,
      Container\factory(($container) ==> {
        $client = new \Redis();
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
      }),
      true,
    );
  }
}
