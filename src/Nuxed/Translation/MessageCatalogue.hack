namespace Nuxed\Translation;

use namespace HH\Lib\{C, Dict, Str};
use namespace Nuxed\Translation\Exception;

final class MessageCatalogue {
  private dict<string, dict<string, string>> $messages = dict[];
  private string $locale;
  private ?MessageCatalogue $fallbackCatalogue;
  private ?MessageCatalogue $parent;

  public function __construct(
    string $locale,
    KeyedContainer<string, KeyedContainer<string, string>> $messages = [],
  ) {
    $this->locale = $locale;
    $this->messages = Dict\map($messages, $m ==> dict($m));
  }

  /**
   * Gets the catalogue locale.
   */
  public function getLocale(): string {
    return $this->locale;
  }

  /**
   * Gets the domains.
   */
  public function getDomains(): Container<string> {
    $domains = vec[];
    foreach ($this->messages as $domain => $messages) {
      $domains[] = $domain;
    }
    return $domains;
  }

  public function all(
  ): KeyedContainer<string, KeyedContainer<string, string>> {
    $allMessages = dict[];
    foreach ($this->messages as $domain => $messages) {
      $allMessages[$domain] = Dict\merge(
        $messages,
        $allMessages[$domain] ?? dict[],
      );
    }
    return $allMessages;
  }

  /**
   * Gets the messages within a given domain.
   */
  public function domain(string $domain): KeyedContainer<string, string> {
    return $this->messages[$domain] ?? dict[];
  }

  /**
   * Sets a message translation.
   */
  public function set(
    string $id,
    string $translation,
    string $domain = 'messages',
  ): void {
    $this->add(dict[$id => $translation], $domain);
  }

  /**
   * Checks if a message has a translation.
   */
  public function has(string $id, string $domain = 'messages'): bool {
    if ($this->defines($id, $domain)) {
      return true;
    }

    if ($this->fallbackCatalogue is nonnull) {
      return $this->fallbackCatalogue->has($id, $domain);
    }

    return false;
  }

  /**
   * Checks if a message has a translation (it does not take into account the fallback mechanism).
   */
  public function defines(string $id, string $domain = 'messages'): bool {
    return C\contains_key($this->messages[$domain] ?? dict[], $id);
  }

  /**
   * Gets a message translation.
   */
  public function get(string $id, string $domain = 'messages'): string {
    if (C\contains_key($this->messages[$domain] ?? dict[], $id)) {
      return $this->messages[$domain][$id];
    }

    if ($this->fallbackCatalogue is nonnull) {
      return $this->fallbackCatalogue->get($id, $domain);
    }

    return $id;
  }

  /**
   * Sets translations for a given domain.
   */
  public function replace(
    KeyedContainer<string, string> $messages,
    string $domain = 'messages',
  ): void {
    unset($this->messages[$domain]);
    $this->add($messages, $domain);
  }

  /**
   * Sets translations for a given domain.
   */
  public function add(
    KeyedContainer<string, string> $messages,
    string $domain = 'messages',
  ): void {
    if (!C\contains_key($this->messages, $domain)) {
      $this->messages[$domain] = dict($messages);
    } else {
      $this->messages[$domain] = Dict\merge(
        $this->messages[$domain],
        $messages,
      );
    }
  }

  /**
   * Merges translations from the given Catalogue into the current one.
   *
   * The two catalogues must have the same locale.
   */
  public function addCatalogue(MessageCatalogue $catalogue): void {
    if ($catalogue->getLocale() !== $this->locale) {
      throw new Exception\LogicException(Str\format(
        'Cannot add a catalogue for locale "%s" as the current locale for this catalogue is "%s"',
        $catalogue->getLocale(),
        $this->locale,
      ));
    }

    foreach ($catalogue->all() as $domain => $messages) {
      $this->add($messages, $domain);
    }
  }

  /**
   * Merges translations from the given Catalogue into the current one
   * only when the translation does not exist.
   *
   * This is used to provide default translations when they do not exist for the current locale.
   */
  public function addFallbackCatalogue(MessageCatalogue $catalogue): void {
    // detect circular references
    $c = $catalogue;
    while ($c = $c->getFallbackCatalogue()) {
      if ($c->getLocale() === $this->getLocale()) {
        throw new Exception\LogicException(Str\format(
          'Circular reference detected when adding a fallback catalogue for locale "%s".',
          $catalogue->getLocale(),
        ));
      }
    }

    $c = $this;
    do {
      if ($c->getLocale() === $catalogue->getLocale()) {
        throw new Exception\LogicException(Str\format(
          'Circular reference detected when adding a fallback catalogue for locale "%s".',
          $catalogue->getLocale(),
        ));
      }
    } while ($c = $c->parent);

    $catalogue->parent = $this;
    $this->fallbackCatalogue = $catalogue;
  }

  /**
   * Gets the fallback catalogue.
   */
  public function getFallbackCatalogue(): ?MessageCatalogue {
    return $this->fallbackCatalogue;
  }
}
