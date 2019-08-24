namespace Nuxed\Http\Server;

use namespace Nuxed\Http\Message;

/**
 * Callable Middleware Decorator.
 *
 * @see Middleware\CallableMiddlewareDecorator
 */
function cm(CallableMiddleware $middleware): IMiddleware {
  return new Middleware\CallableMiddlewareDecorator($middleware);
}

/**
 * Functional Middleware Decorator.
 */
function fm(FunctionalMiddleware $middleware): IMiddleware {
  return cm(
    ($request, $handler) ==>
      $middleware($request, ($request) ==> $handler->handle($request)),
  );
}

/**
 * Double Pass Middleware Decorator.
 */
function dm(DoublePassMiddleware $middleware): IMiddleware {
  return cm(($request, $handler) ==> {
    $response = new Message\Response();
    return $middleware($request, $response, $handler);
  });
}

/**
 * Double Pass Functional Middleware Decorator.
 */
function dfm(DoublePassFunctionalMiddleware $middleware): IMiddleware {
  return cm(($request, $handler) ==> {
    $response = new Message\Response();
    $next = ($request) ==> $handler->handle($request);
    return $middleware($request, $response, $next);
  });
}

/**
 * Lazy Middleware Decorator.
 */
function lm(LazyMiddleware $factory): IMiddleware {
  return cm(($request, $handler) ==> {
    return $factory()
      |> $$->process($request, $handler);
  });
}

/**
 * Callable Handler Decorator.
 *
 * @see Handler\CallableHandlerDecorator
 * @see cm
 */
function ch(CallableHandler $handler): IHandler {
  return new Handler\CallableHandlerDecorator($handler);
}

/**
 * Double Pass Handler Decorator.
 *
 * @see dm
 */
function dh(DoublePassHandler $handler): IHandler {
  return ch(($request) ==> {
    $response = new Message\Response();
    return $handler($request, $response);
  });
}

/**
 * Lazy Handler Decorator.
 */
function lh(LazyHandler $factory): IHandler {
  return ch(($request) ==> {
    return $factory()
      |> $$->handle($request);
  });
}

/**
 * Handler Middleware Decorator.
 *
 * Decorate a request handler as middleware.
 *
 * When pulling handlers from a container, or creating pipelines, it's
 * simplest if everything is of the same type, so we do not need to worry
 * about varying execution based on type.
 *
 * To manage this, this function decorates request handlers as middleware, so that
 * they may be piped or routed to. When processed, they delegate handling to the
 * decorated handler, which will return a response.
 *
 * @see Middleware\HandlerMiddlewareDecorator
 */
function hm(
  IHandler $handler,
): Middleware\HandlerMiddlewareDecorator {
  return new Middleware\HandlerMiddlewareDecorator($handler);
}

function host(string $host, IMiddleware $middleware): IMiddleware {
  return new Middleware\HostMiddlewareDecorator($host, $middleware);
}

function path(string $path, IMiddleware $middleware): IMiddleware {
  return new Middleware\PathMiddlewareDecorator($path, $middleware);
}

function stack(IMiddleware ...$middleware): IMiddlewareStack {
  $stack = new MiddlewareStack();
  foreach ($middleware as $mw) {
    $stack->stack($mw);
  }

  return $stack;
}
