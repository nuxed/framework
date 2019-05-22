namespace Nuxed\Kernel\Extension;

use namespace HH\Asio;
use namespace Nuxed\Container;

final class AsyncMysqlExtension extends AbstractExtension {
  const type TConfig = shape(
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
  );

  public function __construct(private this::TConfig $config = shape()) {}

  <<__Override>>
  public function register(Container\ContainerBuilder $builder): void {
    $builder->add(
      \AsyncMysqlConnectionPool::class,
      Container\factory(
        ($container) ==> {
          $config = Shapes::idx($this->config, 'pool', shape());
          return new \AsyncMysqlConnectionPool(darray[
            'per_key_connection_limit' =>
              $config['per_key_connection_limit'] ?? 50,
            'pool_connection_limit' => $config['pool_connection_limit'] ?? 5000,
            'idle_timeout_micros' => $config['idle_timeout_micros'] ?? 4000000,
            'age_timeout_micros' => $config['age_timeout_micros'] ?? 60000000,
            'expiration_policy' => $config['expiration_policy'] ?? 'Age',
          ]);
        },
      ),
      true,
    );

    $builder->add(
      \AsyncMysqlConnection::class,
      Container\factory(($container) ==> {
        $pool = $container->get(\AsyncMysqlConnectionPool::class);
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
      }),
      false,
    );
  }
}
