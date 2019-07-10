namespace Nuxed\EventDispatcher;

/**
 * Marker interface indicating an event instance.
 *
 * Event instances may contain zero methods, or as many methods as they
 * want. The interface MUST be implemented, however, to provide type-safety
 * to both listeners as well as the dispatcher.
 */
interface IEvent {}
