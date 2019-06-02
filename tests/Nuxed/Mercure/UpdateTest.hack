namespace Nuxed\Test\Mercure;

use namespace Nuxed\Mercure;
use namespace Nuxed\Http\Client;
use namespace Nuxed\Http\Message;
use namespace Facebook\HackTest;
use function Facebook\FBExpect\expect;

class UpdateTest extends HackTest\HackTest {
  <<HackTest\DataProvider('updateProvider')>>
  public function testCreateUpdate(
    Container<string> $topics,
    string $data,
    Container<string> $targets = vec[],
    ?string $id = null,
    ?string $type = null,
    ?int $retry = null,
  ): void {
    $update = new Mercure\Update($topics, $data, $targets, $id, $type, $retry);
    expect($topics)->toBeSame($update->getTopics());
    expect($data)->toBeSame($update->getData());
    expect($targets)->toBeSame($update->getTargets());
    expect($id)->toBeSame($update->getId());
    expect($type)->toBeSame($update->getType());
    expect($retry)->toBeSame($update->getRetry());
  }

  public function updateProvider(
  ): Container<
    (Container<string>, string, Container<string>, ?string, ?string, ?int),
  > {
    return vec[
      tuple(
        vec['http://example.com/foo'],
        'payload',
        vec['user-1', 'group-a'],
        'id',
        'type',
        1936,
      ),
      tuple(
        vec['https://mercure.rocks', 'https://github.com/dunglas/mercure'],
        'payload',
        vec[],
        null,
        null,
        null,
      ),
    ];
  }
}
