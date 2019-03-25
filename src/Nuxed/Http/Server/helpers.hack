namespace Nuxed\Http\Server;

use namespace Nuxed\Http\Message;
use type Nuxed\Contract\Http\Server\MiddlewareInterface;
use type Nuxed\Contract\Http\Server\RequestHandlerInterface;
use type Nuxed\Contract\Http\Message\ResponseInterface;
use type Nuxed\Contract\Http\Message\ServerRequestInterface;

function cm(
  (function(
    ServerRequestInterface,
    RequestHandlerInterface,
  ): Awaitable<ResponseInterface>) $middleware,
): MiddlewareInterface {
  return new Middleware\CallableMiddlewareDecorator($middleware);
}

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

function lm((function(): MiddlewareInterface) $factory): MiddlewareInterface {
  return cm(($request, $handler) ==> {
    return $factory()
      |> $$->process($request, $handler);
  });
}

function ch(
  (function(ServerRequestInterface): Awaitable<ResponseInterface>) $handler,
): RequestHandlerInterface {
  return new RequestHandler\CallableRequestHandlerDecorator($handler);
}

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

function lh(
  (function(): RequestHandlerInterface) $factory,
): RequestHandlerInterface {
  return ch(($request) ==> {
    return $factory()
      |> $$->handle($request);
  });
}

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

function pipe(MiddlewareInterface ...$middlewares): MiddlewareInterface {
  $pipe = new MiddlewarePipe();
  foreach ($middlewares as $middleware) {
    $pipe->pipe($middleware);
  }
  return $pipe;
}
