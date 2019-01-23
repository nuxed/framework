namespace Nuxed\Kernel\Handler;

use namespace HH\Lib\SecureRandom;
use namespace Nuxed\Contract\Http;
use function bin2hex;
use function hash_equals;

trait HandlerTrait {
  require implements Http\Server\RequestHandlerInterface;

  protected function session(
    Http\Message\ServerRequestInterface $request,
  ): Http\Session\SessionInterface {
    return $request->getAttribute('session') as Http\Session\SessionInterface;
  }

  protected function flash(
    Http\Message\ServerRequestInterface $request,
  ): Http\Flash\FlashMessagesInterface {
    return $request->getAttribute('flash') as Http\Flash\FlashMessagesInterface;
  }

  protected function generateCsrfToken(
    Http\Message\ServerRequestInterface $request,
    string $name = 'default',
  ): string {
    $session = $this->session($request);
    $token = bin2hex(SecureRandom\string(24));
    $session->set('csrf-token-'.$name, $token);
    return $token;
  }

  protected function validateCsrfToken(
    Http\Message\ServerRequestInterface $request,
    string $token,
    string $name = 'default',
  ): bool {
    $session = $this->session($request);
    $result = /* HH_IGNORE_ERROR[2049] */
    /* HH_IGNORE_ERROR[4107] */
    hash_equals($session->get('csrf-token-'.$name, '') as string, $token);
    $session->remove('csrf-token-'.$name);
    return $result;
  }
}
