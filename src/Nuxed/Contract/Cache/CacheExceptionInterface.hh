<?hh // strict

namespace Nuxed\Contract\Cache;

use type Exception;

/**
 * Exception interface for all exceptions thrown by an Implementing Library.
 */
interface CacheExceptionInterface {
  require extends Exception;
}
