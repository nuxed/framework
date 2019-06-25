namespace Nuxed\Translation\Catalogue;

use namespace HH\Lib\{C, Str, Vec};
use namespace Nuxed\Translation;
use namespace Nuxed\Translation\Exception;

/**
 * Base catalogues binary operation class.
 *
 * A catalogue binary operation performs operation on
 * source (the left argument) and target (the right argument) catalogues.
 */
abstract class AbstractOperation implements IOperation {
  protected Translation\MessageCatalogue $source;
  protected Translation\MessageCatalogue $target;
  protected Translation\MessageCatalogue $result;

  /**
   * @var ?vec<string> The domains affected by this operation
   */
  private ?vec<string> $domains;

  /**
   * This container stores 'all', 'new' and 'obsolete' messages for all valid domains.
   */
  protected dict<string, shape(
    'all' => dict<string, string>,
    'new' => dict<string, string>,
    'obsolete' => dict<string, string>,
  )> $messages = dict[];

  /**
   * @throws Exception\LogicException
   */
  public function __construct(
    Translation\MessageCatalogue $source,
    Translation\MessageCatalogue $target,
  ) {
    if ($source->getLocale() !== $target->getLocale()) {
      throw new Exception\LogicException(
        'Operated catalogues must belong to the same locale.',
      );
    }
    $this->source = $source;
    $this->target = $target;
    $this->result = new Translation\MessageCatalogue($source->getLocale());
  }

  /**
   * {@inheritdoc}
   */
  public function getDomains(): Container<string> {
    if ($this->domains is null) {
      $this->domains = Vec\unique(
        Vec\concat($this->source->getDomains(), $this->target->getDomains()),
      );
    }

    return $this->domains;
  }

  /**
   * {@inheritdoc}
   */
  public function getMessages(string $domain): KeyedContainer<string, string> {
    if (!C\contains($this->getDomains(), $domain)) {
      throw new Exception\InvalidArgumentException(
        Str\format('Invalid domain: %s.', $domain),
      );
    }

    if (!C\contains_key($this->messages, $domain)) {
      $this->processDomain($domain);
    }

    return $this->messages[$domain]['all'];
  }

  /**
   * {@inheritdoc}
   */
  public function getNewMessages(
    string $domain,
  ): KeyedContainer<string, string> {
    if (!C\contains($this->getDomains(), $domain)) {
      throw new Exception\InvalidArgumentException(
        Str\format('Invalid domain: %s.', $domain),
      );
    }

    if (!C\contains_key($this->messages, $domain)) {
      $this->processDomain($domain);
    }

    return $this->messages[$domain]['new'];
  }

  /**
   * {@inheritdoc}
   */
  public function getObsoleteMessages(
    string $domain,
  ): KeyedContainer<string, string> {
    if (!C\contains($this->getDomains(), $domain)) {
      throw new Exception\InvalidArgumentException(
        Str\format('Invalid domain: %s.', $domain),
      );
    }

    if (!C\contains_key($this->messages, $domain)) {
      $this->processDomain($domain);
    }

    return $this->messages[$domain]['obsolete'];
  }

  /**
   * {@inheritdoc}
   */
  public function getResult(): Translation\MessageCatalogue {
    foreach ($this->getDomains() as $domain) {
      if (!C\contains_key($this->messages, $domain)) {
        $this->processDomain($domain);
      }
    }

    return $this->result;
  }

  /**
   * Performs operation on source and target catalogues for the given domain and
   * stores the results.
   */
  abstract protected function processDomain(string $domain): void;
}
