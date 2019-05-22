namespace Nuxed\Test\Http\Server\Middleware;

use namespace Nuxed\Http\Server;
use namespace Nuxed\Http\Message;
use type Facebook\HackTest\HackTest;

trait RequestFactoryTestTrait {
  require extends HackTest;

  final protected function request(string $uri): Message\ServerRequest {
    return new Message\ServerRequest('GET', Message\uri($uri));
  }
}
