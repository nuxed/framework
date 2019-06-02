namespace Nuxed\Translation\Formatter;

interface IMessageFormatter {
  /**
   * Formats a localized message pattern with given arguments.
   */
  public function format(
    string $message,
    string $locale,
    KeyedContainer<string, mixed> $parameters = dict[],
  ): string;
}
