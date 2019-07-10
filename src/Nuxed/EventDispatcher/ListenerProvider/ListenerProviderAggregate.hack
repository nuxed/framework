namespace Nuxed\EventDispatcher\ListenerProvider;

use namespace Nuxed\EventDispatcher;

final class ListenerProviderAggregate implements IListenerProvider {
  private vec<IListenerProvider> $providers = vec[];

  public async function getListeners<reify T as EventDispatcher\IEvent>(
    T $event,
  ): AsyncIterator<EventDispatcher\IEventListener<T>> {
    foreach ($this->providers as $provider) {
      foreach ($provider->getListeners<T>($event) await as $listener) {
        yield $listener;
      }
    }
  }

  public function attach(IListenerProvider $provider): void {
    $this->providers[] = $provider;
  }
}
