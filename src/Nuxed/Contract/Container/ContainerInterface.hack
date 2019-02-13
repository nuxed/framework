namespace Nuxed\Contract\Container;

use type Nuxed\Contract\Service\ResetInterface;

/**
 * Describes the interface of a container that exposes methods to read its entries.
 */
interface ContainerInterface extends ResetInterface {
  /**
   * Finds an entry of the container by its identifier and returns it.
   *
   * @param string $id Identifier of the entry to look for.
   *
   * @throws NotFoundExceptionInterface  No entry was found for **this** identifier.
   * @throws ContainerExceptionInterface Error while retrieving the entry.
   *
   * @return dynamic Entry.
   */
  public function get(string $id): dynamic;

  /**
   * Returns true if the container can return an entry for the given identifier.
   * Returns false otherwise.
   *
   * `has($id)` returning true does not mean that `get($id)` will not throw an exception.
   * It does however mean that `get($id)` will not throw a `NotFoundExceptionInterface`.
   *
   * @param string $id Identifier of the entry to look for.
   *
   * @return bool
   */
  public function has(string $id): bool;
}
