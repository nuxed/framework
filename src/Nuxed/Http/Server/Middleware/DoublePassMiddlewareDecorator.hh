<?hh // strict

namespace Nuxed\Http\Server\Middleware;

use type Nuxed\Contract\Http\Message\ResponseInterface;
use type Nuxed\Contract\Http\Message\ServerRequestInterface;
use type Nuxed\Contract\Http\Server\MiddlewareInterface;
use type Nuxed\Contract\Http\Server\RequestHandlerInterface;
use type Nuxed\Http\Message\Response;

class DoublePassMiddlewareDecorator implements MiddlewareInterface {
  public function __construct(
    private (function(
      ServerRequestInterface,
      ResponseInterface,
      RequestHandlerInterface,
    ): ResponseInterface) $call,
    private ResponseInterface $response = new Response(),
  ) {}

  public function process(
    ServerRequestInterface $request,
    RequestHandlerInterface $handler,
  ): ResponseInterface {
    $fun = $this->call;
    return $fun($request, $this->response, $handler);
  }
}
