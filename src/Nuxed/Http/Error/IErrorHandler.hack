namespace Nuxed\Http\Error;

use namespace Nuxed\Http\Message;

interface IErrorHandler {
  /**
   * Handle the error and return a response instance.
   */
  public function handle(
    \Throwable $error,
    Message\ServerRequest $request,
  ): Awaitable<Message\Response>;
}
