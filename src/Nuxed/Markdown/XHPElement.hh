<?hh // strict

namespace Nuxed\Markdown;

use type Nuxed\Util\StringableTrait;
use type XHPUnsafeRenderable;

// Probably don't need XHPAlwaysValidChild - this is likely to be in a <div />
// or other similarly liberal container
final class XHPElement implements XHPUnsafeRenderable {
  use StringableTrait;

  public function __construct(
    private string $markdown,
    private Environment<string> $env,
  ) {
  }

  public function toHTMLString(): string {
    return $this->env->convert($this->markdown);
  }

  public function toString(): string {
    return $this->toHTMLString();
  }
}
