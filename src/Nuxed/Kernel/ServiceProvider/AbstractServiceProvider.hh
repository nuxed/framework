<?hh // strict

namespace Nuxed\Kernel\ServiceProvider;

use type Nuxed\Container\ServiceProvider\AbstractServiceProvider as ServiceProvider
;
use type Nuxed\Kernel\Configuration;

abstract class AbstractServiceProvider extends ServiceProvider {
  protected function config(): Configuration {
    // UNSAFE
    return $this->getContainer()->get('config');
  }
}
