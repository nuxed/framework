namespace Nuxed\Test\Http\Server\Middleware;

use namespace Nuxed\Http\Server;
use namespace Nuxed\Http\Message;
use namespace Nuxed\Contract\Http\Message as Contract;
use type Facebook\HackTest\HackTest;

trait RequestFactoryTestTrait {
  require extends HackTest;

  final protected function request(
    string $uri,
  ): Contract\ServerRequestInterface {
    $factory = new Message\MessageFactory();
    $request = $factory->createServerRequest('GET', $factory->createUri($uri));
    return $request;
  }
}
