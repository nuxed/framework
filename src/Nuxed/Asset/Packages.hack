namespace Nuxed\Asset;

use namespace HH\Lib\{C, Str};

class Packages implements IPackage {
  private dict<string, IPackage> $packages;

  /**
   * @param IPackage                          $defaultPackage
   *                                                    The default package
   * @param KeyedContainer<string, IPackage>  $packages
   *                                                    Additional packages indexed by name
   */
  public function __construct(
    private ?IPackage $defaultPackage = null,
    KeyedContainer<string, IPackage> $packages = dict[],
  ) {
    $this->packages = dict($packages);
  }

  public function setDefaultPackage(IPackage $defaultPackage): void {
    $this->defaultPackage = $defaultPackage;
  }

  /**
   * Adds a  package.
   *
   * @param string           $name    The package name
   * @param IPackage $package The package
   */
  public function addPackage(string $name, IPackage $package): void {
    $this->packages[$name] = $package;
  }

  /**
   * Returns an asset package.
   *
   * @param string $name The name of the package or null for the default package
   *
   * @return IPackage An asset package
   *
   * @throws InvalidArgumentException If there is no package by that name
   * @throws LogicException           If no default package is defined
   */
  public function getPackage(?string $name = null): IPackage {
    if (null === $name) {
      if (null === $this->defaultPackage) {
        throw new Exception\LogicException(
          'There is no default asset package, configure one first.',
        );
      }

      return $this->defaultPackage;
    }

    if (C\contains_key($this->packages, $name)) {
      return $this->packages[$name];
    } else {
      throw new Exception\InvalidArgumentException(
        Str\format('There is no "%s" asset package.', $name),
      );
    }
  }

  /**
   * Gets the version to add to public URL.
   *
   * @param string $path        A public path
   * @param string $packageName A package name
   *
   * @return string The current version
   */
  public function getVersion(
    string $path,
    ?string $packageName = null,
  ): string {
    return $this->getPackage($packageName)->getVersion($path);
  }

  /**
   * Returns the public path.
   *
   * Absolute paths (i.e. http://...) are returned unmodified.
   *
   * @param string $path        A public path
   * @param string $packageName The name of the asset package to use
   *
   * @return string A public path which takes into account the base path and URL path
   */
  public function getUrl(string $path, ?string $packageName = null): string {
    return $this->getPackage($packageName)->getUrl($path);
  }
}
