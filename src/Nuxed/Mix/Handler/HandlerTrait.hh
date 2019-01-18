<?hh // strict

namespace Nuxed\Mix\Handler;

use namespace HH\Lib\SecureRandom;
use namespace Nuxed\Io;
use namespace Nuxed\Contract\Log;
use namespace Nuxed\Contract\Http;
use namespace Nuxed\Contract\Event;
use namespace Nuxed\Contract\Cache;
use namespace Nuxed\Contract\Crypto;
use namespace Nuxed\Contract\Http\Router;
use namespace Nuxed\Http\Message\Response;
use type Nuxed\Http\Message\Response;
use type Nuxed\Container\ContainerAwareTrait;
use type AsyncMysqlConnection;
use function bin2hex;
use function hash_equals;

trait HandlerTrait {
  require implements Http\Server\RequestHandlerInterface;

  use ContainerAwareTrait;

  protected function getService<T>(classname<T> $service): T {
    // UNSAFE
    return $this->getContainer()->get($service);
  }

  protected function uri(string $uri): Http\Message\UriInterface {
    return $this->getService(Http\Message\UriFactoryInterface::class)
      ->createUri($uri);
  }

  protected function redirect(
    Http\Message\UriInterface $uri,
    int $status = 302,
    KeyedContainer<string, Container<string>> $headers = dict[],
  ): Http\Message\ResponseInterface {
    $response = $this->getService(Http\Message\ResponseFactoryInterface::class)
      ->createResponse($status);
    foreach ($headers as $key => $value) {
      $response = $response->withHeader($key, $value);
    }
    return $response->withHeader('location', vec[
      (string)$uri,
    ]);
  }

  protected function redirectToRoute(
    string $route,
    KeyedContainer<string, string> $paramters,
    int $status = 302,
  ): Http\Message\ResponseInterface {
    $uri = $this->router()->generateUri($route, $paramters);
    return $this->redirect($uri, $status);
  }

  protected function json(
    mixed $data,
    int $status = 200,
    KeyedContainer<string, Container<string>> $headers = dict[],
  ): Http\Message\ResponseInterface {
    return new Response\JsonResponse($data, $status, $headers);
  }

  protected function html(
    string $html,
    int $status = 200,
    KeyedContainer<string, Container<string>> $headers = dict[],
  ): Http\Message\ResponseInterface {
    return new Response\HtmlResponse($html, $status, $headers);
  }

  protected function xml(
    string $xml,
    int $status = 200,
    KeyedContainer<string, Container<string>> $headers = dict[],
  ): Http\Message\ResponseInterface {
    return new Response\XmlResponse($xml, $status, $headers);
  }

  protected function text(
    string $text,
    int $status = 200,
    KeyedContainer<string, Container<string>> $headers = dict[],
  ): Http\Message\ResponseInterface {
    return new Response\TextResponse($text, $status, $headers);
  }

  protected function response(
    int $status = 200,
    KeyedContainer<string, Container<string>> $headers = dict[],
  ): Http\Message\ResponseInterface {
    return new Response($status, $headers);
  }

  protected function dispatch<TEvent as Event\EventInterface>(
    TEvent $event,
  ): TEvent {
    return $this->getService(Event\EventDispatcherInterface::class)
      ->dispatch($event);
  }

  protected function logger(): Log\LoggerInterface {
    return $this->getService(Log\LoggerInterface::class);
  }

  protected function cache(): Cache\CacheInterface {
    return $this->getService(Cache\CacheInterface::class);
  }

  protected function mysql(): AsyncMysqlConnection {
    return $this->getService(AsyncMysqlConnection::class);
  }

  protected function crypto(): Crypto\CryptoInterface {
    return $this->getService(Crypto\CryptoInterface::class);
  }

  protected function router(): Router\RouterInterface {
    return $this->getService(Router\RouterInterface::class);
  }

  protected function file(
    string $path,
    bool $create = false,
    int $mode = 0777,
  ): Io\File {
    return new Io\File($path, $create, $mode);
  }

  protected function folder(
    string $path,
    bool $create = false,
    int $mode = 0777,
  ): Io\Folder {
    return new Io\Folder($path, $create, $mode);
  }

  protected function session(
    Http\Message\ServerRequestInterface $request,
  ): Http\Session\SessionInterface {
    return $request->getAttribute('session') as Http\Session\SessionInterface;
  }

  protected function flash(
    Http\Message\ServerRequestInterface $request,
  ): Http\Flash\FlashMessagesInterface {
    return $request->getAttribute('flash') as Http\Flash\FlashMessagesInterface;
  }

  protected function generateCsrfToken(
    Http\Message\ServerRequestInterface $request,
    string $name = 'default',
  ): string {
    $session = $this->session($request);
    $token = bin2hex(SecureRandom\string(24));
    $session->set('csrf-token-'.$name, $token);
    return $token;
  }

  protected function validateCsrfToken(
    Http\Message\ServerRequestInterface $request,
    string $token,
    string $name = 'default',
  ): bool {
    $session = $this->session($request);
    $result = /* HH_IGNORE_ERROR[2049] */
    /* HH_IGNORE_ERROR[4107] */
    hash_equals($session->get('csrf-token-'.$name, '') as string, $token);
    $session->remove('csrf-token-'.$name);
    return $result;
  }
}
