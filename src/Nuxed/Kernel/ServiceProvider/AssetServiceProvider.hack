namespace Nuxed\Kernel\ServiceProvider;

use namespace Nuxed\Io;
use namespace Nuxed\Asset;
use namespace Nuxed\Container;

class AssetServiceProvider implements Container\ServiceProviderInterface {
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

  public function __construct(private this::TConfig $config) {}

  public function register(Container\ContainerBuilder $builder): void {
    $builder->add(
      Asset\Packages::class,
      Container\factory(
        ($_) ==> {
          $startegies = dict[];
          foreach (
            ($this->config['version_strategy'] ?? vec[]) as $versionStartegy
          ) {
            $manifest = $versionStartegy['manifest'] ?? null;

            if ($manifest is nonnull) {
              $startegies[$versionStartegy['name']] =
                new Asset\VersionStrategy\JsonManifestVersionStrategy(
                  new Io\File(Io\Path::create($manifest)),
                );
            } else {
              $version = $versionStartegy['version'] ?? null;

              if ($version is nonnull) {
                $startegies[$versionStartegy['name']] =
                  new Asset\VersionStrategy\StaticVersionStrategy(
                    $version,
                    $versionStartegy['format'] ?? null,
                  );
              } else {
                $startegies[$versionStartegy['name']] =
                  new Asset\VersionStrategy\EmptyVersionStrategy();
              }
            }
          }

          $packages = dict[];
          foreach ($this->config['packages'] as $package) {
            $versionStartegy = $package['version_strategy'] ?? null;

            if ($versionStartegy is nonnull) {
              $versionStartegy = $startegies[$versionStartegy];
            } else {
              $versionStartegy =
                new Asset\VersionStrategy\EmptyVersionStrategy();
            }

            $path = $package['path'] ?? null;

            if ($path is nonnull) {
              $packages[$package['name']] = new Asset\PathPackage(
                $path,
                $versionStartegy,
              );
            } else {
              $packages[$package['name']] = new Asset\UrlPackage(
                $package['urls'] ?? vec[],
                $versionStartegy,
              );
            }
          }

          $default = $this->config['default'] ?? null;
          if ($default is nonnull) {
            $default = $packages[$default];
          } else {
            $default = null;
          }

          return new Asset\Packages($default, $packages);
        },
      ),
      true,
    );
  }
}
