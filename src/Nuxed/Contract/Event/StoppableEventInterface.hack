namespace Nuxed\Contract\Event;

interface StoppableEventInterface extends EventInterface {
  /**
   * Is propagation stopped?
   *
   * This will typically only be used by the Dispatcher to determine if the
   * previous listener halted propagation.
   *
   * @return bool
   *   True if the Event is handled and no further listeners should be called.
   *   False to continue calling listeners.
   */
  public function isPropagationStopped(): bool;
}
