namespace Nuxed\Test\EventDispatcher;

use namespace HH\Lib\C;
use namespace Facebook\HackTest;
use namespace Nuxed\EventDispatcher;
use namespace Nuxed\Test\EventDispatcher\Fixture;
use function Facebook\FBExpect\expect;

class EventDispatcherTest extends HackTest\HackTest {
  public async function testStoppableEvent(): Awaitable<void> {
    $provider = new EventDispatcher\ListenerProvider\ReifiedListenerProvider();
    $provider->listen<Fixture\OrderCanceledEvent>(
      new Fixture\OrderCanceledEventListener('foo'),
    );
    $provider->listen<Fixture\OrderCanceledEvent>(
      new Fixture\OrderCanceledEventListener('bar', true),
    );
    $provider->listen<Fixture\OrderCanceledEvent>(
      new Fixture\OrderCanceledEventListener('baz'),
    );
    $provider->listen<Fixture\OrderCanceledEvent>(
      new Fixture\OrderCanceledEventListener('qux'),
    );
    $provider->listen<Fixture\OrderCreatedEvent>(
      new Fixture\OrderCreatedEventListener(),
    );
    $dispatcher = new EventDispatcher\EventDispatcher($provider);

    $event = new Fixture\OrderCanceledEvent('foo');
    await $dispatcher->dispatch<Fixture\OrderCanceledEvent>($event);
    expect($event->orderId)->toBeSame('foofoobar');
  }

  public async function testDispatch(): Awaitable<void> {
    $provider = new EventDispatcher\ListenerProvider\ReifiedListenerProvider();
    $provider->listen<Fixture\OrderCanceledEvent>(
      new Fixture\OrderCanceledEventListener('foo'),
    );
    $provider->listen<Fixture\OrderCanceledEvent>(
      new Fixture\OrderCanceledEventListener('bar'),
    );
    $provider->listen<Fixture\OrderCanceledEvent>(
      new Fixture\OrderCanceledEventListener('baz'),
    );
    $provider->listen<Fixture\OrderCanceledEvent>(
      new Fixture\OrderCanceledEventListener('qux'),
    );
    $dispatcher = new EventDispatcher\EventDispatcher($provider);
    $event = new Fixture\OrderCanceledEvent('foo');
    await $dispatcher->dispatch<Fixture\OrderCanceledEvent>($event);
    expect($event->orderId)->toBeSame('foofoobarbazqux');
  }

  public async function testErroredEvent(): Awaitable<void> {
    $provider = new EventDispatcher\ListenerProvider\ReifiedListenerProvider();
    $provider->listen<Fixture\OrderCreatedEvent>(
      new Fixture\OrderCreatedEventListener(),
    );
    $provider->listen<EventDispatcher\ErrorEvent<Fixture\OrderCreatedEvent>>(
      EventDispatcher\f(async ($event) ==> {
        $event->getEvent()->orderId = 'caught';
      }),
    );
    $dispatcher = new EventDispatcher\EventDispatcher($provider);
    $event = new Fixture\OrderCreatedEvent('hello');
    expect(() ==> $dispatcher->dispatch<Fixture\OrderCreatedEvent>($event))
      ->toThrow(\Exception::class);
    expect($event->orderId)->toBeSame('caught');
  }
}
