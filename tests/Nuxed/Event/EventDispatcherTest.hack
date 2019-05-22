namespace Nuxed\Test\Event;

use namespace HH\Asio;
use namespace Nuxed\EventDispatcher;
use type Facebook\HackTest\HackTest;
use type Facebook\HackTest\DataProvider;
use function Facebook\FBExpect\expect;

class EventDispatcherTest extends HackTest {
  public async function testDispatch(): Awaitable<void> {
    $events = new EventDispatcher\EventDispatcher();
    $events->on(SillyEvent::class, async ($event) ==> {
      $event->value .= 'a';
    });
    $events->on(SillyEvent::class, async ($event) ==> {
      $event->value .= 'b';
    });
    $event = await $events->dispatch(new SillyEvent());
    expect($event->value)->toBeSame('ab');
  }

  public async function testEventsPriorities(): Awaitable<void> {
    $events = new EventDispatcher\EventDispatcher();
    $events->on(
      SillyEvent::class,
      async ($event) ==> {
        $event->value .= 'a';
      },
      1,
    );
    $events->on(
      SillyEvent::class,
      async ($event) ==> {
        $event->value .= 'b';
      },
      2,
    );
    $event = await $events->dispatch(new SillyEvent());
    expect($event->value)->toBeSame('ba');
  }

  public async function testDispatcherOrder(): Awaitable<void> {
    $events = new EventDispatcher\EventDispatcher();
    $events->on(
      SillyEvent::class,
      async ($event) ==> {
        $event->value .= 'a';
      },
      1,
    );
    $events->on(
      SillyEvent::class,
      async ($event) ==> {
        await Asio\usleep(100);
        $event->value .= 'b';
      },
      2,
    );
    $events->on(
      SillyEvent::class,
      async ($event) ==> {
        $event->value .= 'c';
      },
      2,
    );
    $event = await $events->dispatch(new SillyEvent());
    expect($event->value)->toBeSame('bca');
  }

  public async function testForget(): Awaitable<void> {
    $events = new EventDispatcher\EventDispatcher();
    $events->on(SillyEvent::class, async ($event) ==> {
      $event->value = 'called';
    });
    $events->forget(SillyEvent::class);
    $event = await $events->dispatch(new SillyEvent());
    expect($event->value)->toBeSame('');
  }

  public async function testStoppableEvent(): Awaitable<void> {
    $events = new EventDispatcher\EventDispatcher();
    $events->on(StoppableSillyEvent::class, async ($event) ==> {
      $event->stopped = true;
    });
    $events->on(StoppableSillyEvent::class, async ($event) ==> {
      $event->value = 'called';
    });
    $event = await $events->dispatch(new StoppableSillyEvent());
    expect($event->value)->toBeSame('');
  }

  public async function testStoppableEventSleeps(): Awaitable<void> {
    $events = new EventDispatcher\EventDispatcher();
    $events->on(StoppableSillyEvent::class, async ($event) ==> {
      await Asio\usleep(100);
      $event->stopped = true;
    });
    $events->on(StoppableSillyEvent::class, async ($event) ==> {
      $event->value = 'called';
    });
    $event = await $events->dispatch(new StoppableSillyEvent());
    expect($event->value)->toBeSame('');
  }

  public async function testListenersAreNotCalledIfEventIsAlreadyStopped(
  ): Awaitable<void> {
    $events = new EventDispatcher\EventDispatcher();
    $events->on(StoppableSillyEvent::class, async ($event) ==> {
      $event->value = 'called';
    });
    $event = await $events->dispatch(new StoppableSillyEvent(true));
    expect($event->value)->toBeSame('');
  }
}

<<__Sealed(StoppableSillyEvent::class)>>
class SillyEvent implements EventDispatcher\IEvent {
  public string $value = '';
}

final class StoppableSillyEvent
  extends SillyEvent
  implements EventDispatcher\IStoppableEvent {
  public function __construct(public bool $stopped = false) {}

  public function isPropagationStopped(): bool {
    return $this->stopped;
  }
}
