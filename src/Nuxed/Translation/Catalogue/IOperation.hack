namespace Nuxed\Translation\Catalogue;

use namespace Nuxed\Translation;

/**
 * Represents an operation on catalogue(s).
 *
 * An instance of this interface performs an operation on one or more catalogues and
 * stores intermediate and final results of the operation.
 *
 * The first catalogue in its argument(s) is called the 'source catalogue' or 'source' and
 * the following results are stored:
 *
 * Messages: also called 'all', are valid messages for the given domain after the operation is performed.
 *
 * New Messages: also called 'new' (new = all ∖ source = {x: x ∈ all ∧ x ∉ source}).
 *
 * Obsolete Messages: also called 'obsolete' (obsolete = source ∖ all = {x: x ∈ source ∧ x ∉ all}).
 *
 * Result: also called 'result', is the resulting catalogue for the given domain that holds the same messages as 'all'.
 */
interface IOperation {
  /**
   * Returns domains affected by operation.
   */
  public function getDomains(): Container<string>;

  /**
   * Returns all valid messages ('all') after operation.
   */
  public function getMessages(string $domain): KeyedContainer<string, string>;

  /**
   * Returns new messages ('new') after operation.
   */
  public function getNewMessages(
    string $domain,
  ): KeyedContainer<string, string>;

  /**
   * Returns obsolete messages ('obsolete') after operation.
   */
  public function getObsoleteMessages(
    string $domain,
  ): KeyedContainer<string, string>;

  /**
   * Returns resulting catalogue ('result').
   */
  public function getResult(): Translation\MessageCatalogue;
}
