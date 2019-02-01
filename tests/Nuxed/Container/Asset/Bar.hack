namespace Nuxed\Test\Container\Asset;

class Bar {
  protected int $something = 1;

  public function setSomething(int $something): void {
    $this->something = $something;
  }
}
