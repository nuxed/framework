namespace Nuxed\Http\Server;

use namespace Nuxed\Http\Message;
use type Nuxed\Contract\Http\Server\MiddlewareInterface;
use type Nuxed\Contract\Http\Server\MiddlewarePipeInterface;
use type Nuxed\Contract\Http\Server\RequestHandlerInterface;
use type Nuxed\Contract\Http\Message\ResponseInterface;
use type Nuxed\Contract\Http\Message\ServerRequestInterface;

/**
 * Callable Middleware Decorator.
 *
 * Decorates callable with the following signature:
 *
 * <code>
 * function (
 *     ServerRequestInterface $request,
 *     RequestHandlerInterface $handler
 * ): Awaitable<ResponseInterface>
 * </code>
 *
 * such that it will operate as a middleware.
 *
 * Neither the arguments nor the return value need be typehinted; however, if
 * the signature is incompatible, an Exception will likely be thrown.
 *
 * @see Middleware\CallableMiddlewareDecorator
 */
function cm(
  (function(
    ServerRequestInterface,
    RequestHandlerInterface,
  ): Awaitable<ResponseInterface>) $middleware,
): MiddlewareInterface {
  return new Middleware\CallableMiddlewareDecorator($middleware);
}

/**
 * Functional Middleware Decorator.
 *
 * Decorates callable with the following signature:
 *
 * <code>
 * function (
 *     ServerRequestInterface $request,
 *     (function(ServerRequestInterface): Awaitable<ResponseInterface>) $next
 * ): Awaitable<ResponseInterface>
 * </code>
 *
 * such that it will operate as a middleware.
 *
 * Neither the arguments nor the return value need be typehinted; however, if
 * the signature is incompatible, an Exception will likely be thrown.
 */
function fm(
  (function(
    ServerRequestInterface,
    (function(ServerRequestInterface): Awaitable<ResponseInterface>),
  ): Awaitable<ResponseInterface>) $middleware,
): MiddlewareInterface {
  return cm(
    ($request, $handler) ==>
      $middleware($request, ($request) ==> $handler->handle($request)),
  );
}

/**
 * Double Pass Middleware Decorator.
 *
 * Decorates callable with the following signature:
 *
 * <code>
 * function(
 *   ServerRequestInterface $request,
 *   ResponseInterface $response,
 *   RequestHandlerInterface $handler,
 * ): Awaitable<ResponseInterface>
 * </code>
 *
 * such that it will operate as a middleware.
 *
 * Neither the arguments nor the return value need be typehinted; however, if
 * the signature is incompatible, an Exception will likely be thrown.
 */
function dm(
  (function(
    ServerRequestInterface,
    ResponseInterface,
    RequestHandlerInterface,
  ): Awaitable<ResponseInterface>) $middleware,
): MiddlewareInterface {
  return cm(($request, $handler) ==> {
    $response = new Message\Response();
    return $middleware($request, $response, $handler);
  });
}

/**
 * Double Pass Functional Middleware Decorator.
 *
 * Decorates callable with the following signature:
 *
 * <code>
 * function(
 *   ServerRequestInterface $request,
 *   ResponseInterface $response,
 *   (function(ServerRequestInterface): Awaitable<ResponseInterface>) $next,
 * ): Awaitable<ResponseInterface>
 * </code>
 *
 * such that it will operate as a middleware.
 *
 * Neither the arguments nor the return value need be typehinted; however, if
 * the signature is incompatible, an Exception will likely be thrown.
 */
function dfm(
  (function(
    ServerRequestInterface,
    ResponseInterface,
    (function(ServerRequestInterface): Awaitable<ResponseInterface>),
  ): Awaitable<ResponseInterface>) $middleware,
): MiddlewareInterface {
  return cm(($request, $handler) ==> {
    $response = new Message\Response();
    $next = ($request) ==> $handler->handle($request);
    return $middleware($request, $response, $next);
  });
}

/**
 * Lazy Middleware Decorator.
 *
 * Create a lazy middleware from a factory with the following signature:
 *
 * <code>
 * function(): MiddlewareInterface
 * </code>
 *
 * The factory will be only executade if process is called on the middleware.
 */
function lm((function(): MiddlewareInterface) $factory): MiddlewareInterface {
  return cm(($request, $handler) ==> {
    return $factory()
      |> $$->process($request, $handler);
  });
}

/**
 * Callable Request Handler Decorator.
 *
 * Decorates callable with the following signature:
 *
 * <code>
 * function (
 *     ServerRequestInterface $request,
 * ): Awaitable<ResponseInterface>
 * </code>
 *
 * such that it will operate as a Request handler.
 *
 * Neither the arguments nor the return value need be typehinted; however, if
 * the signature is incompatible, an Exception will likely be thrown.
 *
 * @see RequestHandler\CallableRequestHandlerDecorator
 * @see cm
 */
function ch(
  (function(ServerRequestInterface): Awaitable<ResponseInterface>) $handler,
): RequestHandlerInterface {
  return new RequestHandler\CallableRequestHandlerDecorator($handler);
}

/**
 * Double Pass Request Handler Decorator.
 *
 * Decorates callable with the following signature:
 *
 * <code>
 * function (
 *     ServerRequestInterface $request,
 *     ResponseInterface $response
 * ): Awaitable<ResponseInterface>
 * </code>
 *
 * such that it will operate as a Request handler.
 *
 * Neither the arguments nor the return value need be typehinted; however, if
 * the signature is incompatible, an Exception will likely be thrown.
 *
 * @see dm
 */
function dh(
  (function(
    ServerRequestInterface,
    ResponseInterface,
  ): Awaitable<ResponseInterface>) $handler,
): RequestHandlerInterface {
  return ch(($request) ==> {
    $response = new Message\Response();
    return $handler($request, $response);
  });
}

/**
 * Lazy Request Handler Decorator.
 *
 * Create a lazy request handler from a factory with the following signature:
 *
 * <code>
 * function(): RequestHandlerInterface
 * </code>
 *
 * The factory will be only executade if handle is called on the request handler.
 */
function lh(
  (function(): RequestHandlerInterface) $factory,
): RequestHandlerInterface {
  return ch(($request) ==> {
    return $factory()
      |> $$->handle($request);
  });
}

/**
 * Request Handler Middleware Decorator.
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
 * @see Middleware\RequestHandlerMiddleware
 */
function hm(
  RequestHandlerInterface $handler,
): Middleware\RequestHandlerMiddleware {
  return new Middleware\RequestHandlerMiddleware($handler);
}

function host(
  string $host,
  MiddlewareInterface $middleware,
): MiddlewareInterface {
  return new Middleware\HostMiddlewareDecorator($host, $middleware);
}

function path(
  string $path,
  MiddlewareInterface $middleware,
): MiddlewareInterface {
  return new Middleware\PathMiddlewareDecorator($path, $middleware);
}

function pipe(MiddlewareInterface ...$middlewares): MiddlewarePipeInterface {
  $pipe = new MiddlewarePipe();
  foreach ($middlewares as $middleware) {
    $pipe->pipe($middleware);
  }

  return $pipe;
}
