namespace Nuxed\Markdown\Extension;

use type Facebook\Markdown\RenderFilter;
use type Facebook\Markdown\Inlines\Inline;
use type Facebook\Markdown\UnparsedBlocks\BlockProducer;
use type Facebook\Markdown\UnparsedBlocks\LinkReferenceDefinition;

class AbstractExtension implements ExtensionInterface {
  /**
   * @see Facebook\Markdown\RenderContext::appendFilters()
   */
  public function getRenderFilters(): Container<RenderFilter> {
    return vec[];
  }

  /**
   * @see Facebook\Markdown\Inlines\Context::prependInlineTypes()
   */
  public function getInlineTypes(): Container<classname<Inline>> {
    return vec[];
  }

  /**
   * @see Facebook\Markdown\UnparsedBlocks\Context::addLinkReferenceDefinition()
   */
  public function getLinkReferenceDefinition(): ?LinkReferenceDefinition {
    return null;
  }

  /**
   * @see Facebook\Markdown\UnparsedBlocks\Context::prependBlockTypes()
   */
  public function getBlockProducers(): Container<classname<BlockProducer>> {
    return vec[];
  }
}
