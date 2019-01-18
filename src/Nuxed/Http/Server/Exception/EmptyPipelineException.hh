<?hh // strict

namespace Nuxed\Http\Server\Exception;

use namespace HH\Lib\Str;
use type Nuxed\Contract\Http\Server\MiddlewarePipeInterface;
use type OutOfBoundsException;

<<__ConsistentConstruct>>
class EmptyPipelineException
  extends OutOfBoundsException
  implements ExceptionInterface {
  public static function forClass(
    classname<MiddlewarePipeInterface> $class,
  ): this {
    return new static(Str\format(
      '%s cannot handle request; no middleware available to process the request',
      $class,
    ));
  }
}
