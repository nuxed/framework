namespace Nuxed\Log\Formatter;

use namespace HH\Lib\{C, Dict, Str};
use namespace Nuxed\{Log, Util};

class LineFormatter implements IFormatter {
  const string SIMPLE_DATE = "Y-m-d\TH:i:s.uP";
  const string SIMPLE_FORMAT =
    "[%time%][%level%]: %message% %context% %extra%\n";

  protected string $format;
  private string $dateFormat;
  protected bool $allowInlineLineBreaks;
  protected bool $ignoreEmptyContextAndExtra;

  /**
   * @param string|null $format                     The format of the message
   * @param string|null $dateFormat                 The format of the timestamp: one supported by DateTime::format
   * @param bool        $allowInlineLineBreaks      Whether to allow inline line breaks in log entries
   * @param bool        $ignoreEmptyContextAndExtra
   */
  <<__Override>>
  public function __construct(
    ?string $format = null,
    ?string $dateFormat = null,
    bool $allowInlineLineBreaks = false,
    bool $ignoreEmptyContextAndExtra = true,
  ) {
    $this->dateFormat = $dateFormat ?? static::SIMPLE_DATE;
    $this->format = $format === null ? static::SIMPLE_FORMAT : $format;
    $this->ignoreEmptyContextAndExtra = $ignoreEmptyContextAndExtra;
    $this->allowInlineLineBreaks = $allowInlineLineBreaks;
  }

  public function ignoreEmptyContextAndExtra(bool $ignore = true): void {
    $this->ignoreEmptyContextAndExtra = $ignore;
  }

  public function allowInlineLineBreaks(bool $allow = true): void {
    $this->allowInlineLineBreaks = $allow;
  }

  public function format(Log\LogRecord $record): Log\LogRecord {
    $output = $this->format;

    foreach ($record['extra'] as $var => $val) {
      if (null !== Str\search($output, '%extra.'.$var.'%')) {
        $output = \strtr($output, '%extra.'.$var.'%', $this->stringify($val));
        unset($record['extra'][$var]);
      }
    }

    foreach ($record['context'] as $var => $val) {
      if (null !== Str\search($output, '%context.'.$var.'%')) {
        $output = \strtr($output, '%context.'.$var.'%', $this->stringify($val));
        unset($record['context'][$var]);
      }
    }

    if ($this->ignoreEmptyContextAndExtra) {
      if (0 === C\count($record['context'])) {
        $output = Str\replace($output, '%context%', '');
      }

      if (0 === C\count($record['extra'])) {
        $output = Str\replace($output, '%extra%', '');
      }
    }

    $replaces = dict[
      '%message%' => $record['message'],
      '%time%' => $record['time']->format($this->dateFormat),
      '%context%' => Util\stringify($record['context']),
      '%level%' => Str\uppercase((string)$record['level']),
      '%extra%' => Util\stringify($record['extra']),
    ];

    $output = \strtr($output, $replaces);

    // remove leftover %context.xxx% if any
    if (null !== Str\search($output, '%')) {
      $output = \preg_replace('/%(?:extra|context)\..+?%/', '', $output);
    }

    $record['formatted'] = $output;

    return $record;
  }

  public function stringify(mixed $value): string {
    return $this->replaceNewlines(Util\stringify($value));
  }

  protected function replaceNewlines(string $str): string {
    if ($this->allowInlineLineBreaks) {
      if (0 === Str\search($str, '{')) {
        return \strtr($str, Dict\associate(vec['\r', '\n'], vec["\r", "\n"]));
      }

      return $str;
    }

    return \strtr(
      $str,
      Dict\associate(vec["\r\n", "\r", "\n"], vec[' ', ' ', ' ']),
    );
  }

}
