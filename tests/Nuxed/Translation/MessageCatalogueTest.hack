namespace Nuxed\Test\Translation;

use namespace HH\Lib\C;
use namespace HH\Lib\Dict;
use namespace Facebook\HackTest;
use namespace Nuxed\Translation;
use namespace Nuxed\Translation\Expection;
use function Facebook\FBExpect\expect;

class MessageCatalogueTest extends HackTest\HackTest {
  public function testGetLocale(): void {
    $catalogue = new Translation\MessageCatalogue('en');

    expect($catalogue->getLocale())->toBeSame('en');
  }

  public function testGetDomains(): void {
    $catalogue = new Translation\MessageCatalogue('en');

    expect(C\count($catalogue->getDomains()))->toBeSame(0);
    $catalogue->add(dict[], 'foo');
    $catalogue->add(dict[], 'bar');
    $catalogue->add(dict[], 'baz');
    $domains = $catalogue->getDomains();
    expect($domains)->toContain('foo');
    expect($domains)->toContain('bar');
    expect($domains)->toContain('baz');
    expect(C\count($domains))->toBeSame(3);
  }

  public function testAll(): void {
    $messages = dict[
      'domain1' => dict[
        'foo' => 'Foo !',
      ],
      'domain2' => dict[
        'bar' => 'Foo !',
      ],
    ];
    $catalogue = new Translation\MessageCatalogue('en', $messages);

    $all = $catalogue->all();
    expect(Dict\map($all, ($messages) ==> dict($messages)))
      ->toBeSame($messages);
    expect(C\contains_key($all, 'domain1'))->toBeTrue();
    expect(C\contains_key($all, 'domain2'))->toBeTrue();
    expect(C\count($all))->toBeSame(2);
    expect(C\count($all['domain1']))->toBeSame(1);
    expect(C\count($all['domain2']))->toBeSame(1);
  }

  public function testDomain(): void {
    $catalogue = new Translation\MessageCatalogue('en', dict[
      'domain1' => dict[
        'foo' => 'Foo!',
      ],
      'domain2' => dict[
        'bar' => 'Bar!',
      ],
    ]);

    $domain1 = $catalogue->domain('domain1');
    expect(C\count($domain1))->toBeSame(1);
    expect(C\contains_key($domain1, 'foo'))->toBeTrue();
    expect($domain1['foo'])->toBeSame('Foo!');
    $domain2 = $catalogue->domain('domain2');
    expect(C\count($domain2))->toBeSame(1);
    expect(C\contains_key($domain2, 'bar'))->toBeTrue();
    expect($domain2['bar'])->toBeSame('Bar!');
  }

  public function testSet(): void {
    $catalogue = new Translation\MessageCatalogue('en', dict[
      'domain1' => dict[
        'foo' => 'Foo!',
      ],
      'domain2' => dict[
        'bar' => 'Bar!',
      ],
    ]);

    $catalogue->set('baz', 'Baz!', 'domain3');
    expect($catalogue->domain('domain3')['baz'])->toBeSame('Baz!');
    $catalogue->set('foobar', 'Foo!? BAR!', 'domain1');
    $domain1 = $catalogue->domain('domain1');
    expect(C\count($domain1))->toBeSame(2);
    expect($domain1['foo'])->toBeSame('Foo!');
    expect($domain1['foobar'])->toBeSame('Foo!? BAR!');
    $catalogue->set('foobar', 'Nuh...', 'domain1');
    $domain1 = $catalogue->domain('domain1');
    expect($domain1['foobar'])->toBeSame('Nuh...');
  }

