namespace Nuxed\Test\Container\Asset;

use type Nuxed\Container\Container;
use type Nuxed\Container\ServiceProvider\AbstractServiceProvider;

class FooServiceProvider extends AbstractServiceProvider {
  protected vec<string> $provides = vec[
    Foo::class,
  ];

  <<__Override>>
  public function register(Container $c): void {
    $c->add(Foo::class);
  }
}
