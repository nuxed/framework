<?hh // strict

namespace Nuxed\Test\Container\Asset;

class FooCallable {
  public function __invoke(Bar $bar): Foo {
    return new Foo($bar);
  }
}
