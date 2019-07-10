namespace Nuxed\Test\EventDispatcher\ListenerProvider;

use namespace HH\Lib\C;
use namespace Facebook\HackTest;
use namespace Nuxed\Test\EventDispatcher\Fixture;
use namespace Nuxed\EventDispatcher\ListenerProvider;
use function Facebook\FBExpect\expect;

class AttachableListenerProviderTest extends HackTest\HackTest {
  public async function testListenAndGetListeners(): Awaitable<void> {
    $listenerProvider = new ListenerProvider\AttachableListenerProvider();
    $listeners = vec[
      new Fixture\OrderCanceledEventListener('foo'),
      new Fixture\OrderCanceledEventListener('baz'),
      new Fixture\OrderCanceledEventListener('qux'),
    ];
    foreach ($listeners as $listener) {
      $listenerProvider->listen(Fixture\OrderCanceledEvent::class, $listener);
    }
    $listenerProvider->listen(
      Fixture\OrderCreatedEvent::class,
      new Fixture\OrderCreatedEventListener(),
    );

    $event = new Fixture\OrderCanceledEvent('bar');
    $i = 0;
    foreach (
      $listenerProvider->getListeners<Fixture\OrderCanceledEvent>(
        $event,
      ) await as $listener
    ) {
      expect($listeners[$i])->toBeSame($listener);
      $i++;
    }

    expect($i)->toBeSame(3);
  }

  public async function testDuplicateListeners(): Awaitable<void> {
    $listenerProvider = new ListenerProvider\AttachableListenerProvider();
    $listener = new Fixture\OrderCanceledEventListener('foo');
    $listenerProvider->listen(Fixture\OrderCanceledEvent::class, $listener);
    $listenerProvider->listen(Fixture\OrderCanceledEvent::class, $listener);
    $listenerProvider->listen(Fixture\OrderCanceledEvent::class, $listener);
    $listenerProvider->listen(
      Fixture\OrderCreatedEvent::class,
      new Fixture\OrderCreatedEventListener(),
    );

    $event = new Fixture\OrderCanceledEvent('bar');
    $i = 0;
    foreach (
      $listenerProvider->getListeners<Fixture\OrderCanceledEvent>(
        $event,
      ) await as $eventListener
    ) {
      expect($listener)->toBeSame($eventListener);
      $i++;
    }

    expect($i)->toBeSame(1);
  }
}
