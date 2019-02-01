namespace Nuxed\Test\Asset;

use namespace Nuxed\Asset;
use type Facebook\HackTest\HackTest;
use function Facebook\FBExpect\expect;

class PackagesTest extends HackTest {

  public function testConstruct(): void {
    $foo = new Asset\Package(new Asset\VersionStrategy\EmptyVersionStrategy());
    $bar = new Asset\Package(new Asset\VersionStrategy\EmptyVersionStrategy());
    $packages = new Asset\Packages($foo, dict[
      'bar' => $bar,
    ]);
    expect($packages->getPackage())->toBeSame($foo);
    expect($packages->getPackage('bar'))->toBeSame($bar);
  }

  public function testGetterSetters(): void {
    $foo = new Asset\Package(new Asset\VersionStrategy\EmptyVersionStrategy());
    $bar = new Asset\Package(new Asset\VersionStrategy\EmptyVersionStrategy());
    $packages = new Asset\Packages();
    $packages->setDefaultPackage($foo);
    $packages->addPackage('bar', $bar);
    expect($packages->getPackage())->toBeSame($foo);
    expect($packages->getPackage('bar'))->toBeSame($bar);
  }

  public function testGetVersion(): void {
    $packages = new Asset\Packages(
      new Asset\Package(
        new Asset\VersionStrategy\StaticVersionStrategy('default'),
      ),
      dict[
        'a' => new Asset\Package(
          new Asset\VersionStrategy\StaticVersionStrategy('a'),
        ),
      ],
    );
    expect($packages->getVersion('/foo'))->toBeSame('default');
    expect($packages->getVersion('/foo', 'a'))->toBeSame('a');
  }

  public function testGetUrl(): void {
    $packages = new Asset\Packages(
      new Asset\Package(
        new Asset\VersionStrategy\StaticVersionStrategy('default'),
      ),
      dict[
        'a' => new Asset\Package(
          new Asset\VersionStrategy\StaticVersionStrategy('a'),
        ),
      ],
    );
    expect($packages->getUrl('/foo'))->toBeSame('/foo?default');
    expect($packages->getUrl('/foo', 'a'))->toBeSame('/foo?a');
  }

  public function testNoDefaultPackage(): void {
    $this->setExpectedException(
      Asset\Exception\LogicException::class,
      'There is no default asset package, configure one first.',
    );

    $packages = new Asset\Packages();
    $packages->getPackage();
  }

  public function testUndefinedPackage(): void {
    $this->setExpectedException(
      Asset\Exception\InvalidArgumentException::class,
      'There is no "foo" asset package.',
    );

    $packages = new Asset\Packages();
    $packages->getPackage('foo');
  }
}