  public function testHas(): void {
    $catalogue = new Translation\MessageCatalogue('en', dict[
      'domain1' => dict[
        'foo' => 'Foo!',
      ],
      'domain2' => dict[
        'bar' => 'Bar!',
      ],
    ]);

    expect($catalogue->has('foo', 'domain1'))->toBeTrue();
    expect($catalogue->has('bar', 'domain2'))->toBeTrue();
    expect($catalogue->has('foo'))->toBeFalse();
    expect($catalogue->has('bar'))->toBeFalse();
    expect($catalogue->has('baz', 'domain3'))->toBeFalse();
    expect($catalogue->has('baz'))->toBeFalse();

    $fallback = new Translation\MessageCatalogue('fr', dict[
      'domain3' => dict[
        'baz' => 'Baz!',
      ],
    ]);
    $catalogue->addFallbackCatalogue($fallback);

    expect($catalogue->has('foo', 'domain1'))->toBeTrue();
    expect($catalogue->has('bar', 'domain2'))->toBeTrue();
    expect($catalogue->has('foo'))->toBeFalse();
    expect($catalogue->has('bar'))->toBeFalse();
    expect($catalogue->has('baz', 'domain3'))->toBeTrue();
    expect($catalogue->has('baz'))->toBeFalse();
  }

  public function testDefines(): void {
    $catalogue = new Translation\MessageCatalogue('en', dict[
      'domain1' => dict[
        'foo' => 'Foo!',
      ],
      'domain2' => dict[
        'bar' => 'Bar!',
      ],
    ]);

    expect($catalogue->defines('foo', 'domain1'))->toBeTrue();
    expect($catalogue->defines('bar', 'domain2'))->toBeTrue();
    expect($catalogue->defines('foo'))->toBeFalse();
    expect($catalogue->defines('bar'))->toBeFalse();
    expect($catalogue->defines('baz', 'domain3'))->toBeFalse();
    expect($catalogue->defines('baz'))->toBeFalse();

    $fallback = new Translation\MessageCatalogue('fr', dict[
      'domain3' => dict[
        'baz' => 'Baz!',
      ],
    ]);
    $catalogue->addFallbackCatalogue($fallback);

    expect($catalogue->defines('foo', 'domain1'))->toBeTrue();
    expect($catalogue->defines('bar', 'domain2'))->toBeTrue();
    expect($catalogue->defines('foo'))->toBeFalse();
    expect($catalogue->defines('bar'))->toBeFalse();
    expect($catalogue->defines('baz', 'domain3'))->toBeFalse();
    expect($catalogue->defines('baz'))->toBeFalse();
  }

  public function testGet(): void {
    $catalogue = new Translation\MessageCatalogue('en', dict[
      'domain1' => dict[
        'foo' => 'Foo!',
      ],
      'domain2' => dict[
        'bar' => 'Bar!',
      ],
    ]);

    expect($catalogue->get('foo', 'domain1'))->toBeSame('Foo!');
    expect($catalogue->get('bar', 'domain2'))->toBeSame('Bar!');
    expect($catalogue->get('foo'))->toBeSame('foo');
    expect($catalogue->get('bar'))->toBeSame('bar');
    expect($catalogue->get('baz', 'domain3'))->toBeSame('baz');
    expect($catalogue->get('baz'))->toBeSame('baz');

    $fallback = new Translation\MessageCatalogue('fr', dict[
      'domain3' => dict[
        'baz' => 'Baz!',
      ],
    ]);
    $catalogue->addFallbackCatalogue($fallback);

    expect($catalogue->get('foo', 'domain1'))->toBeSame('Foo!');
    expect($catalogue->get('bar', 'domain2'))->toBeSame('Bar!');
    expect($catalogue->get('foo'))->toBeSame('foo');
    expect($catalogue->get('bar'))->toBeSame('bar');
    expect($catalogue->get('baz', 'domain3'))->toBeSame('Baz!');
    expect($catalogue->get('baz'))->toBeSame('baz');
  }

