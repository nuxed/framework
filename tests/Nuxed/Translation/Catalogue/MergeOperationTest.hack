namespace Nuxed\Test\Translation\Catalogue;

use namespace HH\Lib\C;
use namespace Facebook\HackTest;
use namespace Nuxed\Translation;
use namespace Nuxed\Translation\Exception;
use namespace Nuxed\Translation\Catalogue;
use function Facebook\FBExpect\expect;

class MergeOperationTest extends AbstractOperationTest {
  public function testGetMessagesFromSingleDomain(): void {
    $operation = $this->createOperation(
      new Translation\MessageCatalogue(
        'en',
        dict['messages' => dict['a' => 'old_a', 'b' => 'old_b']],
      ),
      new Translation\MessageCatalogue(
        'en',
        dict['messages' => dict['a' => 'new_a', 'c' => 'new_c']],
      ),
    );

    $messages = $operation->getMessages('messages');
    expect($messages['a'])->toBeSame('old_a');
    expect($messages['b'])->toBeSame('old_b');
    expect($messages['c'])->toBeSame('new_c');
    expect(C\count($messages))->toBeSame(3);

    $new = $operation->getNewMessages('messages');
    expect($new['c'])->toBeSame('new_c');
    expect(C\count($new))->toBeSame(1);

    $obsolete = $operation->getObsoleteMessages('messages');
    expect(C\count($obsolete))->toBeSame(0);
  }

  public function testGetResultFromSingleDomain(): void {
    $result = $this->createOperation(
      new Translation\MessageCatalogue(
        'en',
        dict['messages' => dict['a' => 'old_a', 'b' => 'old_b']],
      ),
      new Translation\MessageCatalogue(
        'en',
        dict['messages' => dict['a' => 'new_a', 'c' => 'new_c']],
      ),
    )
      ->getResult();

    expect($result->get('a'))->toBeSame('old_a');
    expect($result->get('b'))->toBeSame('old_b');
    expect($result->get('c'))->toBeSame('new_c');
  }

  protected function createOperation(
    Translation\MessageCatalogue $source,
    Translation\MessageCatalogue $target,
  ): Catalogue\IOperation {
    return new Catalogue\MergeOperation($source, $target);
  }
}
