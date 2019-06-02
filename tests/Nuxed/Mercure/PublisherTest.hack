namespace Nuxed\Test\Mercure;

use namespace Nuxed\Mercure;
use namespace Nuxed\Http\Client;
use namespace Nuxed\Http\Message;
use namespace Facebook\HackTest;
use function Facebook\FBExpect\expect;

class PublisherTest extends HackTest\HackTest {
  const string URL = 'https://demo.mercure.rocks/hub';
  const string JWT =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJtZXJjdXJlIjp7InN1YnNjcmliZSI6WyJmb28iLCJiYXIiXSwicHVibGlzaCI6WyJmb28iXX19.LRLvirgONK13JgacQ_VbcjySbVhkSmHy3IznH3tA9PM';
  const string AUTH_HEADER = 'Bearer '.self::JWT;

  public async function testPublish(): Awaitable<void> {
    $client = new Client\MockHttpClient(
      async ($request) ==> {
        expect($request->getMethod())->toBeSame('POST');
        expect($request->getUri()->toString())->toBeSame(self::URL);
        expect($request->getHeaderLine('authorization'))
          ->toBeSame(self::AUTH_HEADER);
        expect(await $request->getBody()->readAsync())->toBeSame(
          'topic=https%3A%2F%2Fdemo.mercure.rocks%2Fdemo%2Fbooks%2F1.jsonld&data=Hi+from+Nuxed%21&id=id',
        );

        return Message\response(200, dict[], Message\stream('id'));
      },
    );

    $publisher = new Mercure\Publisher(self::URL, () ==> self::JWT, $client);
    $update = new Mercure\Update(
      vec['https://demo.mercure.rocks/demo/books/1.jsonld'],
      'Hi from Nuxed!',
      vec[],
      'id',
    );

    expect(await $publisher->publish($update))->toBeSame('id');
  }

  public async function testInvalidJwt(): Awaitable<void> {
    $client = new Client\MockHttpClient(
      async ($request) ==> Message\response(500),
    );
    $publisher = new Mercure\Publisher(self::URL, () ==> 'Invalid', $client);
    $update = new Mercure\Update(
      vec['https://demo.mercure.rocks/demo/books/1.jsonld'],
      'Hello, World!',
    );
    expect(() ==> $publisher->publish($update))
      ->toThrow(
        Mercure\Exception\InvalidArgumentException::class,
        'The provided JWT is not valid',
      );
  }
}