  public function testReplace(): void {
    $catalogue = new Translation\MessageCatalogue('en', dict[
      'domain1' => dict[
        'foo' => 'Foo!',
      ],
      'domain2' => dict[
        'bar' => 'Bar!',
      ],
    ]);

    $messages = dict($catalogue->domain('domain1'));
    expect($messages)->toBeSame(dict['foo' => 'Foo!']);
    $messages = dict($catalogue->domain('domain2'));
    expect($messages)->toBeSame(dict['bar' => 'Bar!']);

    $catalogue->replace(dict['baz' => 'Baz!'], 'domain1');
    $messages = dict($catalogue->domain('domain1'));
    expect($messages)->toBeSame(dict['baz' => 'Baz!']);
    $messages = dict($catalogue->domain('domain2'));
    expect($messages)->toBeSame(dict['bar' => 'Bar!']);

    $catalogue->replace(dict['qux' => 'Qux!'], 'domain2');
    $messages = dict($catalogue->domain('domain1'));
    expect($messages)->toBeSame(dict['baz' => 'Baz!']);
    $messages = dict($catalogue->domain('domain2'));
    expect($messages)->toBeSame(dict['qux' => 'Qux!']);
  }

  public function testAdd(): void {
    $catalogue = new Translation\MessageCatalogue('en', dict[
      'domain1' => dict[
        'foo' => 'Foo!',
      ],
      'domain2' => dict[
        'bar' => 'Bar!',
      ],
    ]);

    $messages = dict($catalogue->domain('domain1'));
    expect($messages)->toBeSame(dict['foo' => 'Foo!']);
    $messages = dict($catalogue->domain('domain2'));
    expect($messages)->toBeSame(dict['bar' => 'Bar!']);

    $catalogue->add(dict['baz' => 'Baz!'], 'domain1');
    $messages = dict($catalogue->domain('domain1'));
    expect($messages)->toBeSame(dict['foo' => 'Foo!', 'baz' => 'Baz!']);
    $messages = dict($catalogue->domain('domain2'));
    expect($messages)->toBeSame(dict['bar' => 'Bar!']);

    $catalogue->add(dict['qux' => 'Qux!'], 'domain2');
    $messages = dict($catalogue->domain('domain1'));
    expect($messages)->toBeSame(dict['foo' => 'Foo!', 'baz' => 'Baz!']);
    $messages = dict($catalogue->domain('domain2'));
    expect($messages)->toBeSame(dict['bar' => 'Bar!', 'qux' => 'Qux!']);

    $catalogue->add(dict['foobar' => 'Foo!? Bar!'], 'domain3');
    $messages = dict($catalogue->domain('domain3'));
    expect($messages)->toBeSame(dict['foobar' => 'Foo!? Bar!']);
  }

  public function testAddCatalogue(): void {
    $catalogue = new Translation\MessageCatalogue('en', dict[
      'domain1' => dict[
        'foo' => 'Foo!',
      ],
      'domain2' => dict[
        'bar' => 'Bar!',
      ],
    ]);

    expect($catalogue->defines('foo', 'domain1'))->toBeTrue();
    expect($catalogue->defines('bar', 'domain2'))->toBeTrue();
    expect($catalogue->defines('baz', 'domain3'))->toBeFalse();

    $catalogue->addCatalogue(new Translation\MessageCatalogue('en', dict[
      'domain3' => dict[
        'baz' => 'Baz!',
      ],
    ]));

    expect($catalogue->defines('foo', 'domain1'))->toBeTrue();
    expect($catalogue->defines('bar', 'domain2'))->toBeTrue();
    expect($catalogue->defines('baz', 'domain3'))->toBeTrue();
  }

  public function testAddCatalogueWithDifferentLocale(): void {
    $catalogue = new Translation\MessageCatalogue('en');
    expect(
      () ==> $catalogue->addCatalogue(new Translation\MessageCatalogue('fr')),
    )->toThrow(
      Translation\Exception\LogicException::class,
      'Cannot add a catalogue for locale "fr" as the current locale for this catalogue is "en"',
    );
  }

  public function testGetFallbackCatalogue(): void {
    $catalogue = new Translation\MessageCatalogue('en');
    $fallback = $catalogue->getFallbackCatalogue();
    expect($fallback)->toBeNull();
    $fallback = new Translation\MessageCatalogue('fr');
    $catalogue->addFallbackCatalogue($fallback);
    expect($catalogue->getFallbackCatalogue())
      ->toBeSame($fallback);
  }

  public function testAddFallbackCatalogue(): void {

  }
}
