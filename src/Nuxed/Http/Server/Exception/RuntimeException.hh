<?hh // strict

namespace Nuxed\Http\Server\Exception;

use type RuntimeException as ParentException;

class RuntimeException extends ParentException implements ExceptionInterface {
}
