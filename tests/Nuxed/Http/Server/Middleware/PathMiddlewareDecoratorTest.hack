namespace Nuxed\Test\Http\Server\Middleware;

use namespace Nuxed\Http\Server;
use namespace Nuxed\Http\Message;
use type Facebook\HackTest\HackTest;
use function Facebook\FBExpect\expect;

class PathMiddlewareDecoratorTest extends HackTest {
  use RequestFactoryTestTrait;

  public async function testPathDecorator(): Awaitable<void> {
    $middleware = Server\cm(
      async ($request, $next) ==> Message\Response\text('middleware'),
    );
    $handler = Server\ch(async ($request) ==> Message\Response\text('handler'));
    $decorator = Server\path('/foo/bar', $middleware);

    $response = await $decorator->process($this->request('/bar/foo'), $handler);
    $body = $response->getBody();
    $body->rewind();
    $content = await $body->readAsync();
    expect($content)->toBeSame('handler');

    $response = await $decorator->process(
      $this->request('/foo/bar/baz'),
      $handler,
    );
    $body = $response->getBody();
    $body->rewind();
    $content = await $body->readAsync();
    expect($content)->toBeSame('middleware');

    $response = await $decorator->process($this->request('/FOO/BAR'), $handler);
    $body = $response->getBody();
    $body->rewind();
    $content = await $body->readAsync();
    expect($content)->toBeSame('middleware');

    $response = await $decorator->process(
      $this->request('https://example.com/foo/bar'),
      $handler,
    );
    $body = $response->getBody();
    $body->rewind();
    $content = await $body->readAsync();
    expect($content)->toBeSame('middleware');
  }

  public async function testHandlerIsCalledIfPathIsShorterThanPrefix(
  ): Awaitable<void> {
    $middleware = Server\cm(
      async ($request, $next) ==> Message\Response\text('middleware'),
    );
    $handler = Server\ch(async ($request) ==> Message\Response\text('handler'));
    $decorator = Server\path('/foo/bar', $middleware);

    $response = await $decorator->process($this->request('/foo'), $handler);
    $body = $response->getBody();
    $body->rewind();
    $content = await $body->readAsync();
    expect($content)->toBeSame('handler');
  }

  public async function testHandlerIsCalledIfPathDoesntContainThePrefix(
  ): Awaitable<void> {
    $middleware = Server\cm(
      async ($request, $next) ==> Message\Response\text('middleware'),
    );
    $handler = Server\ch(async ($request) ==> Message\Response\text('handler'));
    $decorator = Server\path('/foo/bar', $middleware);

    $response = await $decorator->process($this->request('/qux'), $handler);
    $body = $response->getBody();
    $body->rewind();
    $content = await $body->readAsync();
    expect($content)->toBeSame('handler');
  }

  public async function testHandlerIsCalledIfMathIsNotAtBorder(
  ): Awaitable<void> {
    $middleware = Server\cm(
      async ($request, $next) ==> Message\Response\text('middleware'),
    );
    $handler = Server\ch(async ($request) ==> Message\Response\text('handler'));
    $decorator = Server\path('/foo/bar', $middleware);

    $response = await $decorator->process(
      $this->request('/foo/barbar'),
      $handler,
    );
    $body = $response->getBody();
    $body->rewind();
    $content = await $body->readAsync();
    expect($content)->toBeSame('handler');
  }

  public async function testPrefixIsRemovedFromTheRequest(): Awaitable<void> {
    $middleware = Server\cm(
      async ($request, $next) ==> {
        expect($request->getUri()->getPath())->toBeSame('/qux');

        return Message\Response\text('middleware');
      },
    );
    $handler = Server\ch(async ($request) ==> Message\Response\text('handler'));
    $decorator = Server\path('/foo/bar', $middleware);

    $response = await $decorator->process(
      $this->request('/foo/bar/qux'),
      $handler,
    );
    $body = $response->getBody();
    $body->rewind();
    $content = await $body->readAsync();
    expect($content)->toBeSame('middleware');
  }

