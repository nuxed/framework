<?hh // strict

namespace Nuxed\Io;

use namespace HH\Lib\C;
use namespace HH\Lib\Vec;
use namespace HH\Lib\Str;
use type Nuxed\Io\Exception\InvalidArgumentException;
use function preg_match;
use function pathinfo;
use function realpath;
use const PATHINFO_BASENAME;
use const PATHINFO_FILENAME;
use const PATHINFO_EXTENSION;
use const PATH_SEPARATOR;
use const DIRECTORY_SEPARATOR;

/**
 * Provides convenience functions for inflecting notation paths, namespace paths and file system paths.
 */
class Path {

  /**
   * Directory separator.
   */
  const string SEPARATOR = DIRECTORY_SEPARATOR;

  /**
   * Include path separator.
   */
  const string DELIMITER = PATH_SEPARATOR;

  /**
   * Return the extension from a file path.
   */
  public static function extension(string $path): string {
    return Str\lowercase(pathinfo($path, PATHINFO_EXTENSION));
  }

  /**
   * Verify a path is absolute by checking the first path part.
   */
  public static function isAbsolute(string $path): bool {
    return (
      Str\starts_with($path, '/') ||
      Str\starts_with($path, '\\') ||
      preg_match('/^[a-zA-Z0-9]+:/', $path)
    );
  }

  /**
   * Verify a path is relative.
   */
  public static function isRelative(string $path): bool {
    return !static::isAbsolute($path);
  }

  /**
   * Join all path parts and return a normalized path.
   *
   * @param bool $above - Go above the root path if .. is used
   */
  public static function join(
    Container<string> $paths,
    bool $above = true,
  ): string {
    $clean = vec[];
    $parts = vec[];
    $up = 0;

    // First pass expands sub-paths
    foreach ($paths as $path) {
      $path = Str\trim($path, '/');

      if (Str\contains($path, '/')) {
        $clean = Vec\concat($clean, Str\split($path, '/'));
      } else {
        $clean[] = $path;
      }
    }

    foreach ($clean as $path) {
      if ($path === '.' || $path === '') {
        continue;
      } elseif ($path === '..') {
        $up++;
      } elseif ($up) {
        $up--;
      } else {
        $parts[] = $path;
      }
    }

    if ($above) {
      while ($up) {
        $parts[] = '..';
        $up--;
      }
    }

    return Str\join($parts, '/');
  }

  /**
   * Normalize a string by resolving "." and "..". When multiple slashes are found, they're replaced by a single one;
   * when the path contains a trailing slash, it is preserved. On Windows backslashes are used.
   */
  public static function normalize(string $path): string {
    return realpath($path);
  }

  /**
   * Determine the relative path between two absolute paths.
   *
   * @throws InvalidArgumentException
   */
  public static function relativeTo(string $from, string $to): string {
    if (static::isRelative($from) || static::isRelative($to)) {
      throw new InvalidArgumentException(
        'Cannot determine relative path without two absolute paths',
      );
    }

    $from = Str\split(static::normalize($from), '/');
    $to = Str\split(static::normalize($to), '/');
    $relative = $to;

    foreach ($from as $depth => $dir) {
      // Find first non-matching dir and ignore it
      if ($dir === $to[$depth]) {
        $relative = Vec\slice($relative, 1);

        // Get count of remaining dirs to $from
      } else {
        $remaining = C\count($from) - $depth;

        // Add traversals up to first matching dir
        if ($remaining > 1) {
          $padLength = (C\count($relative) + $remaining - 1) * -1;
          $relative = Vec\drop(
            Vec\concat($relative, Vec\fill($padLength, '..')),
            $padLength,
          );
          break;
        } else {
          $relative[0] = './'.$relative[0];
        }
      }
    }

    if (!$relative) {
      return './';
    }

    return Str\join($relative, '/');
  }

  /**
   * Strip off the extension if it exists.
   */
  public static function stripExt(string $path): string {
    if (Str\contains($path, '.')) {
      $path = Str\slice($path, 0, Str\search($path, '.'));
    }

    return $path;
  }
}
