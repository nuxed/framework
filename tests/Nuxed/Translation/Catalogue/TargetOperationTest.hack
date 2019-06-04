namespace Nuxed\Test\Translation\Catalogue;

use namespace HH\Lib\C;
use namespace Facebook\HackTest;
use namespace Nuxed\Translation;
use namespace Nuxed\Translation\Exception;
use namespace Nuxed\Translation\Catalogue;
use function Facebook\FBExpect\expect;

class TargetOperationTest extends AbstractOperationTest {
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
    expect($messages['c'])->toBeSame('new_c');
    expect(C\count($messages))->toBeSame(2);

    $new = $operation->getNewMessages('messages');
    expect($new['c'])->toBeSame('new_c');
    expect(C\count($new))->toBeSame(1);

    $obsolete = $operation->getObsoleteMessages('messages');
    expect($obsolete['b'])->toBeSame('old_b');
    expect(C\count($obsolete))->toBeSame(1);
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
    expect($result->get('c'))->toBeSame('new_c');
    expect($result->defines('b'))->toBeFalse();
  }

  protected function createOperation(
    Translation\MessageCatalogue $source,
    Translation\MessageCatalogue $target,
  ): Catalogue\IOperation {
    return new Catalogue\TargetOperation($source, $target);
  }
}
