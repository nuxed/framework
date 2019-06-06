namespace Nuxed\Translation;

use namespace HH\Lib\C;
use namespace HH\Lib\Str;
use namespace HH\Lib\Vec;
use namespace HH\Lib\Regex;

class Translator implements ITranslator, ILocaleAware, ITranslatorBag {
  protected dict<string, MessageCatalogue> $catalogues = dict[];

  private ?string $locale;

  private vec<string> $fallbackLocales = vec[];

  private _Private\LoaderContainer $loaders;

  private ?vec<string> $parentLocales;

  private dict<string, vec<(string, mixed, string)>> $resources = dict[];

  /**
   * @throws Exception\InvalidArgumentException If a locale contains invalid characters
   */
  public function __construct(
    string $locale = \Locale::getDefault(),
    private Formatter\IMessageFormatter $formatter =
      new Formatter\MessageFormatter(),
  ) {
    $this->loaders = new _Private\LoaderContainer();
    $this->setLocale($locale);
  }

  /**
   * Adds a Loader.
   */
  public function addLoader<T>(
    classname<Loader\ILoader<T>> $format,
    Loader\ILoader<T> $loader,
  ): void {
    $this->loaders->addLoader($format, $loader);
  }

  /**
   * Adds a Resource.
   *
   * @template T
   *
   * @param classname<Loader\ILoader<T>>  $format   The classname of the loader (@see addLoader())
   *
   * @throws InvalidArgumentException If the locale contains invalid characters
   */
  public function addResource<T>(
    classname<Loader\ILoader<T>> $format,
    T $resource,
    string $locale,
    ?string $domain = null,
  ): void {
    if (null === $domain) {
      $domain = 'messages';
    }

    $this->assertValidLocale($locale);
    if (!C\contains_key($this->resources, $locale)) {
      $this->resources[$locale] = vec[];
    }

    $this->resources[$locale][] = tuple($format, $resource, $domain);
    if (C\contains($this->fallbackLocales, $locale)) {
      $this->catalogues = dict[];
    } else {
      unset($this->catalogues[$locale]);
    }
  }

  /**
   * {@inheritdoc}
   */
  public function setLocale(string $locale): void {
    $this->assertValidLocale($locale);
    $this->locale = $locale;
  }

  /**
   * {@inheritdoc}
   */
  public function getLocale(): string {
    return $this->locale ?? \Locale::getDefault();
  }

  /**
   * Sets the fallback locales.
   *
   * @throws Exception\InvalidArgumentException If a locale contains invalid characters
   */
  public function setFallbackLocales(Container<string> $locales): void {
    // needed as the fallback locales are linked to the already loaded catalogues
    $this->catalogues = dict[];
    foreach ($locales as $locale) {
      $this->assertValidLocale($locale);
    }
    $this->fallbackLocales = vec($locales);
  }

  /**
   * {@inheritdoc}
   */
  public function trans(
    string $id,
    KeyedContainer<string, mixed> $parameters = dict[],
    ?string $locale = null,
    ?string $domain = null,
  ): string {
    if (null === $domain) {
      $domain = 'messages';
    }
    $id = (string)$id;
    $catalogue = $this->getCatalogue($locale);
    $locale = $catalogue->getLocale();
    while (!$catalogue->defines($id, $domain)) {
      $cat = $catalogue->getFallbackCatalogue();
      if ($cat is nonnull) {
        $catalogue = $cat;
        $locale = $catalogue->getLocale();
      } else {
        break;
      }
    }

    return $this->formatter
      ->format($catalogue->get($id, $domain), $locale, $parameters);
  }

  /**
   * {@inheritdoc}
   */
  public function getCatalogue(?string $locale = null): MessageCatalogue {
    if (null === $locale) {
      $locale = $this->getLocale();
    } else {
      $this->assertValidLocale($locale);
    }

    if (!C\contains_key($this->catalogues, $locale)) {
      $this->loadCatalogue($locale);
    }

    return $this->catalogues[$locale];
  }

  /**
   * Gets the loaders.
   */
  protected function getLoader<T>(
    classname<Loader\ILoader<T>> $format,
  ): Loader\ILoader<T> {
    return $this->loaders->getLoader($format);
  }

  protected function loadCatalogue(string $locale): void {
    $this->assertValidLocale($locale);
    try {
      $this->doLoadCatalogue($locale);
    } catch (Exception\NotFoundResourceException $e) {
      if (0 === C\count($this->computeFallbackLocales($locale))) {
        throw $e;
      }
    }
    $this->loadFallbackCatalogues($locale);
  }

  /**
   * @internal
   */
  protected function doLoadCatalogue(string $locale): void {
    $this->catalogues[$locale] = new MessageCatalogue($locale);
    if (C\contains_key($this->resources, $locale)) {
      foreach ($this->resources[$locale] as $resource) {
        $this->catalogues[$locale]->addCatalogue(
          /* HH_IGNORE_ERROR[4110]*/
          $this->getLoader($resource[0])
            ->load($resource[1], $locale, $resource[2]),
        );
      }
    }
  }

  private function loadFallbackCatalogues(string $locale): void {
    $current = $this->catalogues[$locale];
    foreach ($this->computeFallbackLocales($locale) as $fallback) {
      if (!C\contains_key($this->catalogues, $fallback)) {
        $this->loadCatalogue($fallback);
      }
      $fallbackCatalogue = new MessageCatalogue(
        $fallback,
        $this->getAllMessages($this->catalogues[$fallback]),
      );
      $current->addFallbackCatalogue($fallbackCatalogue);
      $current = $fallbackCatalogue;
    }
  }

  protected function computeFallbackLocales(string $locale): Container<string> {
    $locales = vec[];
    foreach ($this->fallbackLocales as $fallback) {
      if ($fallback === $locale) {
        continue;
      }
      $locales[] = $fallback;
    }

    while ($locale is nonnull) {
      $parent = _Private\Parents[$locale] ?? null;
      if ($parent is null && Str\contains($locale, '_')) {
        $locale = Str\slice($locale, 0, Str\search_last($locale, '_'));
      } else if ('root' !== $parent) {
        $locale = $parent;
      } else {
        $locale = null;
      }

      if ($locale is nonnull) {
        $locales = Vec\concat(vec[$locale], $locales);
      }
    }

    return Vec\unique($locales);
  }
  /**
   * Asserts that the locale is valid, throws an Exception if not.
   *
   * @param string $locale Locale to tests
   *
   * @throws InvalidArgumentException If the locale contains invalid characters
   */
  protected function assertValidLocale(string $locale): void {
    if (!Regex\matches($locale, re"/^[a-z0-9@_\\.\\-]*$/i")) {
      throw new Exception\InvalidArgumentException(
        Str\format('Invalid "%s" locale.', $locale),
      );
    }
  }

  private function getAllMessages(
    MessageCatalogue $catalogue,
  ): KeyedContainer<string, KeyedContainer<string, string>> {
    $allMessages = dict[];
    foreach ($catalogue->all() as $domain => $messages) {
      if (0 !== C\count($messages)) {
        $allMessages[$domain] = $messages;
      }
    }
    return $allMessages;
  }
}
