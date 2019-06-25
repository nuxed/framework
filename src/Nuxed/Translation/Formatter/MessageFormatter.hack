namespace Nuxed\Translation\Formatter;

use namespace HH\Lib\{C, Str};
use namespace Nuxed\Translation\Exception;

final class MessageFormatter implements IMessageFormatter {


  private dict<string, dict<string, \MessageFormatter>> $cache = dict[];

  /**
   * {@inheritdoc}
   */
  public function format(
    string $message,
    string $locale,
    KeyedContainer<string, mixed> $parameters = dict[],
  ): string {
    $formatter = $this->cache[$locale][$message] ?? null;
    if ($formatter is null) {
      try {
        $formatter = new \MessageFormatter($locale, $message);
        if (!C\contains_key($this->cache, $locale)) {
          $this->cache[$locale] = dict[];
        }
        $this->cache[$locale][$message] = $formatter;
      } catch (\Throwable $e) {
        throw new Exception\InvalidArgumentException(Str\format(
          'Invalid message format (error #%d): %s.',
          \intl_get_error_code(),
          \intl_get_error_message(),
        ));
      }
    }

    $params = [];
    foreach ($parameters as $key => $value) {
      if (C\contains(['%', '{'], $key[0])) {
        $params[Str\trim($key, '%{ }')] = $value;
      } else {
        $params[$key] = $value;
      }
    }

    $message = $formatter->format($params);
    if (!$message is string) {
      throw new Exception\InvalidArgumentException(Str\format(
        'Unable to format message (error #%s): %s.',
        $formatter->getErrorCode(),
        $formatter->getErrorMessage(),
      ));
    }

    return $message;
  }
}
