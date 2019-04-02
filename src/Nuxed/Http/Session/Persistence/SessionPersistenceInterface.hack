namespace Nuxed\Http\Session\Persistence;

use type Nuxed\Contract\Http\Message\ServerRequestInterface;
use type Nuxed\Contract\Http\Message\ResponseInterface;
use type Nuxed\Contract\Http\Session\SessionInterface;

interface SessionPersistenceInterface {
  /**
   * Generate a session data instance based on the request.
   */
  public function initialize(ServerRequestInterface $request): Awaitable<SessionInterface>;

  /**
   * Persist the session data instance
   *
   * Persists the session data, returning a response instance with any
   * artifacts required to return to the client.
   */
  public function persist(
    SessionInterface $session,
    ResponseInterface $response,
  ): Awaitable<ResponseInterface>;
}
