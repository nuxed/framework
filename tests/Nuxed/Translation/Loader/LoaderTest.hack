namespace Nuxed\Test\Translation\Loader;

use namespace Facebook\HackTest;
use namespace Nuxed\Translation\Loader;
use function Facebook\FBExpect\expect;

abstract class LoaderTest<T> extends HackTest\HackTest {
  abstract protected function getLoader(): Loader\ILoader<T>;

  <<HackTest\DataProvider('provideLoadData')>>
  public function testLoad(
    T $resource,
    string $locale,
    string $domain,
    KeyedContainer<string, string> $expected,
  ): void {
    $loader = $this->getLoader();
    $catalogue = $loader->load($resource, $locale, $domain);
    expect($catalogue->getLocale())->toBeSame($locale);
    expect($catalogue->getDomains())->toContain($domain);
    expect($catalogue->all())
      ->toBeSame(dict[
        $domain => $expected,
      ]);
  }

  abstract public function provideLoadData(
  ): Container<(T, string, string, KeyedContainer<string, string>)>;
}
