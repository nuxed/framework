namespace Nuxed\Http\Session\Persistence;

use namespace Nuxed\Http\Message;
use namespace Nuxed\Http\Session;

interface ISessionPersistence {
  /**
   * Generate a session data instance based on the request.
   */
  public function initialize(
    Message\ServerRequest $request,
  ): Awaitable<Session\Session>;

  /**
   * Persist the session data instance
   *
   * Persists the session data, returning a response instance with any
   * artifacts required to return to the client.
   */
  public function persist(
    Session\Session $session,
    Message\Response $response,
  ): Awaitable<Message\Response>;
}
