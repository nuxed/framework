namespace Nuxed\Test\Http\Message;

use namespace HH\Asio;
use namespace HH\Lib\Vec;
use namespace Nuxed\Io;
use namespace Facebook\HackTest;
use namespace HH\Lib\PseudoRandom;
use namespace Nuxed\Http\Message;
use namespace Nuxed\Contract\Http;
use function Facebook\FBExpect\expect;

class MessageFactoryTest extends HackTest\HackTest {
  <<HackTest\DataProvider('provideCreateResponseData')>>
  public function testCreateResponse(
    int $code,
    string $reasonPhrase,
    string $expected,
  ): void {
    $factory = new Message\MessageFactory();
    $response = $factory->createResponse($code, $reasonPhrase);

    expect($response->getStatusCode())->toBeSame($code);
    expect($response->getReasonPhrase())->toBeSame($expected);
  }

  public function provideCreateResponseData(
  ): Container<(int, string, string)> {
    return vec[
      tuple(100, '', 'Continue'),
      tuple(101, '', 'Switching Protocols'),
      tuple(102, '', 'Processing'),
      tuple(200, '', 'OK'),
      tuple(201, '', 'Created'),
      tuple(202, '', 'Accepted'),
      tuple(203, '', 'Non-Authoritative Information'),
      tuple(204, '', 'No Content'),
      tuple(205, '', 'Reset Content'),
      tuple(206, '', 'Partial Content'),
      tuple(207, '', 'Multi-status'),
      tuple(208, '', 'Already Reported'),
      tuple(300, '', 'Multiple Choices'),
      tuple(301, '', 'Moved Permanently'),
      tuple(302, '', 'Found'),
      tuple(303, '', 'See Other'),
      tuple(304, '', 'Not Modified'),
      tuple(305, '', 'Use Proxy'),
      tuple(306, '', 'Switch Proxy'),
      tuple(307, '', 'Temporary Redirect'),
      tuple(400, '', 'Bad Request'),
      tuple(401, 'Unauthorized', 'Unauthorized'),
      tuple(402, 'Payment Required', 'Payment Required'),
      tuple(403, 'Forbidden', 'Forbidden'),
      tuple(406, 'Not Acceptable', 'Not Acceptable'),
      tuple(
        407,
        'Proxy Authentication Required',
        'Proxy Authentication Required',
      ),
      tuple(408, 'Request Time-out', 'Request Time-out'),
      tuple(409, 'Conflict', 'Conflict'),
      tuple(410, 'Gone', 'Gone'),
      tuple(404, 'what ?', 'what ?'),
      tuple(405, 'No, not this method!', 'No, not this method!'),
    ];
  }

  <<HackTest\DataProvider('provideCreateRequestData')>>
  public function testCreateRequest(
    string $method,
    Http\Message\UriInterface $uri,
  ): void {
    $factory = new Message\MessageFactory();
    $request = $factory->createRequest($method, $uri);
    expect($request->getMethod())->toBeSame($method);
    expect($request->getUri())->toBeSame($uri);
  }

  public function provideCreateRequestData(
  ): Container<(string, Http\Message\UriInterface)> {
    return vec[
      tuple('GET', Message\uri('https://nuxed.org/')),
      tuple('GET', Message\uri('/api/users')),
      tuple('GET', Message\uri('/api/users/123?size=20&page=5')),
      tuple('POST', Message\uri('/api/users')),
      tuple('POST', Message\uri('/api/photos')),
      tuple('PUT', Message\uri('/api/users/123')),
      tuple('PUT', Message\uri('/api/users/123/settings')),
      tuple('PUT', Message\uri('/api/photos/123')),
      tuple('DELETE', Message\uri('/api/photos/123')),
      tuple('FOOBAR', Message\uri('/foo/bar/baz')),
    ];
  }

  <<HackTest\DataProvider('provideCreateServerRequestData')>>
  public function testCreateServerRequest(
    string $method,
    Http\Message\UriInterface $uri,
    KeyedContainer<string, mixed> $parameters,
  ): void {
    $factory = new Message\MessageFactory();
    $request = $factory->createServerRequest($method, $uri, $parameters);
    expect($request->getServerParams())->toBeSame($parameters);
    expect($request->getMethod())->toBeSame($method);
    expect($request->getUri())->toBeSame($uri);
  }

