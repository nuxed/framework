# The Nuxed Asset Component

>Nuxed/Asset is a Hack implementation of [Symfony/Asset](https://github.com/symfony/asset)

---

>The Asset component manages URL generation and versioning of web assets such as CSS stylesheets, JavaScript files and image files.

In the past, it was common for web applications to hardcode URLs of web assets. For example:

```html
<link rel="stylesheet" type="text/css" href="/css/main.css">

<!-- ... -->

<a href="/"><img src="/images/logo.png"></a>
```

This practice is no longer recommended unless the web application is extremely simple. Hardcoding URLs can be a disadvantage because:

- *Templates get verbose*: you have to write the full path for each asset. When using the Asset component, you can group assets in packages to avoid repeating the common part of their path;
- *Versioning is difficult*: it has to be custom managed for each application. Adding a version (e.g. `main.css?v=5`) to the asset URLs is essential for some applications because it allows you to control how the assets are cached. The Asset component allows you to define different versioning strategies for each package;
- *Moving assets location is cumbersome and error-prone*: it requires you to carefully update the URLs of all assets included in all templates. The Asset component allows to move assets effortlessly just by changing the base path value associated with the package of assets;
- *It's nearly impossible to use multiple CDNs*: this technique requires you to change the URL of the asset randomly for each request. The Asset component provides out-of-the-box support for any number of multiple CDNs, both regular (`http://`) and secure (`https://`).

---

## Installation

```console
➜ composer require nuxed/asset
```

Alternatively, you can clone the [https://github.com/nuxed/asset](https://github.com/nuxed/asset) repository.

## Usage

### Asset Packages

The Asset component manages assets through packages. A package groups all the assets which share the same properties: versioning strategy, base path, CDN hosts, etc. In the following basic example, a package is created to manage assets without any versioning:

```hack
use type Nuxed\Asset\Package;
use type Nuxed\Asset\VersionStrategy\EmptyVersionStrategy;

$package = new Package(new EmptyVersionStrategy());

// Absolute path
print $package->getUrl('/image.png');
// result: /image.png

// Relative path
print $package->getUrl('image.png');
// result: image.png
```

Packages implement `PackageInterface`, which defines the following two methods:

`public function getVersion(string $path): string;`
   Returns the asset version for an asset.

`public function getUrl(string $path): string;`
   Returns an absolute or root-relative public path.

With a package, you can:

1. version the assets;
2. set a common base path (e.g. `/css`) for the assets;
3. configure a CDN for the assets;

### Verionsed Assets

One of the main features of the Asset component is the ability to manage the versioning of the application's assets. Asset versions are commonly used to control how these assets are cached.

nstead of relying on a simple version mechanism, the Asset component allows you to define advanced versioning strategies via PHP classes. The two built-in strategies are the `EmptyVersionStrategy`, which doesn't add any version to the asset and `StaticVersionStrategy`, which allows you to set the version with a format string.

In this example, the `StaticVersionStrategy` is used to append the `v1` suffix to any asset path:

```hack
use type Nuxed\Asset\Package;
use type Nuxed\Asset\VersionStrategy\StaticVersionStrategy;

$package = new Package(new StaticVersionStrategy('v1'));

// Absolute path
print $package->getUrl('/image.png');
// result: /image.png?v1

// Relative path
print $package->getUrl('image.png');
// result: image.png?v1
```

In case you want to modify the version format, pass a literal format string as the second argument of the `StaticVersionStrategy` constructor:

```hack
// puts the 'version' word before the version value
$package = new Package(new StaticVersionStrategy('v1', '%s?version=%s'));

print $package->getUrl('/image.png');
// result: /image.png?version=v1

// puts the asset version before its path
$package = new Package(new StaticVersionStrategy('v1', '%2$s/%1$s'));

print $package->getUrl('/image.png');
// result: /v1/image.png

print $package->getUrl('image.png');
// result: v1/image.png
```

### Json File Manifest

A popular strategy to manage asset versioning, which is used by tools such as [Webpack](https://webpack.js.org/), is to generate a JSON file mapping all source file names to their corresponding output file:

```json
// rev-manifest.json
{
    "css/app.css": "build/css/app.b916426ea1d10021f3f17ce8031f93c2.css",
    "js/app.js": "build/js/app.13630905267b809161e71d0f8a0c017b.js",
    "...": "..."
}
```

In those cases, use the `JsonManifestVersionStrategy`:

```hack
use type Nuxed\Asset\Package;
use type Nuxed\Asset\VersionStrategy\JsonManifestVersionStrategy;

$package = new Package(new JsonManifestVersionStrategy('/path/to/rev-manifest.json'));

print $package->getUrl('css/app.css');
// result: build/css/app.b916426ea1d10021f3f17ce8031f93c2.css
```

Use the `VersionStrategyInterface` to define your own versioning strategy. For example, your application may need to append the current date to all its web assets in order to bust the cache every day:

```hack
use namespace HH\Lib\Str;
use type Nuxed\Asset\VersionStrategy\VersionStrategyInterface;
use function date;

class DateVersionStrategy implements VersionStrategyInterface
{
    private string $version;

    public function __construct()
    {
        $this->version = date('Ymd');
    }

    public function getVersion(string $path): string
    {
        return $this->version;
    }

    public function applyVersion(string $path): string
    {
        return Str\format('%s?v=%s', $path, $this->getVersion($path));
    }
}
```

### Grouped Assets

Often, many assets live under a common path (e.g. `/static/images`). If that's your case, replace the default `Package` class with `PathPackage` to avoid repeating that path over and over again:

```hack
use type Nuxed\Asset\PathPackage;
// ...

$pathPackage = new PathPackage('/static/images', new StaticVersionStrategy('v1'));

print $pathPackage->getUrl('logo.png');
// result: /static/images/logo.png?v1

// Base path is ignored when using absolute paths
print $pathPackage->getUrl('/logo.png');
// result: /logo.png?v1
```

### Absolute Assets and CDNs

Applications that host their assets on different domains and CDNs (Content Delivery Networks) should use the `UrlPackage` class to generate absolute URLs for their assets:

```hack
use type Nuxed\Asset\UrlPackage;
// ...

$urlPackage = new UrlPackage(
    'http://static.example.com/images/',
    new StaticVersionStrategy('v1')
);

print $urlPackage->getUrl('/logo.png');
// result: http://static.example.com/images/logo.png?v1
```

You can also pass a schema-agnostic URL:

```hack
use type Nuxed\Asset\UrlPackage;
// ...

$urls = vec[
    '//static1.example.com/images/',
    '//static2.example.com/images/',
];

$urlPackage = new UrlPackage($urls, new StaticVersionStrategy('v1'));

print $urlPackage->getUrl('/logo.png');
// result: //static.example.com/images/logo.png?v1
print  $urlPackage->getUrl('/icon.png');
// result: //static2.example.com/images/icon.png?v1
```

This is useful because assets will automatically be requested via HTTPS if a visitor is viewing your site in https. If you want to use this, make sure that your CDN host supports HTTPS.

For each asset, one of the URLs will be randomly used. But, the selection is deterministic, meaning that each asset will be always served by the same domain. This behavior simplifies the management of HTTP cache.

### Named Packages

Applications that manage lots of different assets may need to group them in packages with the same versioning strategy and base path. The Asset component includes a `Packages` class to simplify management of several packages.

In the following example, all packages use the same versioning strategy, but they all have different base paths:

```hack
use namespace Nuxed\Asset;
use namespace Nuxed\Asset\VersionStrategy;
// ...

$versionStrategy = new VersionStrategy\StaticVersionStrategy('v1');

$defaultPackage = new Asset\Package($versionStrategy);

$namedPackages = Map {
    'img' => new Asset\UrlPackage('http://img.example.com/', $versionStrategy),
    'doc' => new Asset\PathPackage('/somewhere/deep/for/documents', $versionStrategy),
};

$packages = new Asset\Packages($defaultPackage, $namedPackages);
```

The `Packages` class allows to define a default package, which will be applied to assets that don't define the name of package to use. In addition, this application defines a package named `img` to serve images from an external domain and a `doc` package to avoid repeating long paths when linking to a document inside a handler:

```hack

use type Nuxed\Contract\Http\Message\ServerRequestInterface;
use type Nuxed\Contract\Http\Message\ResponseInterface;
use namespace Nuxed\Kernel\Handler;
use type Nuxed\Asset\Packages;

class DocumentHandler extends Handler\AbstractHandler {
  use Handler\ResponseFactoryTrait;

  public function __construct(
    private Packages $asset
  ) {}

  public async function handle(
    ServerRequestInterface $request
  ): Awaitable<ResponseInterface> {

    $stylesheet = $this->asset->getUrl('main.css');
    // result: /main.css?v1
    $favicon = $this->asset->getUrl('/logo.png', 'img');
    // result: http://img.example.com/logo.png?v1
    $document = $this->asset->getUrl('resume.pdf', 'doc');
    // result: /somewhere/deep/for/documents/resume.pdf?v1

    return $this->html(
      <x:doctype>
        <html>
          <head>
            <title>Asset</title>
            <link rel="stylesheet" type="text/css" href="{$stylesheet}" />
            <link rel="shortcut icon" type="image/png" href="{$favicon}"/>
          </head>
          <body>
            <main>
                ...
                <a href="{$document}" download>download resume</a>
                ...
            </main>
          </body>
        </html>
      </x:doctype>
    );
  }
}

```

### Local Files and Other Protocols

In addition to HTTP this component supports other protocols (such as file:// and ftp://). This allows for example to serve local files in order to improve performance:

```hack
use type Nuxed\Asset\UrlPackage;
// ...

$localPackage = new UrlPackage(
    'file:///path/to/images/',
    new EmptyVersionStrategy()
);

$ftpPackage = new UrlPackage(
    'ftp://example.com/images/',
    new EmptyVersionStrategy()
);

print $localPackage->getUrl('/logo.png');
// result: file:///path/to/images/logo.png

print $ftpPackage->getUrl('/logo.png');
// result: ftp://example.com/images/logo.png
```