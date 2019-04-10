namespace Nuxed\Test\Http\Session;

use namespace Nuxed\Contract\Http;
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
        $session = $request->getAttribute('session');
        expect($session)->toBeInstanceOf(Http\Session\SessionInterface::class);
        $session as Http\Session\SessionInterface;
        expect($session->get('foo'))->toBeSame('bar');
        return $response->withAddedHeader('foo', vec['bar']);
      },
    );

    $resposne = await $middleware->process(
      new Message\ServerRequest('GET', new Message\Uri('/foo')),
      $handler,
    );

    $content = await $resposne->getBody()->readAsync();
    expect($content)->toBeSame('foo');
    expect($resposne->getHeaderLine('foo'))->toBeSame('bar');
  }

}

class DummyPersistence
  implements Session\Persistence\SessionPersistenceInterface {
  public async function initialize(
    Http\Message\ServerRequestInterface $request,
  ): Awaitable<Http\Session\SessionInterface> {
    return new Session\Session(dict['foo' => 'bar']);
  }

  public async function persist(
    Http\Session\SessionInterface $session,
    Http\Message\ResponseInterface $response,
  ): Awaitable<Http\Message\ResponseInterface> {
    await $response->getBody()->writeAsync('foo');
    return $response;
  }
}
