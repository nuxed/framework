namespace Nuxed\Test\Http\Session;

use namespace Nuxed\Http;
use namespace Nuxed\Http\Session;
use namespace Nuxed\Http\Server;
use namespace Nuxed\Http\Message;
use type Facebook\HackTest\HackTest;
use function Facebook\FBExpect\expect;

class SessionMiddlewareTest extends HackTest {
  public async function testSessionMiddleware(): Awaitable<void> {
    $persistence = new DummyPersistence();
    $middleware = new Session\SessionMiddleware($persistence);
    $handler = Server\dh(
      async ($request, $response) ==> {
        expect($request->hasSession())->toBeTrue();
        $session = $request->getSession();
        expect($session->get('foo'))->toBeSame('bar');
        return $response->withAddedHeader('foo', vec['bar']);
      },
    );

    $resposne = await $middleware->process(
      new Message\ServerRequest('GET', new Message\Uri('/foo')),
      $handler,
    );

    $body = $resposne->getBody();
    await $body->flushAsync();
    $body->rewind();
    $content = await $body->readAsync();
    expect($content)->toBeSame('foo');
    expect($resposne->getHeaderLine('foo'))->toBeSame('bar');
  }
}

class DummyPersistence implements Session\Persistence\ISessionPersistence {
  public async function initialize(
    Message\ServerRequest $request,
  ): Awaitable<Session\Session> {
    return new Session\Session(dict['foo' => 'bar']);
  }

  public async function persist(
    Session\Session $session,
    Message\Response $response,
  ): Awaitable<Message\Response> {
    await $response->getBody()->writeAsync('foo');
    return $response;
  }
}
