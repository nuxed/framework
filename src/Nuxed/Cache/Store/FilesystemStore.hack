namespace Nuxed\Cache\Store;

use namespace Nuxed\Io;
use namespace HH\Lib\Str;
use namespace Nuxed\Cache\Serializer;

class FilesystemStore extends AbstractStore {
  const FILE_SUFFIX = '.nu.cache';
  protected Io\Folder $folder;

  public function __construct(
    string $cache_dir,
    string $namespace = '',
    int $defaultTtl = 0,
    protected Serializer\ISerializer $serializer =
      new Serializer\NativeSerializer(),
  ) {
    $this->folder = new Io\Folder($cache_dir, true);
    parent::__construct($namespace, $defaultTtl);
  }

  <<__Override>>
  protected async function doStore(
    string $id,
    mixed $value,
    int $ttl = 0,
  ): Awaitable<bool> {
    $name = $this->getFilename($id);
    $val = $this->serializer->serialize(tuple($value, $ttl));
    if ($val is null) {
      return false;
    }

    if ($this->folder->contains($name)) {
      $file = await $this->folder->read($name, Io\File::class);
    } else {
      $file = await $this->folder->touch($name);
    }

    await $file->write($val);
    return true;
  }

  <<__Override>>
  protected async function doContains(string $id): Awaitable<bool> {
    $name = $this->getFilename($id);
    if (!$this->folder->contains($name)) {
      return false;
    }

    $time = \time();
    $file = await $this->folder->read($name, Io\File::class);
    $cache = $this->serializer->unserialize(await $file->read()) as
      (dynamic, int);
    $expiry = $cache[1];
    if (0 === $expiry) {
      return true;
    }
    $mdt = $file->modifyTime() + $expiry;
    $expired = $mdt <= $time;

    if ($expired) {
      await $file->delete();
    }

    return !$expired;
  }

  <<__Override>>
  protected async function doDelete(string $id): Awaitable<bool> {
    $id = $this->getFilename($id);
    $file = await $this->folder->read($id, Io\File::class);
    await $file->delete();
    return true;
  }

  <<__Override>>
  protected async function doGet(string $id): Awaitable<dynamic> {
    if (!await $this->doContains($id)) {
      return null;
    }
    $id = $this->getFilename($id);
    $file = await $this->folder->read($id, Io\File::class);
    $cache = $this->serializer->unserialize(await $file->read()) as
      (dynamic, int);
    return $cache[0];
  }

  <<__Override>>
  protected async function doClear(string $namespace): Awaitable<bool> {
    if (Str\is_empty($namespace)) {
      await $this->folder->flush();
      return true;
    }
    if (!$this->folder->contains($namespace)) {
      return true;
    }
    $cache = await $this->folder->read($namespace, Io\Folder::class);
    await $cache->flush();
    return true;
  }

  protected function getFilename(string $id): string {
    return Str\format(
      '%s%s',
      $this->namespace === '' ? '' : Str\format('%s/', $this->namespace),
      \sha1($id).static::FILE_SUFFIX,
    );
  }
}
