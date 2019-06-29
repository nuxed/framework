namespace Nuxed\Container\Service;

use namespace Nuxed\Container;

class NewableFactoryDecorator<<<__Newable>>T as Newable>
  implements Container\IFactory<T> {

  public function __construct(private classname<T> $service) {}

  public function create(?Container\IServiceContainer $_ = null): T {
    $class = $this->service;
    return new $class();
  }
}
