namespace Nuxed\Test\EventDispatcher\ListenerProvider;

use namespace HH\Lib\C;
use namespace Facebook\HackTest;
use namespace Nuxed\Test\EventDispatcher\Fixture;
use namespace Nuxed\EventDispatcher\ListenerProvider;
use function Facebook\FBExpect\expect;

class ListenerProviderAggregateTest extends HackTest\HackTest {
  public async function testAttachAndGetListeners(): Awaitable<void> {
    $aggregate = new ListenerProvider\ListenerProviderAggregate();
    $attachableProvider = new ListenerProvider\AttachableListenerProvider();
    $reifiedProvider = new ListenerProvider\ReifiedListenerProvider();
    $aggregate->attach($attachableProvider);
    $aggregate->attach($reifiedProvider);

    $listeners = vec[
      new Fixture\OrderCanceledEventListener('foo'),
      new Fixture\OrderCanceledEventListener('baz'),
      new Fixture\OrderCanceledEventListener('qux'),
    ];
    foreach ($listeners as $listener) {
      $attachableProvider->listen(Fixture\OrderCanceledEvent::class, $listener);
      $reifiedProvider->listen<Fixture\OrderCanceledEvent>($listener);
    }
    $attachableProvider->listen(
      Fixture\OrderCreatedEvent::class,
      new Fixture\OrderCreatedEventListener(),
    );

    $event = new Fixture\OrderCanceledEvent('bar');
    $i = 0;
    foreach (
      $aggregate->getListeners<Fixture\OrderCanceledEvent>($event) await as
        $listener
    ) {
      expect($listeners)->toContain($listener);
      $i++;
    }

    expect($i)->toBeSame(6);
  }
}
