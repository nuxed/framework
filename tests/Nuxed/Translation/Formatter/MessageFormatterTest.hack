namespace Nuxed\Test\Translation\Formatter;

use namespace Facebook\HackTest;
use namespace Nuxed\Translation\Formatter;
use namespace Nuxed\Translation\Exception;
use function Facebook\FBExpect\expect;

class MessageFormatterTest extends HackTest\HackTest {
  <<HackTest\DataProvider('provideFormatData')>>
  public function testFormat(
    string $expected,
    string $message,
    string $locale,
    KeyedContainer<string, mixed> $parameters,
  ): void {
    expect(
      new Formatter\MessageFormatter()
        |> $$->format($message, $locale, $parameters),
    )->toBeSame($expected);
  }

  public function testInvalidMessageFormat(): void {
    $formatter = new Formatter\MessageFormatter();
    expect(
      () ==> $formatter->format('{gender_of_host, select, {{', 'en', dict[
        'gender_of_host' => 'non-binary',
      ]),
    )->toThrow(
      Exception\InvalidArgumentException::class,
      'Invalid message format (error #65799): msgfmt_create: message formatter creation failed: U_PATTERN_SYNTAX_ERROR.',
    );
  }

  public function provideFormatData(
  ): Container<(string, string, string, KeyedContainer<string, mixed>)> {
    $plural = <<<'_MSG_'
{gender_of_host, select,
  female {{num_guests, plural, offset:1
      =0 {{host} does not give a party.}
      =1 {{host} invites {guest} to her party.}
      =2 {{host} invites {guest} and one other person to her party.}
     other {{host} invites {guest} as one of the # people invited to her party.}}}
  male   {{num_guests, plural, offset:1
      =0 {{host} does not give a party.}
      =1 {{host} invites {guest} to his party.}
      =2 {{host} invites {guest} and one other person to his party.}
     other {{host} invites {guest} as one of the # people invited to his party.}}}
  other {{num_guests, plural, offset:1
      =0 {{host} does not give a party.}
      =1 {{host} invites {guest} to their party.}
      =2 {{host} invites {guest} and one other person to their party.}
     other {{host} invites {guest} as one of the # people invited to their party.}}}}
_MSG_;

    return vec[
      tuple('Hello, Saif!', 'Hello, {name}!', 'en', dict['name' => 'Saif']),
      tuple('Hello, Ahmed!', 'Hello, {name}!', 'en', dict['name' => 'Ahmed']),
      tuple('Hello, Ons!', 'Hello, {name}!', 'en', dict['name' => 'Ons']),
      tuple('Hello, World!', 'Hello, World!', 'en', dict[]),
      tuple(
        'Ons invites Ahmed as one of the 9 people invited to her party.',
        $plural,
        'en',
        dict[
          'gender_of_host' => 'female',
          'num_guests' => 10,
          'host' => 'Ons',
          'guest' => 'Ahmed',
        ],
      ),
    ];
  }
}
