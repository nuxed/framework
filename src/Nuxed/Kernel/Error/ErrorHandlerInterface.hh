<?hh // strict

namespace Nuxed\Kernel\Error;

use type Nuxed\Contract\Http\Message\ServerRequestInterface;
use type Nuxed\Contract\Http\Message\ResponseInterface;
use type Throwable;

interface ErrorHandlerInterface {
  /**
   * Handle the error and return a response instance.
   */
  public function handle(
    Throwable $error,
    ServerRequestInterface $request,
  ): Awaitable<ResponseInterface>;
}
