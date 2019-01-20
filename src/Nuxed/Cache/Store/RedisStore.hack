namespace Nuxed\Cache\Store;

use namespace HH\Lib\C;
use namespace HH\Lib\Str;
use type Nuxed\Cache\Serializer\SerializerInterface;
use type Nuxed\Cache\Serializer\DefaultSerializer;
use type Nuxed\Cache\Exception\InvalidArgumentException;
use type Redis;
use function version_compare;
use function preg_match;

class RedisStore extends Store {
  public function __construct(
    protected Redis $redis,
    string $namespace = '',
    num $defaultTtl = 0,
    protected SerializerInterface $serializer = new DefaultSerializer(),
  ) {
    $redis->ping();
    if (preg_match('#[^-+_.A-Za-z0-9]#', $namespace)) {
      throw new InvalidArgumentException(
        'RedisStore namespace cannot contain any characters other than [-+_.A-Za-z0-9].',
      );
    }
    parent::__construct($namespace, $defaultTtl);
  }

  <<__Override>>
  public function doGet(string $id): mixed {
    if (!$this->doContains($id)) {
      return null;
    }

    return $this->serializer->unserialize((string)$this->redis->get($id));
  }

  <<__Override>>
  public function doDelete(string $id): bool {
    return (bool)$this->redis->del($id);
  }

  <<__Override>>
  public function doContains(string $id): bool {
    return (bool)$this->redis->exists($id);
  }

  <<__Override>>
  public function doStore(string $id, mixed $value, num $ttl = 0): bool {
    $value = $this->serializer->serialize($value);

    if (0 >= $ttl) {
      return (bool)$this->redis->set($id, $value);
    } else {
      return (bool)$this->redis->setex($id, $ttl, $value);
    }
  }

  <<__Override>>
  public function doClear(string $namespace): bool {
    if (Str\is_empty($namespace)) {
      return $this->redis->flushDB();
    }

    $info = $this->redis->info('Server');
    $info = C\contains_key($info, 'Server') ? $info['Server'] : $info;

    if (!version_compare($info['redis_version'], '2.8', '>=')) {
      // As documented in Redis documentation (http://redis.io/commands/keys) using KEYS
      // can hang your server when it is executed against large databases (millions of items).
      // Whenever you hit this scale, you should really consider upgrading to Redis 2.8 or above.
      return (bool)$this->redis->evaluate(
        "local keys=redis.call('KEYS',ARGV[1]..'*') for i=1,#keys,5000 do redis.call('DEL',unpack(keys,i,math.min(i+4999,#keys))) end return 1",
        [$namespace],
        0,
      );
    }

    $cleared = true;
    $cursor = null;
    do {
      $keys = $this->redis->scan(&$cursor, $namespace.'*', 1000);
      if (C\contains_key($keys, 1) && $keys[1] is Container<_>) {
        $cursor = $keys[0];
        $keys = $keys[1];
      }

      if (!C\is_empty($keys)) {
        foreach ($keys as $key) {
          $cleared = $this->doDelete((string)$key) && $cleared;
        }
      }
    } while ($cursor = (int)$cursor);

    return $cleared;
  }
}
