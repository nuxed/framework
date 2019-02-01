namespace Nuxed\Test\Container\ServiceProvider;

use type Facebook\HackTest\HackTest;
use type Nuxed\Container\Container;
use type Nuxed\Container\Exception\ContainerException;
use type Nuxed\Test\Container\Asset\FakeServiceProvider;
use type Nuxed\Container\ServiceProvider\ServiceProviderAggregate;
use function Facebook\FBExpect\expect;

class ServiceProviderAggregateTest extends HackTest {
  /**
   * Return a service provider fake
   *
   * @return \Nuxed\Container\ServiceProvider\ServiceProviderInterface
   */
  protected function getServiceProvider(): FakeServiceProvider {
    return new FakeServiceProvider();
  }

  /**
   * Asserts that the aggregate adds a class name service provider.
   */
  public function testAggregateAddsClassNameServiceProvider(): void {
    $aggregate = new ServiceProviderAggregate();

    $serviceProvider = $this->getServiceProvider();
    $serviceProvider->setIdentifier('foo');
    $aggregate->add($serviceProvider);

    list($provides, $provider) = $aggregate->provides('SomeService');
    expect($provides)->toBeTrue();
    expect($provider)->toBeSame('foo');
    list($provides, $provider) = $aggregate->provides('AnotherService');
    expect($provides)->toBeTrue();
    expect($provider)->toBeSame('foo');
    list($provides, $provider) = $aggregate->provides('NonExisten');
    expect($provides)->toBeFalse();
    expect($provider)->toBeNull();
  }

  /**
   * Asserts that an exception is thrown when attempting to invoke the register
   * method of a service provider that has not been provided.
   */
  public function testAggregateThrowsWhenRegisteringForServiceThatIsNotAdded(
  ): void {
    expect(() ==> {
      $container = new Container();
      $aggregate = new ServiceProviderAggregate();
      $aggregate->register('SomeService', $container);
    })->toThrow(ContainerException::class);
  }

  /**
   * Asserts that resgister method is only invoked once per service provider.
   */
  public function testAggregateInvokesCorrectRegisterMethodOnlyOnce(): void {
    $aggregate = new ServiceProviderAggregate();
    $provider = $this->getServiceProvider();

    $aggregate->add($provider);

    $container = new Container();
    $aggregate->register('SomeService', $container);
    $aggregate->register('AnotherService', $container);

    expect($provider->registered)->toBeSame(1);
  }
}
