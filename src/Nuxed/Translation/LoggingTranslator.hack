namespace Nuxed\Translation;

use namespace Nuxed\Log;
use namespace HH\Lib\Str;

class LoggingTranslator implements ITranslator, ITranslatorBag, ILocaleAware {
  public function __construct(
    private ITranslator $translator,
    private Log\ILogger $logger,
  ) {
    if (!$translator is ILocaleAware || !$translator is ITranslatorBag) {
      throw new Exception\InvalidArgumentException(Str\format(
        'The Translator "%s" must implement ITranslator, ITranslatorBag, and ILocaleAware.',
        \get_class($translator),
      ));
    }
  }

  /**
   * {@inheritdoc}
   */
  public function trans(
    string $id,
    KeyedContainer<string, mixed> $parameters = dict[],
    ?string $domain = null,
    ?string $locale = null,
  ): string {
    $trans = $this->translator->trans($id, $parameters, $domain, $locale);
    $this->log($id, $domain, $locale);
    return $trans;
  }

  /**
   * {@inheritdoc}
   */
  public function setLocale(string $locale): void {
    $prev = $this->translator as ILocaleAware->getLocale();
    $this->translator as ILocaleAware->setLocale($locale);
    $this->logger->debug(Str\format(
      'The locale of the translator has changed from "%s" to "%s".',
      $prev,
      $locale,
    ));
  }

  /**
   * {@inheritdoc}
   */
  public function getLocale(): string {
    return $this->translator as ILocaleAware->getLocale();
  }

  /**
   * {@inheritdoc}
   */
  public function getCatalogue(?string $locale = null): MessageCatalogue {
    return $this->translator as ITranslatorBag->getCatalogue($locale);
  }

  /**
   * Logs for missing translations.
   */
  private function log(string $id, ?string $domain, ?string $locale): void {
    if (null === $domain) {
      $domain = 'messages';
    }
    $id = $id;
    $catalogue = $this->getCatalogue($locale);
    if ($catalogue->defines($id, $domain)) {
      return;
    }
    if ($catalogue->has($id, $domain)) {
      $this->logger->debug(
        'Translation use fallback catalogue.',
        dict[
          'id' => $id,
          'domain' => $domain,
          'locale' => $catalogue->getLocale(),
        ],
      );
    } else {
      $this->logger->warning(
        'Translation not found.',
        dict[
          'id' => $id,
          'domain' => $domain,
          'locale' => $catalogue->getLocale(),
        ],
      );
    }
  }
}
