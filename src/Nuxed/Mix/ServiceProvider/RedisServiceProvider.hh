<?hh // strict

namespace Nuxed\Mix\ServiceProvider;

use type Redis;

class RedisServiceProvider extends AbstractServiceProvider {
  protected vec<string> $provides = vec[
    Redis::class,
  ];

  <<__Override>>
  public function register(): void {
    $this->share(Redis::class, () ==> {
      $config = $this->config['services']['redis'];
      $client = new Redis();
      $client->connect($config['host'], $config['port'], $config['timeout']);
      if ($config['password'] is nonnull) {
        $client->auth($config['password']);
      }
      if ($config['database'] is nonnull) {
        $client->select($config['database']);
      }
      return $client;
    });
  }
}
