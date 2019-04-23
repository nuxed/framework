namespace Nuxed\Test\Http\Server\Middleware;

use namespace Nuxed\Http\Server;
use type Facebook\HackTest\HackTest;
use function Facebook\FBExpect\expect;

class CallableMiddlewareDecoratorTest extends HackTest {
  use RequestFactoryTestTrait;

  public async function testCallableMiddleware(): Awaitable<void> {
    $call = ($request, $handler) ==>
      $handler->handle($request->withAttribute('foo', 'bar'));

    $middleware = new Server\Middleware\CallableMiddlewareDecorator($call);

    $handler = Server\dh(async ($request, $response) ==> {
      await $response->getBody()
        ->writeAsync($request->getAttribute('foo') as string);
      return $response;
    });

    $response = await $middleware->process($this->request('/'), $handler);
    $body = $response->getBody();
    $body->rewind();
    $content = await $body->readAsync();
    expect($content)->toBeSame('bar');
  }

}
