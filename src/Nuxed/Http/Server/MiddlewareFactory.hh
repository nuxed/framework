<?hh // strict

namespace Nuxed\Http\Server;

use namespace HH\Lib\C;
use type Nuxed\Contract\Http\Message\ServerRequestInterface;
use type Nuxed\Contract\Http\Message\ResponseInterface;
use type Nuxed\Contract\Http\Server\MiddlewareInterface;
use type Nuxed\Contract\Http\Server\RequestHandlerInterface;
use type Nuxed\Contract\Container\ContainerAwareInterface;
use type Nuxed\Contract\Container\ContainerInterface;
use type Nuxed\Container\ContainerAwareTrait;
use type ReflectionFunctionAbstract;
use type ReflectionMethod;
use type ReflectionFunction;
use function is_callable;

class MiddlewareFactory {
  use ContainerAwareTrait;

  public function __construct(
    protected ?ContainerInterface $container = null,
  ) {}

  public function prepare(mixed $middleware): MiddlewareInterface {
    if ($middleware is MiddlewareInterface) {
      if ($this->hasContainer() && $middleware is ContainerAwareInterface) {
        $middleware->setContainer($this->getContainer());
      }
      /* HH_IGNORE_ERROR[4110] */
      return $middleware;
    }

    if ($middleware is RequestHandlerInterface) {
      if ($this->hasContainer() && $middleware is ContainerAwareInterface) {
        $middleware->setContainer($this->getContainer());
      }
      /* HH_IGNORE_ERROR[4110] */
      return new Middleware\RequestHandlerMiddleware($middleware);
    }

    if ($middleware is Container<_>) {
      $pipe = new MiddlewarePipe();
      foreach ($middleware as $value) {
        $pipe->pipe($this->prepare($value));
      }
      return $pipe;
    }

    if (
      $this->hasContainer() &&
      $middleware is string &&
      $this->getContainer()->has($middleware)
    ) {
      return new Middleware\LazyMiddlewareDecorator(
        $this->getContainer(),
        $this,
        $middleware,
      );
    }

    if (is_callable($middleware, false)) {
      if ($middleware is Container<_>) {
        /* HH_IGNORE_ERROR[4110] */
        list($object, $method) = $middleware;
        $reflection = new ReflectionMethod($object, $method);
      } else {
        $reflection = new ReflectionFunction($middleware);
      }

      if ($this->isCallableMiddleware($reflection)) {
        /* HH_IGNORE_ERROR[4110] */
        return new Middleware\CallableMiddlewareDecorator($middleware);
      } elseif ($this->isCallableHandler($reflection)) {
        return new Middleware\RequestHandlerMiddleware(
          new RequestHandler\CallableRequestHandlerDecorator(
            /* HH_IGNORE_ERROR[4110] */
            $middleware,
          ),
        );
      } elseif ($this->isDoublePassMiddleware($reflection)) {
        return /* HH_IGNORE_ERROR[4110] */
        new Middleware\DoublePassMiddlewareDecorator($middleware);
      }
    }

    throw Exception\InvalidMiddlewareException::forMiddleware($middleware);
  }

  private function isCallableMiddleware(
    ReflectionFunctionAbstract $reflection,
  ): bool {
    $parameters = $reflection->getParameters();

    if (C\count($parameters) !== 2) {
      return false;
    }

    $request = $parameters[0]->getType();
    $handler = $parameters[1]->getType();
    $return = $reflection->getReturnType();

    if (null === $request || null === $handler || null === $return) {
      return false;
    }

    if (
      ((string)$request) !== ServerRequestInterface::class ||
      ((string)$handler) !== RequestHandlerInterface::class ||
      ((string)$return) !== ResponseInterface::class
    ) {
      return false;
    }

    return true;
  }

  private function isCallableHandler(
    ReflectionFunctionAbstract $reflection,
  ): bool {
    $parameters = $reflection->getParameters();

    if (C\count($parameters) !== 1) {
      return false;
    }

    $request = $parameters[0]->getType();
    $return = $reflection->getReturnType();

    if (null === $request || null === $return) {
      return false;
    }

    if (
      ((string)$request) !== ServerRequestInterface::class ||
      ((string)$return) !== ResponseInterface::class
    ) {
      return false;
    }

    return true;
  }

  private function isDoublePassMiddleware(
    ReflectionFunctionAbstract $reflection,
  ): bool {
    $parameters = $reflection->getParameters();

    if (C\count($parameters) !== 3) {
      return false;
    }

    $request = $parameters[0]->getType();
    $response = $parameters[1]->getType();
    $handler = $parameters[2]->getType();
    $return = $reflection->getReturnType();

    if (
      null === $request ||
      null === $response ||
      null === $handler ||
      null === $return
    ) {
      return false;
    }

    if (
      ((string)$request) !== ServerRequestInterface::class ||
      ((string)$response) !== ResponseInterface::class ||
      ((string)$handler) !== RequestHandlerInterface::class ||
      ((string)$return) !== ResponseInterface::class
    ) {
      return false;
    }

    return true;
  }

}
