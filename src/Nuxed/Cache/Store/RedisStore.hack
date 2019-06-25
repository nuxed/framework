namespace Nuxed\Cache\Store;

use namespace HH\Asio;
use namespace HH\Lib\{C, Str, Vec};
use namespace Nuxed\Cache\{Exception, Serializer};

class RedisStore extends AbstractStore {
  public function __construct(
    protected \Redis $redis,
    string $namespace = '',
    int $defaultTtl = 0,
    protected Serializer\ISerializer $serializer = new Serializer\DefaultSerializer(),
  ) {
    $redis->ping();
    if (\preg_match('#[^-+_.A-Za-z0-9]#', $namespace)) {
      throw new Exception\InvalidArgumentException(
        'RedisStore namespace cannot contain any characters other than [-+_.A-Za-z0-9].',
      );
    }
    parent::__construct($namespace, $defaultTtl);
  }

  <<__Override>>
  protected async function doGet(string $id): Awaitable<dynamic> {
    $exists = await $this->doContains($id);
    if (!$exists) {
      return null;
    }

    return $this->serializer->unserialize((string)$this->redis->get($id));
  }

  <<__Override>>
  protected async function doDelete(string $id): Awaitable<bool> {
    return (bool)$this->redis->del($id);
  }

  <<__Override>>
  protected async function doContains(string $id): Awaitable<bool> {
    return (bool)$this->redis->exists($id);
  }

  <<__Override>>
  protected async function doStore(
    string $id,
    mixed $value,
    int $ttl = 0,
  ): Awaitable<bool> {
    $value = $this->serializer->serialize($value);

    if (0 >= $ttl) {
      return (bool)$this->redis->set($id, $value);
    } else {
      return (bool)$this->redis->setex($id, $ttl, $value);
    }
  }

  <<__Override>>
  protected async function doClear(string $namespace): Awaitable<bool> {
    if (Str\is_empty($namespace)) {
      return $this->redis->flushDB();
    }

    $info = $this->redis->info('Server');
    $info = C\contains_key($info, 'Server') ? $info['Server'] : $info;

    if (!\version_compare($info['redis_version'], '2.8', '>=')) {
      // As documented in Redis documentation (http://redis.io/commands/keys) using KEYS
      // can hang your server when it is executed against large databases (millions of items).
      // Whenever you hit this scale, you should really consider upgrading to Redis 2.8 or above.
      return (bool)$this->redis->evaluate(
        "local keys=redis.call('KEYS',ARGV[1]..'*') for i=1,#keys,5000 do redis.call('DEL',unpack(keys,i,math.min(i+4999,#keys))) end return 1",
        vec[$namespace],
        0,
      );
    }

    $keys = vec[];
    $cursor = null;
    do {
      $scanned = $this->redis->scan(&$cursor, $namespace.'*', 1000);
      if (C\contains_key($scanned, 1) && $scanned[1] is Traversable<_>) {
        $cursor = (int)$scanned[0];
        $keys = Vec\concat($keys, $scanned[1]);
      }
    } while ($cursor is nonnull && $cursor > 0);

    $keys = Vec\unique($keys);
    $cleared = true;
    if (!C\is_empty($keys)) {
      $wrappers = await Asio\vmw($keys, ($key) ==> {
        return $this->doDelete((string)$key);
      });
      foreach ($wrappers as $wrapper) {
        $cleared = $cleared && $wrapper->getResult();
      }
    }

    return $cleared;
  }
}
