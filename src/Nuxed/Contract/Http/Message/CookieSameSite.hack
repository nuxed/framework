namespace Nuxed\Contract\Http\Message;

/**
 * Enum representing the cookie Same-Site values.
 *
 * @link https://tools.ietf.org/html/draft-west-first-party-cookies-07#section-3.1
 */
enum CookieSameSite: string {
  LAX = 'Lax';
  STRICT = 'Strict';
}
