<?hh // strict

namespace Nuxed\Util;

use namespace HH\Lib\C;
use namespace HH\Lib\Vec;

final abstract class Recursive {
  public static function union<Tk as arraykey, Tv>(
    KeyedContainer<Tk, Tv> ...$containers
  ): dict<Tk, Tv> {
    $result = dict[];
    foreach ($containers as $container) {
      foreach ($container as $key => $value) {
        if (!C\contains_key($result, $key)) {
          $result[$key] = $value;
        } else {
          $first = $result[$key];
          if (
            $first is KeyedContainer<_, _> && $value is KeyedContainer<_, _>
          ) {
            /* HH_IGNORE_ERROR[4110] */
            $result[$key] = static::union($first, $value);
          }
        }
      }
    }
    /* HH_IGNORE_ERROR[4110] */
    return $result;
  }

  /**
   * Merge one or more containers recursively
   */
  public static function merge<Tk as arraykey, Tv>(
    KeyedContainer<Tk, Tv> ...$containers
  ): dict<Tk, Tv> {
    $result = dict[];
    foreach ($containers as $container) {
      foreach ($container as $key => $value) {
        $first = idx($result, $key);
        if ($first is KeyedContainer<_, _> && $value is KeyedContainer<_, _>) {
          /* HH_IGNORE_ERROR[4110] */
          $result[$key] = static::merge($first, $value);
        } else {
          $result[$key] = $value;
        }
      }
    }

    /* HH_IGNORE_ERROR[4110] */
    return $result;
  }

  /**
   * Replaces elements from passed container into the first continer recursively
   * @link https://secure.php.net/manual/en/function.array-replace-recursive.php
   */
  public static function replace<Tk as arraykey, Tv>(
    KeyedContainer<Tk, Tv> $container,
    KeyedContainer<Tk, Tv> ...$replacments
  ): dict<Tk, Tv> {
    $containers = Vec\reverse($replacments);
    $containers[] = $container;
    return static::union(...$containers);
  }
}
