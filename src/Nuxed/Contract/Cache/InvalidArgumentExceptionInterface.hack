namespace Nuxed\Contract\Cache;

use type InvalidArgumentException;

/**
 * Exception interface for invalid cache arguments.
 *
 * Any time an invalid argument is passed into a method it must throw an
 * exception class which implements Nuxed\Contract\Cache\InvalidArgumentException.
 */
interface InvalidArgumentExceptionInterface extends CacheExceptionInterface {
  require extends InvalidArgumentException;
}
