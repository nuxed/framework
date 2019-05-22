namespace Nuxed\Kernel\Error;

use namespace Nuxed\Kernel\Event;
use namespace Nuxed\Http\Message;
use namespace Nuxed\EventDispatcher;
use namespace Nuxed\Http\Message\Response;

class ErrorHandler implements IErrorHandler {
  public function __construct(
    protected bool $debug,
    protected EventDispatcher\IEventDispatcher $events,
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
    \Throwable $error,
    Message\ServerRequest $request,
  ): Awaitable<Message\Response> {
    $event = await $this->events
      ->dispatch(new Event\ErrorEvent($error, $request));

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
