<?hh // strict

namespace Nuxed\Kernel\Handler;

use namespace Nuxed\Http\Message;
use namespace Nuxed\Contract\Http;
use type Nuxed\Contract\Http\Server\RequestHandlerInterface;

trait ResponseFactoryTrait {
  require implements RequestHandlerInterface;

  protected function uri(string $uri): Http\Message\UriInterface {
    return new Message\Uri($uri);
  }

  protected function redirect(
    Http\Message\UriInterface $uri,
    int $status = 302,
    KeyedContainer<string, Container<string>> $headers = dict[],
  ): Http\Message\ResponseInterface {
    return new Message\Response\RedirectResponse($uri, $status, $headers);
  }

  protected function json(
    mixed $data,
    int $status = 200,
    KeyedContainer<string, Container<string>> $headers = dict[],
  ): Http\Message\ResponseInterface {
    return new Message\Response\JsonResponse($data, $status, $headers);
  }

  protected function html(
    string $html,
    int $status = 200,
    KeyedContainer<string, Container<string>> $headers = dict[],
  ): Http\Message\ResponseInterface {
    return new Message\Response\HtmlResponse($html, $status, $headers);
  }

  protected function xml(
    string $xml,
    int $status = 200,
    KeyedContainer<string, Container<string>> $headers = dict[],
  ): Http\Message\ResponseInterface {
    return new Message\Response\XmlResponse($xml, $status, $headers);
  }

  protected function text(
    string $text,
    int $status = 200,
    KeyedContainer<string, Container<string>> $headers = dict[],
  ): Http\Message\ResponseInterface {
    return new Message\Response\TextResponse($text, $status, $headers);
  }

  protected function response(
    int $status = 200,
    KeyedContainer<string, Container<string>> $headers = dict[],
  ): Http\Message\ResponseInterface {
    return new Message\Response($status, $headers);
  }
}
