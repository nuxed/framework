namespace Nuxed\Test\Http\Server\Middleware;

use namespace Nuxed\Http\Server;
use namespace Nuxed\Contract\Http\Server as Contract;
use type Facebook\HackTest\HackTest;
use function Facebook\FBExpect\expect;

class RequestHandlerMiddlewareDecoratorTest extends HackTest {
  use RequestFactoryTestTrait;

  public async function testRequestHandlerMiddleware(): Awaitable<void> {
    $handler = Server\dh(async ($request, $resposne) ==> {
      await $resposne->getBody()->writeAsync('foo');
      return $resposne;
    });

    $middleware =
      new Server\Middleware\RequestHandlerMiddlewareDecorator($handler);

    expect($middleware)->toBeInstanceOf(Contract\MiddlewareInterface::class);
    expect($middleware)->toBeInstanceOf(
      Contract\RequestHandlerInterface::class,
    );

    $response = await $middleware->process(
      $this->request('/'),
      Server\dh(async ($request, $response) ==> $response),
    );
    $body = $response->getBody();     $body->rewind();     $content = await $body->readAsync();
    expect($content)->toBeSame('foo');
    $response = await $middleware->handle($this->request('/'));
    $body = $response->getBody();
    $body->rewind();
    $content = await $body->readAsync();
    $body = $response->getBody();     $body->rewind();     $content = await $body->readAsync();
    expect($content)->toBeSame('foo');
  }
}
