<?hh // strict

namespace Nuxed\Contract\Lib;

interface Stringable {
    /**
     * Return a string representing the current object.
     */
    public function toString(): string;
}