  public function provideCreateServerRequestData(
  ): Container<
    (string, Http\Message\UriInterface, KeyedContainer<string, mixed>),
  > {
    return vec[
      tuple('GET', Message\uri('https://example.com'), dict[]),
      tuple('POST', Message\uri('https://example.com'), dict[]),
      tuple('UNSUBSCRIBE', Message\uri('https://example.com'), dict[]),
      tuple(
        'PATCH',
        Message\uri('https://example.com'),
        dict['foo' => dict['baz' => 'qux']],
      ),
      tuple(
        'POST',
        Message\uri('/bar/baz?foo=baz'),
        dict['foo' => dict['bar' => dict['qux' => 'dux']]],
      ),
      tuple('POST', Message\uri('/baz/qux'), dict['bix' => 'foo']),
      tuple(
        'FOOBAR',
        Message\uri('https://nuxed.org/foobar'),
        dict[
          'foo' => 'bar',
          'baz' => 'qux',
        ],
      ),
    ];
  }

  <<HackTest\DataProvider('provideCreateStreamData')>>
  public async function testCreateStream(string $content): Awaitable<void> {
    $factory = new Message\MessageFactory();
    $stream = $factory->createStream($content);
    $data = await $stream->readAsync();
    expect($data)->toBeSame($content);
    await $stream->closeAsync();
  }

  public function provideCreateStreamData(): Container<(string)> {
    return vec[
      tuple(''),
      tuple('foo'),
      tuple('foo bar baz'),
      tuple("foo \n bar \n baz \n qux"),
      tuple("\n"),
      tuple("\' foo \'"),
    ];
  }

  <<HackTest\DataProvider('provideCreateStreamFromFileData')>>
  public async function testCreateStreamFromFile(
    Io\File $file,
  ): Awaitable<void> {
    $content = await $file->read();

    $factory = new Message\MessageFactory();
    $stream = $factory->createStreamFromFile($file->path()->toString());
    $data = await $stream->readAsync();
    expect($data)->toBeSame($content);
  }

  <<HackTest\DataProvider('provideCreateStreamFromFileData')>>
  public async function testCreateStreamFromResources(
    Io\File $file,
  ): Awaitable<void> {
    $content = await $file->read();

    $factory = new Message\MessageFactory();
    $stream = $factory->createStreamFromResource(
      \fopen($file->path()->toString(), 'r'),
    );
    $data = await $stream->readAsync();
    expect($data)->toBeSame($content);
  }

  public async function provideCreateStreamFromFileData(
  ): Awaitable<Container<(Io\File)>> {
    $files = await Asio\v(vec[
      Io\File::temporary('nuxed-http-create-stream-from-file-test'),
      Io\File::temporary('nuxed-http-create-stream-from-file-test'),
      Io\File::temporary('nuxed-http-create-stream-from-file-test'),
      Io\File::temporary('nuxed-http-create-stream-from-file-test'),
      Io\File::temporary('nuxed-http-create-stream-from-file-test'),
      Io\File::temporary('nuxed-http-create-stream-from-file-test'),
      Io\File::temporary('nuxed-http-create-stream-from-file-test'),
    ]);

    $ops = new Vector(vec[]);
    $files = Vec\map($files, ($file) ==> {
      $ops->add($file->write(PseudoRandom\string(32)));
      return tuple($file);
    });

    await Asio\v($ops);
    return $files;
  }

  <<HackTest\DataProvider('provideCreateCookieData')>>
  public function testCreateCookie(string $value): void {
    $factory = new Message\MessageFactory();
    $cookie = $factory->createCookie($value);
    expect($cookie->getValue())->toBeSame($value);
  }

  public function provideCreateCookieData(): Container<(string)> {
    return vec[
      tuple('foo'),
      tuple('bar'),
      tuple('foo bar baz'),
      tuple(''),
    ];
  }

  <<HackTest\DataProvider('provideCreateUriData')>>
  public function testCreateUri(string $uri): void {
    $factory = new Message\MessageFactory();
    expect($factory->createUri($uri)->toString())->toBeSame($uri);
  }

  public function provideCreateUriData(): Container<(string)> {
    return vec[
      tuple('/foo/bar'),
      tuple('nuxed.org/foo/bar'),
      tuple('https://nuxed.org/'),
      tuple('https://foo.nuxed.org/foo/bar?baz=qux#dux'),
      tuple('/foo?bar=baz#qux'),
      tuple('/foo#baz'),
      tuple('https://username:password@dashboard.nuxed.org/foo?bar=baz#dux'),
    ];
  }
}
