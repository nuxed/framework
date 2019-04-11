namespace Nuxed\Contract\Http\Message;

interface CookieFactoryInterface {
  /**
   * Create a new cookie.
   *
   * @param string $value The value associated with the cookie.
   */
  public function createCookie(string $value): CookieInterface;
}
