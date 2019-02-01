<?hh // strict

namespace Nuxed\Test\Asset;

use namespace Nuxed\Asset;
use type Facebook\HackTest\HackTest;
use function Facebook\FBExpect\expect;

class UrlPackageTest extends HackTest {
  <<DataProvider('providePackages')>>
  public function testGetUrl(
    Container<string> $baseUrls,
    string $format,
    string $path,
    string $expected,
  ): void {
    $package = new Asset\UrlPackage(
      $baseUrls,
      new Asset\VersionStrategy\StaticVersionStrategy('v1', $format ?? '%s?%s'),
    );
    expect($package->getUrl($path))->toBeSame($expected);
  }

  public function providePackages(
  ): Container<(Container<string>, string, string, string)> {
    return vec[
      tuple(
        vec['http://example.net'],
        '',
        'http://example.com/foo',
        'http://example.com/foo',
      ),
      tuple(
        vec['http://example.net'],
        '',
        'https://example.com/foo',
        'https://example.com/foo',
      ),
      tuple(
        vec['http://example.net'],
        '',
        '//example.com/foo',
        '//example.com/foo',
      ),
      tuple(
        vec['file:///example/net'],
        '',
        'file:///example/com/foo',
        'file:///example/com/foo',
      ),
      tuple(
        vec['ftp://example.net'],
        '',
        'ftp://example.com',
        'ftp://example.com',
      ),
      tuple(vec['http://example.com'], '', '/foo', 'http://example.com/foo?v1'),
      tuple(vec['http://example.com'], '', 'foo', 'http://example.com/foo?v1'),
      tuple(vec['http://example.com/'], '', 'foo', 'http://example.com/foo?v1'),
      tuple(
        vec['http://example.com/foo'],
        '',
        'foo',
        'http://example.com/foo/foo?v1',
      ),
      tuple(
        vec['http://example.com/foo/'],
        '',
        'foo',
        'http://example.com/foo/foo?v1',
      ),
      tuple(
        vec['file:///example/com/foo/'],
        '',
        'foo',
        'file:///example/com/foo/foo?v1',
      ),
      tuple(vec['http://example.com'], '', '/foo', 'http://example.com/foo?v1'),
      tuple(
        vec['http://example.com', 'http://example.net'],
        '',
        '/foo',
        'http://example.com/foo?v1',
      ),
      tuple(
        vec['http://example.com', 'http://example.net'],
        '',
        '/fooa',
        'http://example.net/fooa?v1',
      ),
      tuple(
        vec['file:///example/com', 'file:///example/net'],
        '',
        '/foo',
        'file:///example/com/foo?v1',
      ),
      tuple(
        vec['ftp://example.com', 'ftp://example.net'],
        '',
        '/fooa',
        'ftp://example.net/fooa?v1',
      ),
      tuple(
        vec['http://example.com'],
        'version-%2$s/%1$s',
        '/foo',
        'http://example.com/version-v1/foo',
      ),
      tuple(
        vec['http://example.com'],
        'version-%2$s/%1$s',
        'foo',
        'http://example.com/version-v1/foo',
      ),
      tuple(
        vec['http://example.com'],
        'version-%2$s/%1$s',
        'foo/',
        'http://example.com/version-v1/foo/',
      ),
      tuple(
        vec['http://example.com'],
        'version-%2$s/%1$s',
        '/foo/',
        'http://example.com/version-v1/foo/',
      ),
      tuple(
        vec['file:///example/com'],
        'version-%2$s/%1$s',
        '/foo/',
        'file:///example/com/version-v1/foo/',
      ),
      tuple(
        vec['ftp://example.com'],
        'version-%2$s/%1$s',
        '/foo/',
        'ftp://example.com/version-v1/foo/',
      ),
    ];
  }

  <<DataProvider('provideContext')>>
  public function testGetUrlWithContext(
    bool $secure,
    Container<string> $baseUrls,
    string $path,
    string $expected,
  ): void {
    $package = new Asset\UrlPackage(
      $baseUrls,
      new Asset\VersionStrategy\StaticVersionStrategy('v1'),
      $this->getContext($secure),
    );
    expect($package->getUrl($path))->toBeSame($expected);
  }

  public function provideContext(
  ): Container<(bool, Container<string>, string, string)> {
    return vec[
      tuple(
        false,
        vec['http://example.com'],
        'foo',
        'http://example.com/foo?v1',
      ),
      tuple(
        false,
        vec['http://example.com/bar/'],
        'foo',
        'http://example.com/bar/foo?v1',
      ),
      tuple(
        false,
        vec['http://example.com/bar'],
        'foo',
        'http://example.com/bar/foo?v1',
      ),
      tuple(
        false,
        vec['http://example.com'],
        'foo',
        'http://example.com/foo?v1',
      ),
      tuple(
        true,
        vec['http://example.com'],
        'foo',
        'http://example.com/foo?v1',
      ),
      tuple(
        true,
        vec['http://example.com', 'https://example.com'],
        'foo',
        'https://example.com/foo?v1',
      ),
      tuple(
        true,
        vec['https://example.com'],
        'foo',
        'https://example.com/foo?v1',
      ),
      tuple(
        false,
        vec['http://example.com', 'https://example.com'],
        'foo',
        'http://example.com/foo?v1',
      ),
      tuple(true, vec['//example.com'], 'foo', '//example.com/foo?v1'),
      tuple(false, vec['//example.com'], 'foo', '//example.com/foo?v1'),
    ];
  }

  public function testVersionStrategyGivesAbsoluteURL(): void {
    $versionStrategy = new Asset\VersionStrategy\StaticVersionStrategy(
      '',
      'https://cdn.com/bar/main.css',
    );
    $package =
      new Asset\UrlPackage(vec['https://example.com'], $versionStrategy);
    expect($package->getUrl('main.css'))->toBeSame(
      'https://cdn.com/bar/main.css',
    );
  }

  public function testNoBaseUrls(): void {
    $this->setExpectedException(Asset\Exception\LogicException::class);
    new Asset\UrlPackage(
      vec[],
      new Asset\VersionStrategy\EmptyVersionStrategy(),
    );
  }

  <<DataProvider('provideInvalidUrls')>>
  public function testWrongBaseUrl(string $baseUrls): void {
    $this->setExpectedException(
      Asset\Exception\InvalidArgumentException::class,
    );
    new Asset\UrlPackage(
      vec[$baseUrls],
      new Asset\VersionStrategy\EmptyVersionStrategy(),
    );
  }

  public function provideInvalidUrls(): Container<(string)> {
    return vec[
      tuple('not-a-url'),
      tuple('not-a-url-with-query?query=://'),
    ];
  }

  private function getContext(bool $secure): Asset\Context\ContextInterface {
    return new Asset\Context\Context('', $secure);
  }
}
