namespace Nuxed\Contract\Http\Client;

use type Exception;

/**
 * Every HTTP client related exception MUST implement this interface.
 */
interface ClientExceptionInterface {
  require extends Exception;
}
