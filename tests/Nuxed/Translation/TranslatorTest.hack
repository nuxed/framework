namespace Nuxed\Test\Translation;

use namespace HH\Lib\Str;
use namespace Nuxed\Translation;
use namespace Nuxed\Translation\Exception;
use namespace Facebook\HackTest;
use function Facebook\FBExpect\expect;

class TranslatorTest extends HackTest\HackTest {
  <<HackTest\DataProvider('provideInvalidLocales')>>
  public function testConstructInvalidLocale(string $locale): void {
    expect(() ==> new Translation\Translator($locale))->toThrow(
      Exception\InvalidArgumentException::class,
    );
  }

  <<HackTest\DataProvider('provideValidLocales')>>
  public function testConstructValidLocale(string $locale): void {
    $translator = new Translation\Translator($locale);
    expect($translator->getLocale())
      ->toBeSame($locale);
  }

  public function testSetGetLocale(): void {
    $translator = new Translation\Translator('en');
    expect($translator->getLocale())->toBeSame('en');
    $translator->setLocale('fr');
    expect($translator->getLocale())->toBeSame('fr');
  }

  <<HackTest\DataProvider('provideInvalidLocales')>>
  public function testSetInvalidLocale(string $locale): void {
    $translator = new Translation\Translator('en');

    expect(() ==> $translator->setLocale($locale))->toThrow(
      Exception\InvalidArgumentException::class,
    );
  }

  <<HackTest\DataProvider('provideValidLocales')>>
  public function testSetValidLocale(string $locale): void {
    $translator = new Translation\Translator('en');
    $translator->setLocale($locale);
    expect($translator->getLocale())->toBeSame($locale);
  }

  public function testGetCatalogue(): void {
    $translator = new Translation\Translator('en');
    $catalogue = $translator->getCatalogue();
    expect($catalogue->getLocale())->toBeSame('en');
    expect(dict($catalogue->all()))->toBeSame(dict[]);
    $translator->setLocale('fr');
    $catalogue = $translator->getCatalogue();
    expect($catalogue->getLocale())->toBeSame('fr');
    expect(dict($catalogue->all()))->toBeSame(dict[]);
    $frCatalogue = $translator->getCatalogue('fr');
    expect($frCatalogue)->toBeSame($catalogue);
  }

  public function testGetCatalogueReturnsConsolidatedCatalogue(): void {
    /*
     * This will be useful once we refactor so that different domains will be loaded lazily (on-demand).
     * In that case, getCatalogue() will probably have to load all missing domains in order to return
     * one complete catalogue.
     */
    $locale = 'whatever';
    $translator = new Translation\Translator($locale);
    $translator->addLoader(
      Translation\Format::Tree,
      new Translation\Loader\TreeLoader(),
    );
    $translator->addLoader(
      Translation\Format::Ini,
      new Translation\Loader\IniFileLoader(),
    );

    $translator->addResource(
      Translation\Format::Tree,
      dict['foo' => 'foofoo'],
      $locale,
      'domain-a',
    );
    $translator->addResource(
      Translation\Format::Ini,
      __DIR__.'/fixtures/user.en.ini',
      $locale,
      'domain-b',
    );

    /*
     * Test that we get a single catalogue comprising messages
     * from different loaders and different domains
     */
    $catalogue = $translator->getCatalogue($locale);
    expect($catalogue->defines('foo', 'domain-a'))->toBeTrue();
    expect($catalogue->defines('security.login.username', 'domain-b'))
      ->toBeTrue();
  }


  public function testSetFallbackLocales(): void {
    $translator = new Translation\Translator('en');
    $translator->addLoader(
      Translation\Format::Tree,
      new Translation\Loader\TreeLoader(),
    );
    $translator->addResource(
      Translation\Format::Tree,
      dict['foo' => 'foofoo'],
      'en',
    );
    $translator->addResource(
      Translation\Format::Tree,
      dict['bar' => 'foobar'],
      'fr',
    );
    // force catalogue loading
    $translator->trans('bar');
    $translator->setFallbackLocales(['fr']);
    expect($translator->trans('bar'))->toBeSame('foobar');
  }


  public function testSetFallbackLocalesMultiple(): void {
    $translator = new Translation\Translator('en');
    $translator->addLoader(
      Translation\Format::Tree,
      new Translation\Loader\TreeLoader(),
    );
    $translator->addResource(
      Translation\Format::Tree,
      dict['foo' => 'foo (en)'],
      'en',
    );
    $translator->addResource(
      Translation\Format::Tree,
      dict['bar' => 'bar (fr)'],
      'fr',
    );
    // force catalogue loading
    $translator->trans('bar');
    $translator->setFallbackLocales(['fr_FR', 'fr']);
    expect($translator->trans('bar'))->toBeSame('bar (fr)');
  }

