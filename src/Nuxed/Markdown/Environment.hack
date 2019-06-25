namespace Nuxed\Markdown;

use namespace Facebook\Markdown;
use namespace Facebook\Markdown\{Inlines, UnparsedBlocks};

final class Environment<T> {
  public function __construct(
    private Markdown\ParserContext $parser,
    private Markdown\RenderContext $context,
    private Markdown\Renderer<T> $renderer,
  ) {}

  public static function html(): Environment<string> {
    $parser = new Markdown\ParserContext();
    $context = new Markdown\RenderContext();
    $renderer = new Markdown\HTMLRenderer($context);
    return new self($parser, $context, $renderer);
  }

  public function setParser(Markdown\ParserContext $parser): void {
    $this->parser = $parser;
  }

  public function getParser(): Markdown\ParserContext {
    return $this->parser;
  }

  public function setContext(Markdown\RenderContext $context): void {
    $this->context = $context;
  }

  public function getContext(): Markdown\RenderContext {
    return $this->context;
  }

  public function setRenderer(Markdown\Renderer<T> $renderer): void {
    $this->renderer = $renderer;
  }

  public function getRenderer(): Markdown\Renderer<T> {
    return $this->renderer;
  }

  public function setInlineContext(Inlines\Context $context): void {
    $this->parser->setInlineContext($context);
  }

  public function getInlineContext(): Inlines\Context {
    return $this->parser->getInlineContext();
  }

  public function setBlockContext(UnparsedBlocks\Context $context): void {
    $this->parser->setBlockContext($context);
  }

  public function getBlockContext(): UnparsedBlocks\Context {
    return $this->parser->getBlockContext();
  }

  public function getFilters(): Container<Markdown\RenderFilter> {
    return $this->context->getFilters();
  }

  public function addFilters(Markdown\RenderFilter ...$filters): void {
    $this->context->appendFilters(...$filters);
  }

  public function use(Extension\IExtension $extension): void {
    $this->getBlockContext()
      ->prependBlockTypes(...$extension->getBlockProducers());
    $this->getInlineContext()
      ->prependInlineTypes(...$extension->getInlineTypes());
    $this->addFilters(...$extension->getRenderFilters());
  }

  public function parse(string $markdown): Markdown\ASTNode {
    return Markdown\parse($this->parser, $markdown);
  }

  public function render(Markdown\ASTNode $markdown): T {
    return $this->renderer->render($markdown);
  }

  public function convert(string $markdown): T {
    return $this->render($this->parse($markdown));
  }

  public function xhp(string $markdown): XHPElement where T as string {
    /* HH_FIXME[4110] */
    return new XHPElement($markdown, $this);
  }
}
