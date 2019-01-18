<?hh // strict

namespace Nuxed\Mix\ServiceProvider;

use type Nuxed\Container\ServiceProvider\AbstractServiceProvider as ServiceProvider
;
use type Nuxed\Mix\Configuration;

abstract class AbstractServiceProvider extends ServiceProvider {
  <<__Override>>
  public function __construct(protected Configuration $config) {
    parent::__construct();
  }
}
