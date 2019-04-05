namespace Nuxed\Kernel\ServiceProvider;

use namespace Facebook;
use namespace Nuxed\Markdown;
use namespace Nuxed\Container;

class MarkdownServiceProvider implements Container\ServiceProviderInterface {
  const type TConfig = shape(
    ?'parser' => classname<Facebook\Markdown\ParserContext>,
    ?'context' => classname<Facebook\Markdown\RenderContext>,
    ?'renderer' => classname<Facebook\Markdown\Renderer<string>>,
    ?'extensions' =>
      Container<classname<Markdown\Extension\ExtensionInterface>>,
    ...
  );

  public function __construct(private this::TConfig $config = shape()) {}

  public function register(Container\ContainerBuilder $builder): void {
    $builder->add(
      Markdown\Environment::class,
      Container\factory(
        ($container) ==> {
          $env = new Markdown\Environment(
            $container->get(Shapes::idx(
              $this->config,
              'parser',
              Facebook\Markdown\ParserContext::class,
            )),
            $container->get(Shapes::idx(
              $this->config,
              'context',
              Facebook\Markdown\RenderContext::class,
            )),
            $container->get(Shapes::idx(
              $this->config,
              'renderer',
              Facebook\Markdown\Renderer::class,
            )),
          );
          $extensions = Shapes::idx($this->config, 'extensions', vec[]);

          foreach ($extensions as $extension) {
            $env->use($container->get($extension));
          }

          return $env;
        },
      ),
      true,
    );

    $builder->add(
      Facebook\Markdown\ParserContext::class,
      Container\factory(($container) ==> new Facebook\Markdown\ParserContext()),
      true,
    );

    $builder->add(
      Facebook\Markdown\RenderContext::class,
      Container\factory(($container) ==> new Facebook\Markdown\RenderContext()),
      true,
    );

    $builder->add(
      Facebook\Markdown\Renderer::class,
      Container\factory(
        ($container) ==> new Facebook\Markdown\HTMLRenderer(
          $container->get(Facebook\Markdown\RenderContext::class),
        ),
      ),
      true,
    );
  }
}
