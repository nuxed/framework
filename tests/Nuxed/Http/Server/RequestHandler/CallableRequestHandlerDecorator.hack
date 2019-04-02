namespace Nuxed\Test\Http\Server\RequestHandler;

use namespace Nuxed\Http\Server;
use namespace Nuxed\Http\Message;
use type Facebook\HackTest\HackTest;
use function Facebook\FBExpect\expect;

class CallableRequestHandlerDecoratorTest extends HackTest {
  public async function testCallableMiddleware(): Awaitable<void> {
    $resposne = new Message\Response\TextResponse('foo');
    $call = async ($request) ==> $resposne;
    $handler = new Server\RequestHandler\CallableRequestHandlerDecorator($call);
    $return = await $handler->handle(
      new Message\ServerRequest('GET', new Message\Uri('/')),
    );
    expect($return)->toBeSame($resposne);
  }
}