  public async function testHandlerAlwaysGetsOriginalPath(): Awaitable<void> {
    $middleware = Server\cm(
      ($request, $handler) ==>
        $handler->handle($request->withAttribute('foo', 'bar')),
    );
    $handler = Server\ch(async ($request) ==> {
      expect($request->getAttribute('foo'))->toBeSame('bar');
      expect($request->getUri()->getPath())->toBeSame('/foo/bar/qux');

      return Message\Response\text('handler');
    });

    $decorator = new Server\Middleware\PathMiddlewareDecorator(
      '/foo/bar',
      $middleware,
    );

    $response = await $decorator->process(
      $this->request('/foo/bar/qux'),
      $handler,
    );
    $body = $response->getBody();
    $body->rewind();
    $content = await $body->readAsync();
    expect($content)->toBeSame('handler');
  }

  public async function testEmptyPathAlwaysMatch(): Awaitable<void> {
    $middleware = Server\cm(
      async ($request, $next) ==> Message\Response\text('middleware'),
    );
    $handler = Server\ch(async ($request) ==> Message\Response\text('handler'));
    $decorator = new Server\Middleware\PathMiddlewareDecorator('', $middleware);

    $response = await $decorator->process(
      $this->request('/foo/barbar'),
      $handler,
    );
    $body = $response->getBody();
    $body->rewind();
    $content = await $body->readAsync();
    expect($content)->toBeSame('middleware');
    $response = await $decorator->process($this->request('/foo/bar'), $handler);
    $body = $response->getBody();
    $body->rewind();
    $content = await $body->readAsync();
    expect($content)->toBeSame('middleware');
    $response = await $decorator->process($this->request('/foo/'), $handler);
    $body = $response->getBody();
    $body->rewind();
    $content = await $body->readAsync();
    expect($content)->toBeSame('middleware');
    $response = await $decorator->process($this->request('/foo'), $handler);
    $body = $response->getBody();
    $body->rewind();
    $content = await $body->readAsync();
    expect($content)->toBeSame('middleware');
    $response = await $decorator->process($this->request('/'), $handler);
    $body = $response->getBody();
    $body->rewind();
    $content = await $body->readAsync();
    expect($content)->toBeSame('middleware');
    $response = await $decorator->process($this->request(''), $handler);
    $body = $response->getBody();
    $body->rewind();
    $content = await $body->readAsync();
    expect($content)->toBeSame('middleware');
  }

  public async function testForwardSlashAlwaysMatch(): Awaitable<void> {
    $middleware = Server\cm(
      async ($request, $next) ==> Message\Response\text('middleware'),
    );
    $handler = Server\ch(async ($request) ==> Message\Response\text('handler'));
    $decorator = new Server\Middleware\PathMiddlewareDecorator(
      '/',
      $middleware,
    );

    $response = await $decorator->process(
      $this->request('/foo/barbar'),
      $handler,
    );
    $body = $response->getBody();
    $body->rewind();
    $content = await $body->readAsync();
    expect($content)->toBeSame('middleware');
    $response = await $decorator->process($this->request('/foo/bar'), $handler);
    $body = $response->getBody();
    $body->rewind();
    $content = await $body->readAsync();
    expect($content)->toBeSame('middleware');
    $response = await $decorator->process($this->request('/foo/'), $handler);
    $body = $response->getBody();
    $body->rewind();
    $content = await $body->readAsync();
    expect($content)->toBeSame('middleware');
    $response = await $decorator->process($this->request('/foo'), $handler);
    $body = $response->getBody();
    $body->rewind();
    $content = await $body->readAsync();
    expect($content)->toBeSame('middleware');
    $response = await $decorator->process($this->request('/'), $handler);
    $body = $response->getBody();
    $body->rewind();
    $content = await $body->readAsync();
    expect($content)->toBeSame('middleware');
    $response = await $decorator->process($this->request(''), $handler);
    $body = $response->getBody();
    $body->rewind();
    $content = await $body->readAsync();
    expect($content)->toBeSame('middleware');
  }
}
