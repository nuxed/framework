<?hh // strict

namespace Nuxed\Markdown;

use namespace Facebook\Markdown;
use type Facebook\Markdown\Renderer;
use type Facebook\Markdown\RenderFilter;
use type Facebook\Markdown\HTMLRenderer;
use type Facebook\Markdown\ParserContext;
use type Facebook\Markdown\RenderContext;
use type Facebook\Markdown\UnparsedBlocks\Context as BlockContext;
use type Facebook\Markdown\Inlines\Context as InlineContext;
use type Facebook\Markdown\ASTNode;

<<__ConsistentConstruct>>
class Environment<T> {
  public function __construct(
    private ParserContext $parser,
    private RenderContext $context,
    private Renderer<T> $renderer,
  ) {}

  public static function html(): Environment<string> {
    $parser = new ParserContext();
    $context = new RenderContext();
    $renderer = new HTMLRenderer($context);
    return new self($parser, $context, $renderer);
  }

  public function setParser(ParserContext $parser): void {
    $this->parser = $parser;
  }

  public function getParser(): ParserContext {
    return $this->parser;
  }

  public function setContext(RenderContext $context): void {
    $this->context = $context;
  }

  public function getContext(): RenderContext {
    return $this->context;
  }

  public function setRenderer(Renderer<T> $renderer): void {
    $this->renderer = $renderer;
  }

  public function getRenderer(): Renderer<T> {
    return $this->renderer;
  }

  public function setInlineContext(InlineContext $context): void {
    $this->parser->setInlineContext($context);
  }

  public function getInlineContext(): InlineContext {
    return $this->parser->getInlineContext();
  }

  public function setBlockContext(BlockContext $context): void {
    $this->parser->setBlockContext($context);
  }

  public function getBlockContext(): BlockContext {
    return $this->parser->getBlockContext();
  }

  public function getFilters(): Container<RenderFilter> {
    return $this->context->getFilters();
  }

  public function addFilters(RenderFilter ...$filters): void {
    $this->context->appendFilters(...$filters);
  }

  public function use(Extension\ExtensionInterface $extension): void {
    $this->getBlockContext()
      ->prependBlockTypes(...$extension->getBlockProducers());
    $this->getInlineContext()
      ->prependInlineTypes(...$extension->getInlineTypes());
    $this->addFilters(...$extension->getRenderFilters());
  }

  public function parse(string $markdown): ASTNode {
    return Markdown\parse($this->parser, $markdown);
  }

  public function render(ASTNode $markdown): T {
    return $this->renderer->render($markdown);
  }

  public function convert(string $markdown): T {
    return $this->render($this->parse($markdown));
  }

  public function xhp(string $markdown): XHPElement where T as string {
    // UNSAFE
    return new XHPElement($markdown, $this);
  }
}
