<?hh // strict

namespace Nuxed\Container\ServiceProvider;

use namespace HH\Lib\C;
use function get_class;

abstract class AbstractServiceProvider implements ServiceProviderInterface {
  protected vec<string> $provides = vec[];

  protected string $identifier;

  public function __construct() {
    $this->identifier = get_class($this);
  }

  /**
   * {@inheritdoc}
   */
  public function provides(string $alias): bool {
    return C\contains($this->provides, $alias);
  }

  /**
   * {@inheritdoc}
   */
  public function setIdentifier(string $id): ServiceProviderInterface {
    $this->identifier = $id;

    return $this;
  }

  /**
   * {@inheritdoc}
   */
  public function getIdentifier(): string {
    return $this->identifier;
  }
}
