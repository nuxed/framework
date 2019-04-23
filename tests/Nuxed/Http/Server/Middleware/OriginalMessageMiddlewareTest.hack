namespace Nuxed\Test\Http\Server\Middleware;

use namespace Nuxed\Http\Server;
use type Facebook\HackTest\HackTest;
use function Facebook\FBExpect\expect;

class OriginalMessageMiddlewareTest extends HackTest {
  use RequestFactoryTestTrait;

  public async function testOriginalMessage(): Awaitable<void> {
    $originalRequest = $this->request('/foo/bar');

    $hanlder = Server\dh(async ($request, $response) ==> {
      expect($request->getHeader('X-FOO'))->toBeSame(vec['bar']);
      expect($request->getUri()->getPort())->toBeSame(8080);

      expect($request->getUri())
        ->toNotBeSame($originalRequest->getUri());
      expect($request)
        ->toNotBeSame($originalRequest);
      expect($request->getAttribute('OriginalUri'))
        ->toBeSame($originalRequest->getUri());
      expect($request->getAttribute('OriginalRequest'))
        ->toBeSame($originalRequest);

      await $response->getBody()->writeAsync('pass.');
      return $response;
    });

    $RequestModifier = Server\cm(
      ($request, $handler) ==>
        $handler->handle($request->withAddedHeader('X-FOO', vec['bar'])),
    );
    $UriModifier = Server\cm(
      ($request, $handler) ==>
        $handler->handle($request->withUri($request->getUri()->withPort(8080))),
    );

    $middleware = Server\pipe(
      new Server\Middleware\OriginalMessagesMiddleware(),
      $RequestModifier,
      $UriModifier,
    );

    $response = await $middleware->process($originalRequest, $hanlder);
    $body = $response->getBody();
    $body->rewind();
    $content = await $body->readAsync();
    expect($content)->toBeSame('pass.');
  }
}
