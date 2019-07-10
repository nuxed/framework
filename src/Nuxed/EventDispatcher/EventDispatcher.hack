namespace Nuxed\EventDispatcher;

use namespace HH\Lib;

final class EventDispatcher implements IEventDispatcher {
  public function __construct(
    private ListenerProvider\IListenerProvider $listenerProvider,
  ) {}

  /**
   * Provide all relevant listeners with an event to process.
   *
   * If a Throwable is caught when executing the listener loop, it is cast
   * to an ErrorEvent, and then the method calls itself with that instance,
   * re-throwing the original Throwable on completion.
   *
   * In the case that a Throwable is caught for an ErrorEvent, we re-throw
   * to prevent recursion.
   *
   * @template T as IEvent
   *
   * @return T The Event that was passed, now modified by listeners.
   */
  public async function dispatch<reify T as IEvent>(T $event): Awaitable<T> {
    $in = $event;
    if ($event is IStoppableEvent && $event->isPropagationStopped()) {
      return $in;
    }

    $listeners = $this->listenerProvider->getListeners<T>($event);
    $stopped = new Lib\Ref(false);
    $lastOperation = async {};

    foreach ($listeners await as $listener) {
      if ($stopped->value) {
        break;
      }

      $lastOperation = async {
        await $lastOperation;
        if ($event is IStoppableEvent && $event->isPropagationStopped()) {
          $stopped->value = true;
          return;
        }

        try {
          await $listener->process($event);
        } catch (\Exception $e) {
          await $this->handleCaughtException<T>($e, $event, $listener);
        }
      };
    }

    await $lastOperation;
    return $in;
  }

  private async function handleCaughtException<reify T as IEvent>(
    \Exception $e,
    T $event,
    IEventListener<T> $listener,
  ): Awaitable<noreturn> {
    if ($event is ErrorEvent<IEvent>) {
      throw $event->getException();
    }

    await $this->dispatch<ErrorEvent<T>>(
      new ErrorEvent<T>($event, $listener, $e),
    );

    // Re-throw the original exception, per the spec.
    throw $e;
  }
}
