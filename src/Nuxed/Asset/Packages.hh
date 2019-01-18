<?hh // strict

namespace Nuxed\Asset;

use namespace HH\Lib\C;
use namespace HH\Lib\Str;
use type Nuxed\Asset\Exception\InvalidArgumentException;
use type Nuxed\Asset\Exception\LogicException;

class Packages {
  private dict<string, PackageInterface> $packages;

  /**
   * @param PackageInterface   $defaultPackage The default package
   * @param PackageInterface[] $packages       Additional packages indexed by name
   */
  public function __construct(
    private ?PackageInterface $defaultPackage = null,
    KeyedContainer<string, PackageInterface> $packages = dict[],
  ) {
    $this->packages = dict($packages);
  }

  public function setDefaultPackage(PackageInterface $defaultPackage): void {
    $this->defaultPackage = $defaultPackage;
  }

  /**
   * Adds a  package.
   *
   * @param string           $name    The package name
   * @param PackageInterface $package The package
   */
  public function addPackage(string $name, PackageInterface $package): void {
    $this->packages[$name] = $package;
  }

  /**
   * Returns an asset package.
   *
   * @param string $name The name of the package or null for the default package
   *
   * @return PackageInterface An asset package
   *
   * @throws InvalidArgumentException If there is no package by that name
   * @throws LogicException           If no default package is defined
   */
  public function getPackage(?string $name = null): PackageInterface {
    if (null === $name) {
      if (null === $this->defaultPackage) {
        throw new LogicException(
          'There is no default asset package, configure one first.',
        );
      }

      return $this->defaultPackage;
    }

    if (C\contains($this->packages, $name)) {
      return $this->packages[$name];
    } else {
      throw new InvalidArgumentException(
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
