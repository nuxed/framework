namespace Nuxed\Contract\Event;

type EventListener<TEvent as EventInterface> =
  (function(TEvent): Awaitable<void>);