  <<HackTest\DataProvider('provideInvalidLocales')>>
  public function testSetFallbackInvalidLocales(string $locale): void {
    $translator = new Translation\Translator('en');
    expect(() ==> $translator->setFallbackLocales(vec['en', $locale]))->toThrow(
      Exception\InvalidArgumentException::class,
    );
  }

  <<HackTest\DataProvider('provideValidLocales')>>
  public function testSetFallbackValidLocales(string $locale): void {
    $translator = new Translation\Translator('en');
    $translator->setFallbackLocales(vec['ar', $locale]);
    $catalogue = $translator->getCatalogue();
    expect(
      $catalogue->getFallbackCatalogue()
        ?->getFallbackCatalogue()
        ?->getLocale(),
    )->toBeSame($locale);
  }

  public function testTransWithFallbackLocale(): void {
    $translator = new Translation\Translator('fr_FR');
    $translator->setFallbackLocales(['en']);
    $translator->addLoader(
      Translation\Format::Ini,
      new Translation\Loader\IniFileLoader(),
    );
    $translator->addResource(
      Translation\Format::Ini,
      __DIR__.'/fixtures/user.en.ini',
      'en',
    );
    expect($translator->trans('security.login.username'))->toBeSame('Username');
  }

  <<HackTest\DataProvider('provideInvalidLocales')>>
  public function testAddResourceInvalidLocales(string $locale): void {
    $translator = new Translation\Translator('fr');
    expect(
      () ==> $translator->addResource(
        Translation\Format::Tree,
        dict['foo' => 'foofoo'],
        $locale,
      ),
    )->toThrow(Exception\InvalidArgumentException::class);
  }

  <<HackTest\DataProvider('provideValidLocales')>>
  public function testAddResourceValidLocales(string $locale): void {
    $translator = new Translation\Translator('fr');
    $translator->addResource(
      Translation\Format::Tree,
      dict['foo' => 'foofoo'],
      $locale,
    );
  }

  public function provideInvalidLocales(): Container<(string)> {
    return vec[
      tuple('fr FR'),
      tuple('français'),
      tuple('fr+en'),
      tuple('utf#8'),
      tuple('fr&en'),
      tuple('fr~FR'),
      tuple(' fr'),
      tuple('fr '),
      tuple('fr*'),
      tuple('fr/FR'),
      tuple('fr\\FR'),
    ];
  }

  public function provideValidLocales(): Container<(string)> {
    return vec[
      tuple(''),
      tuple('fr'),
      tuple('francais'),
      tuple('FR'),
      tuple('frFR'),
      tuple('fr-FR'),
      tuple('fr_FR'),
      tuple('fr.FR'),
      tuple('fr-FR.UTF8'),
      tuple('sr@latin'),
    ];
  }

  public function testAddResourceAfterTrans(): void {
    $translator = new Translation\Translator('fr');
    $translator->addLoader(
      Translation\Format::Tree,
      new Translation\Loader\TreeLoader(),
    );
    $translator->setFallbackLocales(['en']);
    $translator->addResource(
      Translation\Format::Tree,
      dict['foo' => 'foofoo'],
      'en',
    );
    expect($translator->trans('foo'))->toBeSame('foofoo');
    $translator->addResource(
      Translation\Format::Tree,
      ['bar' => 'foobar'],
      'en',
    );
    expect($translator->trans('bar'))->toBeSame('foobar');
  }

  <<HackTest\DataProvider('provideTransFileTests')>>
  public function testTransWithoutFallbackLocaleFile(
    classname<Translation\Loader\ILoader<string>> $format,
    Translation\Loader\ILoader<string> $loader,
    string $extension,
  ): void {
    $translator = new Translation\Translator('en');
    $translator->addLoader($format, $loader);
    $translator->addResource($format, __DIR__.'/fixtures/non-existing', 'en');
    $resource = Str\format('%s%s', __DIR__.'/fixtures/user.en.', $extension);
    $translator->addResource($format, $resource, 'en');
    // force catalogue loading
    expect(() ==> $translator->trans('foo'))->toThrow(
      Exception\NotFoundResourceException::class,
    );
  }

  <<HackTest\DataProvider('provideTransFileTests')>>
  public function testTransWithFallbackLocaleFile(
    classname<Translation\Loader\ILoader<string>> $format,
    Translation\Loader\ILoader<string> $loader,
    string $extension,
  ): void {
    $translator = new Translation\Translator('en');
    $translator->addLoader($format, $loader);
    $translator->addResource($format, __DIR__.'/fixtures/non-existing', 'fr');
    $resource = Str\format('%s%s', __DIR__.'/fixtures/user.en.', $extension);
    $translator->addResource($format, $resource, 'en');
    expect($translator->trans('security.login.username', dict[], 'en'));
  }

