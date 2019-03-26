namespace Nuxed\Test\Http\Server;

use namespace Nuxed\Http\Server;
use namespace Nuxed\Http\Message;
use namespace Nuxed\Contract\Http\Message as Contract;
use type Facebook\HackTest\HackTest;
use function Facebook\FBExpect\expect;
use type ReflectionClass;

class MiddlewarePipeTest extends HackTest {
  public function testHandleThrowsIfPipeIsEmpty(): void {
    $pipe = new Server\MiddlewarePipe();
    expect(() ==> $pipe->handle($this->request()))
      ->toThrow(Server\Exception\EmptyPipelineException::class);
  }

  public function testHandleThrowsIfItReachsTheEndOfThePipe(): void {
    $pipe = new Server\MiddlewarePipe();
    $pipe->pipe(
      Server\cm(($req, $next) ==> $next->handle($req))
    );
    $pipe->pipe(
      Server\cm(($req, $next) ==> $next->handle($req))
    );
    expect(() ==> $pipe->handle($this->request()))
      ->toThrow(Server\Exception\EmptyPipelineException::class);
  }

  public async function testHandle(): Awaitable<void> {
    $middleware = new Server\MiddlewarePipe();
    $middleware->pipe(
      Server\hm(Server\ch(
        async ($request) ==> $this->response($request->getAttribute('foo') as string)
      ))
    );
    $request = $this->request()->withAttribute('foo', 'bar');
    $response = await $middleware->handle($request);
    expect($response->getBody()->toString())->toBeSame('bar');
  }

  public async function testProcess(): Awaitable<void> {
    $pipe = new Server\MiddlewarePipe();
    $pipe->pipe(
      Server\cm(($req, $next) ==>
        $next->handle($req->withAttribute('test', 'a'))),
      1000
    );
    $pipe->pipe(
      Server\cm(($req, $next) ==>
        $next->handle($req->withAttribute('test', $req->getAttribute('test') as string . 'c'))),
      800
    );
    $pipe->pipe(
      Server\cm(($req, $next) ==>
        $next->handle($req->withAttribute('test', $req->getAttribute('test') as string . 'b'))),
      900
    );
    $pipe->pipe(
      Server\cm(($req, $next) ==>
        $next->handle($req->withAttribute('test', $req->getAttribute('test') as string . 'e'))),
      500
    );
    $pipe->pipe(
      Server\cm(($req, $next) ==> 
        $next->handle($req->withAttribute('test', $req->getAttribute('test') as string . 'd'))),
      700
    );

    $response = await $pipe->process(
      $this->request(),
      Server\ch(
        async ($r) ==> $this->response($r->getAttribute('test') as string)
      )
    );
    expect($response->getBody()->toString())->toBeSame('abcde');
  }

  public function testDeepClone(): void {
    $middleware = new Server\MiddlewarePipe();
    $middleware->pipe(Server\cm(($req, $next) ==> $next->handle($req)));
    $middleware->pipe(Server\cm(($req, $next) ==> $next->handle($req)));
    $clone = clone $middleware;
    $clone->pipe(Server\cm(($req, $next) ==> $next->handle($req)));

    $reflection = new ReflectionClass(Server\MiddlewarePipe::class)
      |> $$->getProperty('pipeline');
    $reflection->setAccessible(true);
    $pipeline = $reflection->getValue($middleware);
    $clonePipeline = $reflection->getValue($clone);
    expect($pipeline)->toNotBeSame($clonePipeline);
    expect($pipeline->count())->toBeSame(2);
    expect($clonePipeline->count())->toBeSame(3);
  }

  private function request(
    string $uri = '/foo'
  ): Contract\ServerRequestInterface {
    return new Message\Factory()
      |> tuple($$, $$->createUri($uri))
      |> $$[0]->createServerRequest('GET', $$[1]);
  }

  private function response(
    string $content
  ): Contract\ResponseInterface {
    return new Message\Factory() 
      |> tuple($$->createResponse(), $$->createStream($content))
      |> $$[0]->withBody($$[1]);
  }
}