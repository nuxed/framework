namespace Nuxed\Test\Http\Server\Middleware;

use namespace Nuxed\Http\Server;
use namespace Nuxed\Http\Message;
use type Facebook\HackTest\HackTest;
use function Facebook\FBExpect\expect;

class PathMiddlewareDecoratorTest extends HackTest {
  use RequestFactoryTestTrait;

  public async function testPathDecorator(): Awaitable<void> {
    $middleware = Server\cm(
      async ($request, $next) ==>
        new Message\Response\TextResponse('middleware'),
    );
    $handler = Server\ch(
      async ($request) ==> new Message\Response\TextResponse('handler'),
    );
    $decorator = Server\path('/foo/bar', $middleware);

    $response = await $decorator->process($this->request('/bar/foo'), $handler);
    expect($response->getBody()->toString())->toBeSame('handler');

    $response =
      await $decorator->process($this->request('/foo/bar/baz'), $handler);
    expect($response->getBody()->toString())->toBeSame('middleware');

    $response = await $decorator->process($this->request('/FOO/BAR'), $handler);
    expect($response->getBody()->toString())->toBeSame('middleware');

    $response = await $decorator->process(
      $this->request('https://example.com/foo/bar'),
      $handler,
    );
    expect($response->getBody()->toString())->toBeSame('middleware');
  }

  public async function testHandlerIsCalledIfPathIsShorterThanPrefix(
  ): Awaitable<void> {
    $middleware = Server\cm(
      async ($request, $next) ==>
        new Message\Response\TextResponse('middleware'),
    );
    $handler = Server\ch(
      async ($request) ==> new Message\Response\TextResponse('handler'),
    );
    $decorator = Server\path('/foo/bar', $middleware);

    $response = await $decorator->process($this->request('/foo'), $handler);
    expect($response->getBody()->toString())->toBeSame('handler');
  }

  public async function testHandlerIsCalledIfPathDoesntContainThePrefix(
  ): Awaitable<void> {
    $middleware = Server\cm(
      async ($request, $next) ==>
        new Message\Response\TextResponse('middleware'),
    );
    $handler = Server\ch(
      async ($request) ==> new Message\Response\TextResponse('handler'),
    );
    $decorator = Server\path('/foo/bar', $middleware);

    $response = await $decorator->process($this->request('/qux'), $handler);
    expect($response->getBody()->toString())->toBeSame('handler');
  }

  public async function testHandlerIsCalledIfMathIsNotAtBorder(
  ): Awaitable<void> {
    $middleware = Server\cm(
      async ($request, $next) ==>
        new Message\Response\TextResponse('middleware'),
    );
    $handler = Server\ch(
      async ($request) ==> new Message\Response\TextResponse('handler'),
    );
    $decorator = Server\path('/foo/bar', $middleware);

    $response =
      await $decorator->process($this->request('/foo/barbar'), $handler);
    expect($response->getBody()->toString())->toBeSame('handler');
  }

  public async function testPrefixIsRemovedFromTheRequest(): Awaitable<void> {
    $middleware = Server\cm(
      async ($request, $next) ==> {
        expect($request->getUri()->getPath())->toBeSame('/qux');

        return new Message\Response\TextResponse('middleware');
      },
    );
    $handler = Server\ch(
      async ($request) ==> new Message\Response\TextResponse('handler'),
    );
    $decorator = Server\path('/foo/bar', $middleware);

    $response =
      await $decorator->process($this->request('/foo/bar/qux'), $handler);
    expect($response->getBody()->toString())->toBeSame('middleware');
  }

  public async function testHandlerAlwaysGetsOriginalPath(): Awaitable<void> {
    $middleware = Server\cm(
      ($request, $handler) ==>
        $handler->handle($request->withAttribute('foo', 'bar')),
    );
    $handler = Server\ch(async ($request) ==> {
      expect($request->getAttribute('foo'))->toBeSame('bar');
      expect($request->getUri()->getPath())->toBeSame('/foo/bar/qux');

      return new Message\Response\TextResponse('handler');
    });

    $decorator =
      new Server\Middleware\PathMiddlewareDecorator('/foo/bar', $middleware);

    $response =
      await $decorator->process($this->request('/foo/bar/qux'), $handler);
    expect($response->getBody()->toString())->toBeSame('handler');
  }

  public async function testEmptyPathAlwaysMatch(): Awaitable<void> {
    $middleware = Server\cm(
      async ($request, $next) ==>
        new Message\Response\TextResponse('middleware'),
    );
    $handler = Server\ch(
      async ($request) ==> new Message\Response\TextResponse('handler'),
    );
    $decorator = new Server\Middleware\PathMiddlewareDecorator('', $middleware);

    $response =
      await $decorator->process($this->request('/foo/barbar'), $handler);
    expect($response->getBody()->toString())->toBeSame('middleware');
    $response = await $decorator->process($this->request('/foo/bar'), $handler);
    expect($response->getBody()->toString())->toBeSame('middleware');
    $response = await $decorator->process($this->request('/foo/'), $handler);
    expect($response->getBody()->toString())->toBeSame('middleware');
    $response = await $decorator->process($this->request('/foo'), $handler);
    expect($response->getBody()->toString())->toBeSame('middleware');
    $response = await $decorator->process($this->request('/'), $handler);
    expect($response->getBody()->toString())->toBeSame('middleware');
    $response = await $decorator->process($this->request(''), $handler);
    expect($response->getBody()->toString())->toBeSame('middleware');
  }

  public async function testForwardSlashAlwaysMatch(): Awaitable<void> {
    $middleware = Server\cm(
      async ($request, $next) ==>
        new Message\Response\TextResponse('middleware'),
    );
    $handler = Server\ch(
      async ($request) ==> new Message\Response\TextResponse('handler'),
    );
    $decorator =
      new Server\Middleware\PathMiddlewareDecorator('/', $middleware);

    $response =
      await $decorator->process($this->request('/foo/barbar'), $handler);
    expect($response->getBody()->toString())->toBeSame('middleware');
    $response = await $decorator->process($this->request('/foo/bar'), $handler);
    expect($response->getBody()->toString())->toBeSame('middleware');
    $response = await $decorator->process($this->request('/foo/'), $handler);
    expect($response->getBody()->toString())->toBeSame('middleware');
    $response = await $decorator->process($this->request('/foo'), $handler);
    expect($response->getBody()->toString())->toBeSame('middleware');
    $response = await $decorator->process($this->request('/'), $handler);
    expect($response->getBody()->toString())->toBeSame('middleware');
    $response = await $decorator->process($this->request(''), $handler);
    expect($response->getBody()->toString())->toBeSame('middleware');
  }
}