  public function provideTransFileTests(
  ): Container<(
    classname<Translation\Loader\ILoader<string>>,
    Translation\Loader\ILoader<string>,
    string,
  )> {
    return vec[
      tuple(
        Translation\Format::Json,
        new Translation\Loader\JsonFileLoader(),
        'json',
      ),
      tuple(
        Translation\Format::Ini,
        new Translation\Loader\IniFileLoader(),
        'ini',
      ),
    ];
  }

  public function testTransWithIcuFallbackLocale(): void {
    $translator = new Translation\Translator('en_GB');
    $translator->addLoader(
      Translation\Format::Tree,
      new Translation\Loader\TreeLoader(),
    );
    $translator->addResource(
      Translation\Format::Tree,
      dict['foo' => 'foofoo'],
      'en_GB',
    );
    $translator->addResource(
      Translation\Format::Tree,
      dict['bar' => 'foobar'],
      'en_001',
    );
    $translator->addResource(
      Translation\Format::Tree,
      dict['baz' => 'foobaz'],
      'en',
    );
    expect($translator->trans('foo'))->toBeSame('foofoo');
    expect($translator->trans('bar'))->toBeSame('foobar');
    expect($translator->trans('baz'))->toBeSame('foobaz');
  }

  public function testTransWithIcuVariantFallbackLocale(): void {
    $translator = new Translation\Translator('en_GB');
    $translator->addLoader(
      Translation\Format::Tree,
      new Translation\Loader\TreeLoader(),
    );
    $translator->addResource(
      Translation\Format::Tree,
      dict['bar' => 'foobar'],
      'en_GB',
    );
    $translator->addResource(
      Translation\Format::Tree,
      dict['baz' => 'foobaz'],
      'en_001',
    );
    $translator->addResource(
      Translation\Format::Tree,
      dict['qux' => 'fooqux'],
      'en',
    );

    expect($translator->trans('bar'))->toBeSame('foobar');
    expect($translator->trans('baz'))->toBeSame('foobaz');
    expect($translator->trans('qux'))->toBeSame('fooqux');
  }

  public function testTransWithIcuRootFallbackLocale(): void {
    $translator = new Translation\Translator('az_Cyrl');
    $translator->addLoader(
      Translation\Format::Tree,
      new Translation\Loader\TreeLoader(),
    );
    $translator->addResource(
      Translation\Format::Tree,
      dict['foo' => 'foofoo'],
      'az_Cyrl',
    );
    $translator->addResource(
      Translation\Format::Tree,
      dict['bar' => 'foobar'],
      'az',
    );
    expect($translator->trans('foo'))->toBeSame('foofoo');
    expect($translator->trans('bar'))->toBeSame('bar');
  }

  public function testTransWithFallbackLocaleBis(): void {
    $translator = new Translation\Translator('en_US');
    $translator->addLoader(
      Translation\Format::Tree,
      new Translation\Loader\TreeLoader(),
    );
    $translator->addResource(
      Translation\Format::Tree,
      dict['foo' => 'foofoo'],
      'en_US',
    );
    $translator->addResource(
      Translation\Format::Tree,
      dict['bar' => 'foobar'],
      'en',
    );
    expect($translator->trans('bar'))->toBeSame('foobar');
  }

  public function testTransWithFallbackLocaleTer(): void {
    $translator = new Translation\Translator('fr_FR');
    $translator->addLoader(
      Translation\Format::Tree,
      new Translation\Loader\TreeLoader(),
    );
    $translator->addResource(
      Translation\Format::Tree,
      dict['foo' => 'foo (en_US)'],
      'en_US',
    );
    $translator->addResource(
      Translation\Format::Tree,
      dict['bar' => 'bar (en)'],
      'en',
    );
    $translator->setFallbackLocales(vec['en_US', 'en']);
    expect($translator->trans('bar'))->toBeSame('bar (en)');
    expect($translator->trans('foo'))->toBeSame('foo (en_US)');
  }

  public function testTransNonExistentWithFallback(): void {
    $translator = new Translation\Translator('fr');
    $translator->setFallbackLocales(['en']);
    $translator->addLoader(
      Translation\Format::Tree,
      new Translation\Loader\TreeLoader(),
    );
    expect($translator->trans('non-existent'))->toBeSame('non-existent');
  }

