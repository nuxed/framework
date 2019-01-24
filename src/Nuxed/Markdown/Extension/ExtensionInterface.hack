namespace Nuxed\Markdown\Extension;

use type Facebook\Markdown\RenderFilter;
use type Facebook\Markdown\Inlines\Inline;
use type Facebook\Markdown\UnparsedBlocks\BlockProducer;

interface ExtensionInterface {
  /**
   * @see Facebook\Markdown\RenderContext::appendFilters()
   */
  public function getRenderFilters(): Container<RenderFilter>;

  /**
   * @see Facebook\Markdown\Inlines\Context::prependInlineTypes()
   */
  public function getInlineTypes(): Container<classname<Inline>>;

  /**
   * @see Facebook\Markdown\UnparsedBlocks\Context::prependBlockTypes()
   */
  public function getBlockProducers(): Container<classname<BlockProducer>>;
}
