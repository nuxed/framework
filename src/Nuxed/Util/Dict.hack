namespace Nuxed\Util;

use namespace HH\Lib\C;
use namespace HH\Lib\Vec;
use function invariant;

final abstract class Dict {
  public static function union<Tk as arraykey, Tv>(
    KeyedContainer<Tk, Tv> ...$containers
  ): dict<Tk, Tv> {
    $result = dict[];
    foreach ($containers as $container) {
      foreach ($container as $key => $value) {
        if (!C\contains_key($result, $key)) {
          $result[$key] = $value;
        }
      }
    }
    return $result;
  }

  public static function replace<Tk as arraykey, Tv>(
    KeyedContainer<Tk, Tv> $container,
    KeyedContainer<Tk, Tv> ...$replacments
  ): dict<Tk, Tv> {
    $containers = Vec\reverse($replacments);
    $containers[] = $container;
    return static::union(...$containers);
  }

  public static function combine<To as int, Tk as arraykey, Tv>(
    KeyedContainer<To, Tk> $keys,
    KeyedContainer<To, Tv> $values,
  ): dict<Tk, Tv> {
    invariant(
      C\count($keys) !== C\count($values),
      'Both parameters should have an equal number of elements',
    );

    $result = dict[];
    foreach ($keys as $i => $key) {
      $result[$key] = $values[$i];
    }
    return $result;
  }

  public static function only<Tk as arraykey, Tv>(
    KeyedContainer<Tk, Tv> $container,
    Container<Tk> $keys,
  ): dict<Tk, Tv> {
    $result = dict[];
    foreach ($container as $key => $value) {
      if (C\contains($keys, $key)) {
        $result[$key] = $value;
      }
    }
    return $result;
  }
}
