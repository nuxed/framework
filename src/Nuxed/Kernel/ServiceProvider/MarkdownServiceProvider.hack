namespace Nuxed\Kernel\ServiceProvider;

use namespace Facebook;
use namespace Nuxed\Markdown;
use type Nuxed\Container\ServiceProvider\AbstractServiceProvider;

class MarkdownServiceProvider extends AbstractServiceProvider {
  protected vec<string> $provides = vec[
    Markdown\Environment::class,
    Facebook\Markdown\ParserContext::class,
    Facebook\Markdown\RenderContext::class,
    Facebook\Markdown\Renderer::class,
  ];

  <<__Override>>
  public function __construct(
    private shape(
      ?'parser' => classname<Facebook\Markdown\ParserContext>,
      ?'context' => classname<Facebook\Markdown\RenderContext>,
      ?'renderer' => classname<Facebook\Markdown\Renderer<string>>,
      ?'extensions' => Container<Markdown\Extension\ExtensionInterface>,
      ...
    ) $config = shape(),
  ) {
    parent::__construct();
  }

  <<__Override>>
  public function register(): void {
    $environment = $this->share(Markdown\Environment::class)
      ->addArguments(vec[
        Shapes::idx(
          $this->config,
          'parser',
          Facebook\Markdown\ParserContext::class,
        ),
        Shapes::idx(
          $this->config,
          'context',
          Facebook\Markdown\RenderContext::class,
        ),
        Shapes::idx(
          $this->config,
          'renderer',
          Facebook\Markdown\Renderer::class,
        ),
      ]);

    $this->share(Facebook\Markdown\ParserContext::class);
    $this->share(Facebook\Markdown\RenderContext::class);
    $this->share(
      Facebook\Markdown\Renderer::class,
      Facebook\Markdown\HTMLRenderer::class,
    )
      ->addArgument(Facebook\Markdown\RenderContext::class);

    $extensions = Shapes::idx($this->config, 'extensions', vec[]);

    foreach ($extensions as $extension) {
      $environment->addMethodCall('use', vec[$extension]);
    }
  }
}
