namespace Nuxed\Contract\Container;

use type Exception;

/**
 * Base interface representing a generic exception in a container.
 */
interface ContainerExceptionInterface {
  require extends Exception;
}
