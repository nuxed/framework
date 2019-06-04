namespace Nuxed\Test\Translation\Catalogue;

use namespace HH\Lib\C;
use namespace Facebook\HackTest;
use namespace Nuxed\Translation;
use namespace Nuxed\Translation\Exception;
use namespace Nuxed\Translation\Catalogue;
use function Facebook\FBExpect\expect;

abstract class AbstractOperationTest extends HackTest\HackTest {
  public function testGetEmptyDomains(): void {
    $op = $this->createOperation(
      new Translation\MessageCatalogue('en'),
      new Translation\MessageCatalogue('en'),
    );

    expect(C\count($op->getDomains()))->toBeSame(0);
  }

  public function testMergedDomains(): void {
    $op = $this->createOperation(
      new Translation\MessageCatalogue(
        'en',
        dict['a' => dict[], 'b' => dict[]],
      ),
      new Translation\MessageCatalogue(
        'en',
        dict['b' => dict[], 'c' => dict[]],
      ),
    );

    $domains = $op->getDomains();
    expect($domains)->toContain('a');
    expect($domains)->toContain('b');
    expect($domains)->toContain('c');
  }

  public function testGetMessagesFromUnknownDomain(): void {
    $op = $this->createOperation(
      new Translation\MessageCatalogue('en'),
      new Translation\MessageCatalogue('en'),
    );

    expect(() ==> $op->getMessages('domain'))
      ->toThrow(Exception\InvalidArgumentException::class);
    expect(() ==> $op->getNewMessages('domain'))
      ->toThrow(Exception\InvalidArgumentException::class);
    expect(() ==> $op->getObsoleteMessages('domain'))
      ->toThrow(Exception\InvalidArgumentException::class);
  }

  public function testGetEmptyMessages(): void {
    $op = $this->createOperation(
      new Translation\MessageCatalogue('en', dict['a' => dict[]]),
      new Translation\MessageCatalogue('en'),
    );

    expect(C\count($op->getMessages('a')))
      ->toBeSame(0);
  }

  public function testGetEmptyResult(): void {
    $result = $this->createOperation(
      new Translation\MessageCatalogue('en'),
      new Translation\MessageCatalogue('en'),
    )
      ->getResult();

    expect($result->getLocale())->toBeSame('en');
    expect(C\count($result->getDomains()))->toBeSame(0);
  }

  abstract protected function createOperation(
    Translation\MessageCatalogue $source,
    Translation\MessageCatalogue $target,
  ): Catalogue\IOperation;
}
