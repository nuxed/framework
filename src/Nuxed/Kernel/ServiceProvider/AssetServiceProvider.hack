namespace Nuxed\Kernel\ServiceProvider;

use namespace HH\Lib\Str;
use namespace Nuxed\Asset;
use type Nuxed\Container\Container as ServiceContainer;
use type Nuxed\Container\ServiceProvider\AbstractServiceProvider;

class AssetServiceProvider extends AbstractServiceProvider {
  const type TConfig = shape(
    ?'default' => string,
    'packages' => Container<shape(
      'name' => string,
      ?'path' => string,
      ?'urls' => Container<string>,
      ?'version_strategy' => string,
      ...
    )>,
    ?'version_strategy' => Container<shape(
      'name' => string,
      ?'version' => string,
      ?'format' => string,
      ?'manifest' => string,
      ...
    )>,
    ...
  );

  protected vec<string> $provides = vec[
    Asset\Packages::class,
  ];

  public function __construct(private this::TConfig $config) {
    parent::__construct();
  }

  <<__Override>>
  public function register(ServiceContainer $container): void {
    foreach (($this->config['version_strategy'] ?? vec[]) as $config) {
      $container->share(
        Str\format('asset.version_strategy.%s', $config['name']),
        () ==> {
          $manifest = $config['manifest'] ?? null;
          if ($manifest is nonnull) {
            return
              new Asset\VersionStrategy\JsonManifestVersionStrategy($manifest);
          }
          $version = $config['version'] ?? null;
          if ($version is nonnull) {
            return new Asset\VersionStrategy\StaticVersionStrategy(
              $version,
              $config['format'] ?? null,
            );
          }
          return new Asset\VersionStrategy\EmptyVersionStrategy();
        },
      );
    }

    foreach (($this->config['packages'] ?? vec[]) as $package) {
      $container->share(
        Str\format('asset.package.%s', $package['name']),
        () ==> {
          $vsn = $package['version_strategy'] ?? null;
          if (null === $vsn) {
            $vs = new Asset\VersionStrategy\EmptyVersionStrategy();
          } else {
            $vs = $container->get($vsn) as
              Asset\VersionStrategy\VersionStrategyInterface;
          }
          $path = $package['path'] ?? null;
          if ($path is nonnull) {
            return new Asset\PathPackage($path, $vs);
          } else {
            return new Asset\UrlPackage($package['urls'] ?? vec[], $vs);
          }
        },
      );
    }

    $container->share(Asset\Packages::class, (): Asset\Packages ==> {
      $packages = dict[];
      foreach ($this->config['packages'] as $package) {
        $packages[$package['name']] =
          $container->get(Str\format('asset.package.%s', $package['name'])) as
            Asset\PackageInterface;
      }
      $default = $this->config['default'] ?? null;
      if ($default is nonnull) {
        $default = $container->get(Str\format('asset.package.%s', $default)) as
          Asset\PackageInterface;
      } else {
        $default = null;
      }
      return new Asset\Packages($default, $packages);
    });
  }
}
