namespace Nuxed\Kernel\ServiceProvider;

use namespace Facebook;
use namespace Nuxed\Markdown;

class MarkdownServiceProvider extends AbstractServiceProvider {
  protected vec<string> $provides = vec[
    Markdown\Environment::class,
    Facebook\Markdown\ParserContext::class,
    Facebook\Markdown\RenderContext::class,
    Facebook\Markdown\Renderer::class,
  ];

  <<__Override>>
  public function register(): void {
    $config = $this->config()['markdown'] ?? shape();

    $environment = $this->share(Markdown\Environment::class)
      ->addArguments(vec[
        Shapes::idx($config, 'parser', Facebook\Markdown\ParserContext::class),
        Shapes::idx($config, 'context', Facebook\Markdown\RenderContext::class),
        Shapes::idx($config, 'renderer', Facebook\Markdown\Renderer::class),
      ]);

    $this->share(Facebook\Markdown\ParserContext::class);
    $this->share(Facebook\Markdown\RenderContext::class);
    $this->share(
      Facebook\Markdown\Renderer::class,
      Facebook\Markdown\HTMLRenderer::class,
    )
      ->addArgument(Facebook\Markdown\RenderContext::class);

    $extensions = Shapes::idx($config, 'extensions', vec[]);

    foreach ($extensions as $extension) {
      $environment->addMethodCall('use', vec[$extension]);
    }
  }
}
