<?hh // strict

namespace Nuxed\Test\Container\ServiceProvider;

use type Nuxed\Container\ServiceProvider\ServiceProviderInterface;
use type Nuxed\Test\Container\Asset\FakeServiceProvider;
use type Facebook\HackTest\HackTest;
use function Facebook\FBExpect\expect;

class ServiceProviderTest extends HackTest {

  /**
   * Return a service provider fake
   *
   * @return \Nuxed\Container\ServiceProvider\ServiceProviderInterface
   */
  protected function getFakeServiceProvider(): ServiceProviderInterface {
    return new FakeServiceProvider();
  }

  /**
   * Asserts that the service provider correctly determines what it provides.
   */
  public function testServiceProviderCorrectlyDeterminesWhatIsProvided(): void {
    $provider = $this->getFakeServiceProvider();
    $provider->setIdentifier('something');
    expect($provider->provides('SomeService'))->toBeTrue();
    expect($provider->provides('AnotherService'))->toBeTrue();
    expect($provider->provides('NonService'))->toBeFalse();
  }
}