  public function testWhenAResourceHasNoRegisteredLoader(): void {
    $translator = new Translation\Translator('en');
    $translator->addResource(
      Translation\Format::Tree,
      dict['foo' => 'foo'],
      'en',
    );
    expect(() ==> $translator->trans('foo'))->toThrow(
      Exception\RuntimeException::class,
    );
  }

  public function testNestedFallbackCatalogueWhenUsingMultipleLocales(): void {
    $translator = new Translation\Translator('fr');
    $translator->setFallbackLocales(['ru', 'en']);
    $translator->getCatalogue('fr');
    $fr = $translator->getCatalogue('fr');
    expect($fr->getFallbackCatalogue())->toNotBeNull();
    $ru = $fr->getFallbackCatalogue() as nonnull;
    expect($ru->getLocale())->toBeSame('ru');
    expect($ru->getFallbackCatalogue())->toNotBeNull();
    $en = $ru->getFallbackCatalogue() as nonnull;
    expect($en->getLocale())->toBeSame('en');
    expect($en->getFallbackCatalogue())->toBeNull();
  }

  <<HackTest\DataProvider('provideTransTests')>>
  public function testTrans(
    string $expected,
    string $id,
    string $translation,
    KeyedContainer<string, arraykey> $parameters,
    string $locale,
    ?string $domain,
  ): void {
    $translator = new Translation\Translator('en');
    $translator->addLoader(
      Translation\Format::Tree,
      new Translation\Loader\TreeLoader(),
    );
    $translator->addResource(
      Translation\Format::Tree,
      dict[$id => $translation],
      $locale,
      $domain,
    );
    expect($translator->trans($id, $parameters, $locale, $domain))
      ->toBeSame($expected);
  }

  public function provideTransTests(
  ): Container<(
    string,
    string,
    string,
    KeyedContainer<string, arraykey>,
    ?string,
    ?string,
  )> {
    return vec[
      tuple(
        'Nuxed est super !',
        'Nuxed is great!',
        'Nuxed est super !',
        dict[],
        'fr',
        null,
      ),
      tuple(
        'Nuxed aime Symfony !',
        'Nuxed loves {what}!',
        'Nuxed aime {what} !',
        dict['what' => 'Symfony'],
        'fr',
        '',
      ),
      tuple(
        'Nuxed est super !',
        'Nuxed is great!',
        'Nuxed est super !',
        dict[],
        'fr',
        null,
      ),
    ];
  }

  <<HackTest\DataProvider('provideInvalidLocales')>>
  public function testTransInvalidLocale(string $locale): void {
    $translator = new Translation\Translator('en');
    $translator->addLoader(
      Translation\Format::Tree,
      new Translation\Loader\TreeLoader(),
    );
    $translator->addResource(
      Translation\Format::Tree,
      dict['foo' => 'foofoo'],
      'en',
    );
    expect(() ==> $translator->trans('foo', dict[], $locale))->toThrow(
      Exception\InvalidArgumentException::class,
    );
  }

  <<HackTest\DataProvider('provideValidLocales')>>
  public function testTransValidLocale(string $locale): void {
    $translator = new Translation\Translator($locale);
    $translator->addLoader(
      Translation\Format::Tree,
      new Translation\Loader\TreeLoader(),
    );
    $translator->addResource(
      Translation\Format::Tree,
      dict['test' => 'OK'],
      $locale,
    );
    expect($translator->trans('test'))->toBeSame('OK');
    expect($translator->trans('test', dict[], $locale))->toBeSame('OK');
  }

  <<HackTest\DataProvider('provideFlattenedTransTests')>>
  public function testFlattenedTrans(
    string $expected,
    KeyedContainer<string, mixed> $messages,
    string $id,
  ): void {
    $translator = new Translation\Translator('en');
    $translator->addLoader(
      Translation\Format::Tree,
      new Translation\Loader\TreeLoader(),
    );
    $translator->addResource(Translation\Format::Tree, $messages, 'fr');
    expect($translator->trans($id, dict[], 'fr'))
      ->toBeSame($expected);
  }

  public function provideFlattenedTransTests(
  ): Container<(string, KeyedContainer<string, mixed>, string)> {
    $messages = dict[
      'nuxed' => dict['loves' => dict['symfony' => 'Nuxed loves Symfony <3']],
      'foo' => dict['bar' => dict['baz' => 'Foo Bar Baz'], 'baz' => 'Foo Baz'],
    ];

    return vec[
      tuple('Nuxed loves Symfony <3', $messages, 'nuxed.loves.symfony'),
      tuple('Foo Bar Baz', $messages, 'foo.bar.baz'),
      tuple('Foo Baz', $messages, 'foo.baz'),
    ];
  }


}
