namespace Nuxed\Crypto;

use namespace Nuxed\Util;

final class HiddenString implements Util\Stringable {
  public function __construct(
    private string $internalStringValue,
    private bool $disallowInline = false,
    private bool $disallowSerialization = false,
  ) {}

  public function equals(HiddenString $other): bool {
    return \hash_equals($this->toString(), $other->toString());
  }

  public function toString(): string {
    $string = $this->internalStringValue;
    return Str\copy($string);
  }

  public function __toString(): string {
    if ($this->disallowInline) {
      return '';
    }

    return $this->toString();
  }

  /**
   * Hide its internal state from var_dump()
   */
  public function __debugInfo(): KeyedContainer<string, string> {
    return dict[
      'internalStringValue' => '*',
      'attention' => 'If you need the value of a HiddenString, '.
        'invoke toString() instead of dumping it.',
    ];
  }

  public function __sleep(): Container<string> {
    if (!$this->disallowSerialization) {
      return vec[
        'internalStringValue',
        'disallowInline',
        'disallowSerialization',
      ];
    }

    return vec[];
  }
}
