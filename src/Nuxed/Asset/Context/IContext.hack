namespace Nuxed\Asset\Context;

interface IContext {
  /**
   * Gets the base path.
   *
   * @return string The base path
   */
  public function getBasePath(): string;

  /**
   * Checks whether the request is secure or not.
   *
   * @return bool true if the request is secure, false otherwise
   */
  public function isSecure(): bool;
}
