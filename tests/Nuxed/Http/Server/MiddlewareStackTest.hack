namespace Nuxed\Test\Http\Server;

use namespace Nuxed\Http\Server;
use namespace Nuxed\Http\Message;
use type Facebook\HackTest\HackTest;
use function Facebook\FBExpect\expect;
use type ReflectionClass;

class MiddlewareStackTest extends HackTest {
  public function testHandleThrowsIfPipeIsEmpty(): void {
    $middleware = new Server\MiddlewareStack();
    expect(() ==> $middleware->handle($this->request()))
      ->toThrow(Server\Exception\EmptyStackException::class);
  }

  public function testHandleThrowsIfItReachsTheEndOfThePipe(): void {
    $middleware = new Server\MiddlewareStack();
    $middleware->stack(Server\cm(($req, $next) ==> $next->handle($req)));
    $middleware->stack(Server\cm(($req, $next) ==> $next->handle($req)));
    expect(() ==> $middleware->handle($this->request()))
      ->toThrow(Server\Exception\EmptyStackException::class);
  }

  public async function testHandle(): Awaitable<void> {
    $middleware = new Server\MiddlewareStack();
    $middleware->stack(
      Server\hm(Server\ch(
        async ($request) ==>
          $this->response($request->getAttribute('foo') as string),
      )),
    );
    $request = $this->request()->withAttribute('foo', 'bar');
    $response = await $middleware->handle($request);
    $content = await $response->getBody()->readAsync();
    expect($content)->toBeSame('bar');
  }

  public async function testProcess(): Awaitable<void> {
    $middleware = new Server\MiddlewareStack();
    $middleware->stack(
      Server\cm(
        ($req, $next) ==> $next->handle($req->withAttribute('test', 'a')),
      ),
      1000,
    );
    $middleware->stack(
      Server\cm(
        ($req, $next) ==> $next->handle(
          $req->withAttribute('test', $req->getAttribute('test') as string.'c'),
        ),
      ),
      800,
    );
    $middleware->stack(
      Server\cm(
        ($req, $next) ==> $next->handle(
          $req->withAttribute('test', $req->getAttribute('test') as string.'b'),
        ),
      ),
      900,
    );
    $middleware->stack(
      Server\cm(
        ($req, $next) ==> $next->handle(
          $req->withAttribute('test', $req->getAttribute('test') as string.'e'),
        ),
      ),
      500,
    );
    $middleware->stack(
      Server\cm(
        ($req, $next) ==> $next->handle(
          $req->withAttribute('test', $req->getAttribute('test') as string.'d'),
        ),
      ),
      700,
    );

    $response = await $middleware->process(
      $this->request(),
      Server\ch(
        async ($r) ==> $this->response($r->getAttribute('test') as string),
      ),
    );
    $content = await $response->getBody()->readAsync();
    expect($content)->toBeSame('abcde');
  }

  public function testDeepClone(): void {
    $middleware = new Server\MiddlewareStack();
    $middleware->stack(Server\cm(($req, $next) ==> $next->handle($req)));
    $middleware->stack(Server\cm(($req, $next) ==> $next->handle($req)));
    $clone = clone $middleware;
    $clone->stack(Server\cm(($req, $next) ==> $next->handle($req)));

    $reflection = new ReflectionClass(Server\MiddlewareStack::class)
      |> $$->getProperty('pipeline');
    $reflection->setAccessible(true);
    $pipeline = $reflection->getValue($middleware);
    $clonePipeline = $reflection->getValue($clone);
    expect($pipeline)->toNotBeSame($clonePipeline);
    expect($pipeline->count())->toBeSame(2);
    expect($clonePipeline->count())->toBeSame(3);
  }

  private function request(string $uri = '/foo'): Message\ServerRequest {
    return new Message\ServerRequest('GET', Message\uri($uri));
  }

  private function response(string $content): Message\Response {
    return Message\Response\text($content);
  }
}
