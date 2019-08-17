namespace Nuxed\Http\Error;

use namespace Nuxed\Http\{Message, Server};
use namespace Nuxed\Http\Message\Response;

class ErrorHandler implements IErrorHandler {
  public function __construct(protected bool $debug) {}

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
    Message\ServerRequest $_request,
  ): Awaitable<Message\Response> {
    if ($error is Server\Exception\ServerException) {
      $status = $error->getStatusCode();
    } else {
      $status = (int)$error->getCode();
      if ($status < 400 || $status > 600) {
        $status = 500;
      }
    }

    if (!$this->debug) {
      return new Response\JsonResponse(
        dict[
          'status' => 'error',
          'message' => Message\Response::$phrases[$status] ??
            Message\Response::$phrases[500],
          'code' => $status,
        ],
        $status,
        $error is Server\Exception\ServerException
          ? $error->getHeaders()
          : dict[],
      );
    }

    return new Response\JsonResponse(
      dict[
        'status' => 'error',
        'message' => $error->getMessage(),
        'code' => $status,
        'data' => dict[
          'file' => $error->getFile(),
          'line' => $error->getLine(),
          'trace' => $error->getTrace(),
        ],
      ],
      $status,
      $error is Server\Exception\ServerException
        ? $error->getHeaders()
        : dict[],
    );
  }
}
