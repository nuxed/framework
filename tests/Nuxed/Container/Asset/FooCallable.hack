namespace Nuxed\Test\Container\Asset;

class FooCallable {
  public function call(Bar $bar): Foo {
    return new Foo($bar);
  }
}
