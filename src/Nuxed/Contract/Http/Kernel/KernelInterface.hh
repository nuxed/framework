<?hh // strict

namespace Nuxed\Contract\Http\Kernel;

use type Nuxed\Contract\Http\Server\MiddlewarePipeInterface;
use type Nuxed\Contract\Http\Emitter\EmitterInterface;
use type Nuxed\Contract\Http\Message\ServerRequestInterface;
use type Nuxed\Contract\Http\Message\ResponseInterface;
use type Nuxed\Contract\Http\Router\RouteCollectorInterface;

interface KernelInterface
  extends MiddlewarePipeInterface, EmitterInterface, RouteCollectorInterface {
  /**
   * Perform any final actions for the request lifecycle.
   */
  public function terminate(
    ServerRequestInterface $request,
    ResponseInterface $response,
  ): void;
}
