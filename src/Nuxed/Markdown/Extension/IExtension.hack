namespace Nuxed\Markdown\Extension;

use namespace Facebook\Markdown;
use namespace Facebook\Markdown\{Inlines, UnparsedBlocks};

interface IExtension {
  /**
   * @see Facebook\Markdown\RenderContext::appendFilters()
   */
  public function getRenderFilters(): Container<Markdown\RenderFilter>;

  /**
   * @see Facebook\Markdown\Inlines\Context::prependInlineTypes()
   */
  public function getInlineTypes(): Container<classname<Inlines\Inline>>;

  /**
   * @see Facebook\Markdown\UnparsedBlocks\Context::prependBlockTypes()
   */
  public function getBlockProducers(
  ): Container<classname<UnparsedBlocks\BlockProducer>>;
}
