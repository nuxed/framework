namespace Nuxed\Kernel\Extension;

use namespace Nuxed\Kernel;
use namespace Nuxed\Container;
use namespace Nuxed\Http\Emitter;
use namespace Nuxed\Http\Server;
use namespace Nuxed\Http\Router;
use namespace Nuxed\Kernel\Handler;
use namespace Nuxed\Kernel\Middleware;


class HttpExtension extends AbstractExtension {
  <<__Override>>
  public function register(Container\ContainerBuilder $builder): void {
    $builder->add(
      Kernel\Middleware\ErrorMiddleware::class,
      new Kernel\Middleware\ErrorMiddlewareFactory(),
      true,
    );

    $builder->add(
      Kernel\Error\IErrorHandler::class,
      new Kernel\Error\ErrorHandlerFactory(),
      true,
    );

    $builder->add(
      Kernel\Handler\NotFoundHandler::class,
      new Kernel\Handler\NotFoundHandlerFactory(),
      true,
    );

    $builder->add(Emitter\IEmitter::class, new Emitter\EmitterFactory(), true);
    $builder->add(
      Server\MiddlewareStack::class,
      new Server\MiddlewareStackFactory(),
      true,
    );
    $builder->register(new Router\RouterServiceProvider());
  }

  <<__Override>>
  public function stack(
    Server\MiddlewareStack $middleware,
    Container\IServiceContainer $container,
  ): void {
    /*
     *  The error handler should be the first (most outer) middleware to catch
     *  all Exceptions.
     */
    $middleware->stack(
      Server\lm(() ==> $container->get(Middleware\ErrorMiddleware::class)),
      0x10000,
    );

    /*
     * Register the routing middleware in the middleware pipeline.
     * This middleware register the Nuxed\Router\RouteResult request attribute.
     */
    $middleware->stack(
      Server\lm(
        () ==> $container->get(Router\Middleware\RouteMiddleware::class),
      ),
      -0x9500,
    );

    /*
     * The following handle routing failures for common conditions:
     * - HEAD request but no routes answer that method
     * - OPTIONS request but no routes answer that method
     * - method not allowed
     * Order here maters; the
     */
    $middleware->stack(
      Server\lm(
        () ==> $container->get(Router\Middleware\ImplicitHeadMiddleware::class),
      ),
      -0x9600,
    );
    $middleware->stack(
      Server\lm(
        () ==>
          $container->get(Router\Middleware\ImplicitOptionsMiddleware::class),
      ),
      -0x9700,
    );
    $middleware->stack(
      Server\lm(
        () ==>
          $container->get(Router\Middleware\MethodNotAllowedMiddleware::class),
      ),
      -0x9800,
    );

    /*
     * Register the dispatch middleware in the middleware pipeline.
     */
    $middleware->stack(
      Server\lm(
        () ==> $container->get(Router\Middleware\DispatchMiddleware::class),
      ),
      -0x09900,
    );

    /*
     * At this point, if no Response is returned by any middleware, the
     * NotFoundHandler kicks in; alternately, you can provide other fallback
     * middleware to execute.
     */
    $middleware->stack(
      Server\hm(
        Server\lh(() ==> $container->get(Handler\NotFoundHandler::class)),
      ),
      -0x10000,
    );
  }
}
