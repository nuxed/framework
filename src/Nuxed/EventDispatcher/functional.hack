namespace Nuxed\EventDispatcher;

use namespace His\Container;

/**
 * Helper function to create an event listener,
 * from a callable.
 */
function f<T as IEvent>(
  (function(T): Awaitable<void>) $listener,
): IEventListener<T> {
  return new CallableEventListener($listener);
}

/**
 * Helper function to create a lazy loaded event listener.
 */
function lazy<T as IEvent>(
  Container\ContainerInterface $container,
  classname<IEventListener<T>> $service,
): IEventListener<T> {
  return f(($event) ==> {
    return $container->get($service)->process($event);
  });
}
