namespace Nuxed\Io;

use namespace HH\Lib\C;
use namespace HH\Lib\Vec;
use namespace HH\Lib\Str;
use namespace HH\Lib\Experimental\Filesystem;
use type Nuxed\Io\Exception\InvalidArgumentException;
use function realpath;
use const PATHINFO_BASENAME;
use const PATHINFO_FILENAME;
use const PATHINFO_EXTENSION;
use const PATH_SEPARATOR;
use const DIRECTORY_SEPARATOR;

/**
 * Provides convenience functions for inflecting notation paths and file system paths.
 */
final class Path {
  /**
   * Directory separator.
   */
  const string SEPARATOR = DIRECTORY_SEPARATOR;

  /**
   * Include path separator.
   */
  const string DELIMITER = PATH_SEPARATOR;

  public function __construct(private Filesystem\Path $path) {
  }

  public static function create(string $path): Path {
    return new self(new Filesystem\Path(static::normalize($path)));
  }

  public function toString(): string {
    return $this->path->toString();
  }

  public function __toString(): string {
    return $this->toString();
  }

  /**
   * Return the extension from a file path.
   */
  public function extension(): ?string {
    return $this->path->getExtension();
  }

  /**
   * Verify a path is absolute by checking the first path part.
   */
  public function isAbsolute(): bool {
    return $this->path->isAbsolute();
  }

  /**
   * Verify a path is relative.
   */
  public function isRelative(): bool {
    return $this->path->isRelative();
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
   *
   * if the path couldn't be normalized, null will be returned.
   */
  public static function normalize(string $path): ?string {
    $normalized = realpath($path);
    if ($normalized is string) {
      return $normalized;
    }

    return null;
  }

  /**
   * Determine the relative path between this and another absolute path.
   *
   * @throws InvalidArgumentException
   */
  public function relativeTo(Path $to): Path {
    if ($this->isRelative() || $to->isRelative()) {
      throw new InvalidArgumentException(
        'Cannot determine relative path without two absolute paths',
      );
    }

    $from = Str\split($this->toString(), '/');
    $to = Str\split($to->toString(), '/');
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
      return self::create('./');
    }

    return self::create(Str\join($relative, '/'));
  }

  public function isDirectory(): bool {
    return $this->path->isDirectory();
  }

  public function isFile(): bool {
    return $this->path->isFile();
  }

  public function isSymlink(): bool {
    return $this->path->isSymlink();
  }

  public function exists(): bool {
    return $this->path->exists();
  }

  public function parent(): Path {
    return new self($this->path->getParent());
  }

  public function basename(): string {
    return $this->path->getBaseName();
  }

  public function parts(): Container<string> {
    return $this->path->getParts();
  }
}
