namespace Nuxed\Test\Container\Asset;

use type Nuxed\Container\Container;
use type Nuxed\Container\ServiceProvider\AbstractServiceProvider;
use type Nuxed\Container\ServiceProvider\BootableServiceProviderInterface;

class FakeServiceProvider
  extends AbstractServiceProvider
  implements BootableServiceProviderInterface {
  protected vec<string> $provides = vec[
    'SomeService',
    'AnotherService',
  ];

  public int $registered = 0;

  public function boot(): void {
    // noop
  }

  <<__Override>>
  public function register(Container $c): void {
    $this->registered++;

    $c->add('SomeService', function(mixed $arg): mixed {
      return $arg;
    });
  }

}
