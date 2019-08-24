namespace Nuxed\Test\Http\Server\Handler;

use namespace Nuxed\Http\Server;
use namespace Nuxed\Http\Message;
use type Facebook\HackTest\HackTest;
use function Facebook\FBExpect\expect;

class CallableHandlerDecoratorTest extends HackTest {
  public async function testCallableMiddleware(): Awaitable<void> {
    $resposne = Message\Response\text('foo');
    $call = async ($request) ==> $resposne;
    $handler = new Server\Handler\CallableHandlerDecorator($call);
    $return = await $handler->handle(
      new Message\ServerRequest('GET', new Message\Uri('/')),
    );
    expect($return)->toBeSame($resposne);
  }
}
