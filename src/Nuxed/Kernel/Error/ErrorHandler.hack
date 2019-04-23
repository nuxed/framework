namespace Nuxed\Kernel\Error;

use namespace Nuxed\Http\Message\Response;
use namespace Nuxed\Http\Message;
use namespace Nuxed\Contract\Event;
use type Nuxed\Contract\Http\Message\ServerRequestInterface;
use type Nuxed\Contract\Http\Message\ResponseInterface;
use type Nuxed\Kernel\Event\ErrorEvent;
use type Throwable;

class ErrorHandler implements ErrorHandlerInterface {
  public function __construct(
    protected bool $debug,
    protected Event\EventDispatcherInterface $events,
  ) {}

  /**
   * Handle the error and return a response instance.
   *
   * This ErrorHandler returns a JsonResponse with formatted exception data following
   * the JSend specifications in debug-mode, a simple json-formatted error response
   * otherwise.
   *
   * @link https://labs.omniti.com/labs/jsend
   */
  public async function handle(
    Throwable $error,
    ServerRequestInterface $request,
  ): Awaitable<ResponseInterface> {
    $event = await $this->events->dispatch(new ErrorEvent($error, $request));

    if ($event->response is nonnull) {
      return $event->response;
    }

    $code = (int)$error->getCode();
    if ($code < 400 || $code > 600) {
      $code = 500;
    }

    if (!$this->debug) {
      return new Response\JsonResponse(
        dict[
          'status' => 'error',
          'message' => Message\Response::$phrases[$code] ??
            Message\Response::$phrases[500],
          'code' => $code,
        ],
        $code,
      );
    }

    return new Response\JsonResponse(
      dict[
        'status' => 'error',
        'message' => $error->getMessage(),
        'code' => $code,
        'data' => dict[
          'file' => $error->getFile(),
          'line' => $error->getLine(),
          'trace' => $error->getTrace(),
        ],
      ],
      $code,
    );
  }
}
