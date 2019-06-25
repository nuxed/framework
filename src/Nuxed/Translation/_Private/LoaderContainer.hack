namespace Nuxed\Translation\_Private;

use namespace HH\Lib\{C, Str};
use namespace Nuxed\Translation\{Exception, Loader};

final class LoaderContainer {
  private dict<string, mixed> $loaders = dict[];

  public function getLoader<T>(
    classname<Loader\ILoader<T>> $format,
  ): Loader\ILoader<T> {
    if (!C\contains_key($this->loaders, $format)) {
      throw new Exception\RuntimeException(
        Str\format('The "%s" translation loader is not registered.', $format),
      );
    }

    /* HH_IGNORE_ERROR[4110] */
    return $this->loaders[$format];
  }

  public function addLoader<T>(
    classname<Loader\ILoader<T>> $format,
    Loader\ILoader<T> $loader,
  ): void {
    $this->loaders[$format] = $loader;
  }
}
