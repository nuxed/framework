<?hh // strict

namespace Nuxed\Contract\Service;

/**
 * Provides a way to reset an object to its initial state.
 *
 * When calling the "reset()" method on an object, it should be put back to its
 * initial state. This usually means clearing any internal buffers and forwarding
 * the call to internal dependencies. All properties of the object should be put
 * back to the same state it had when it was first ready to use.
 *
 * This method could be called, for example, to recycle objects that are used as
 * services, so that they can be used to handle several requests in the same
 * process loop (note that we advise making your services stateless instead of
 * implementing this interface when possible.)
 */
interface ResetInterface {
  public function reset(): void;
}
