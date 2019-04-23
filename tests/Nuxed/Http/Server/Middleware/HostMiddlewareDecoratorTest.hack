namespace Nuxed\Test\Http\Server\Middleware;

use namespace Nuxed\Http\Server;
use type Facebook\HackTest\HackTest;
use function Facebook\FBExpect\expect;

class HostMiddlewareDecoratorTest extends HackTest {
  use RequestFactoryTestTrait;

  public async function testProcessCallsMiddlewareIfHostMatchs(
  ): Awaitable<void> {
    $middleware = Server\dfm(async ($request, $response, $next) ==> {
      await $response->getBody()->writeAsync('middleware');
      return $response;
    });
    $handler = Server\dh(async ($request, $response) ==> {
      await $response->getBody()->writeAsync('handler');
      return $response;
    });

    $decorator = Server\host('example.com', $middleware);
    $response = await $decorator->process(
      $this->request('https://example.com'),
      $handler,
    );

    $body = $response->getBody();
    $body->rewind();
    $content = await $body->readAsync();
    expect($content)->toBeSame('middleware');
  }

  public async function testProcessCallsHandlerIfHostDoesntMatch(
  ): Awaitable<void> {
    $middleware = Server\dfm(async ($request, $response, $next) ==> {
      await $response->getBody()->writeAsync('middleware');
      return $response;
    });
    $handler = Server\dh(async ($request, $response) ==> {
      await $response->getBody()->writeAsync('handler');
      return $response;
    });

    $decorator = new Server\Middleware\HostMiddlewareDecorator(
      'example.org',
      $middleware,
    );
    $response = await $decorator->process(
      $this->request('example.com'),
      $handler,
    );

    $body = $response->getBody();
    $body->rewind();
    $content = await $body->readAsync();
    expect($content)->toBeSame('handler');
  }

  public async function testHostIsCaseInsensitive(): Awaitable<void> {
    $middleware = Server\dfm(async ($request, $response, $next) ==> {
      await $response->getBody()->writeAsync('middleware');
      return $response;
    });
    $handler = Server\dh(async ($request, $response) ==> {
      await $response->getBody()->writeAsync('handler');
      return $response;
    });

    $decorator = Server\host('EXamplE.coM', $middleware);
    $response = await $decorator->process(
      $this->request('https://example.com/'),
      $handler,
    );

    $body = $response->getBody();
    $body->rewind();
    $content = await $body->readAsync();
    expect($content)->toBeSame('middleware');

    $decorator = Server\host('example.Com', $middleware);
    $response = await $decorator->process(
      $this->request('Https://ExamPle.com/'),
      $handler,
    );
    $body = $response->getBody();
    $body->rewind();
    $content = await $body->readAsync();
    expect($content)->toBeSame('middleware');

    $decorator = Server\host('eXaMple.Com', $middleware);
    $response = await $decorator->process(
      $this->request('Https://ExamPle.com'),
      $handler,
    );
    $body = $response->getBody();
    $body->rewind();
    $content = await $body->readAsync();
    expect($content)->toBeSame('middleware');

    $decorator = Server\host('EXAMPLE.COM', $middleware);
    $response = await $decorator->process(
      $this->request('https://example.com/'),
      $handler,
    );
    $body = $response->getBody();
    $body->rewind();
    $content = await $body->readAsync();
    expect($content)->toBeSame('middleware');

    $decorator = Server\host('example.com', $middleware);
    $response = await $decorator->process(
      $this->request('HTTPS://EXAMPLE.COM/FOO'),
      $handler,
    );
    $body = $response->getBody();
    $body->rewind();
    $content = await $body->readAsync();
    expect($content)->toBeSame('middleware');
  }
}
