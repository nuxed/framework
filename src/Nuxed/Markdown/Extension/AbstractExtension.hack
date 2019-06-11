namespace Nuxed\Markdown\Extension;

use namespace Facebook\Markdown;
use namespace Facebook\Markdown\Inlines;
use namespace Facebook\Markdown\UnparsedBlocks;

class AbstractExtension implements IExtension {
  /**
   * @see Facebook\Markdown\RenderContext::appendFilters()
   */
  public function getRenderFilters(): Container<Markdown\RenderFilter> {
    return vec[];
  }

  /**
   * @see Facebook\Markdown\Inlines\Context::prependInlineTypes()
   */
  public function getInlineTypes(): Container<classname<Inlines\Inline>> {
    return vec[];
  }

  /**
   * @see Facebook\Markdown\UnparsedBlocks\Context::prependBlockTypes()
   */
  public function getBlockProducers(
  ): Container<classname<UnparsedBlocks\BlockProducer>> {
    return vec[];
  }
}
