namespace Nuxed\Kernel\Handler;

use namespace HH\Lib\SecureRandom;
use namespace Nuxed\Http;

trait HandlerTrait {
  require implements Http\Server\IRequestHandler;

  protected function generateCsrfToken(
    Http\Message\ServerRequest $request,
    string $name = 'default',
  ): string {
    $session = $request->getSession();
    $token = \bin2hex(SecureRandom\string(24));
    $session->put('csrf-token-'.$name, $token);
    return $token;
  }

  protected function validateCsrfToken(
    Http\Message\ServerRequest $request,
    string $token,
    string $name = 'default',
  ): bool {
    $session = $request->getSession();
    $result = /* HH_IGNORE_ERROR[2049] */
    /* HH_IGNORE_ERROR[4107] */
    hash_equals($session->get('csrf-token-'.$name, '') as string, $token);
    $session->forget('csrf-token-'.$name);
    return $result;
  }
}
