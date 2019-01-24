<?hh // strict

namespace Nuxed\Kernel\Handler;

use namespace Nuxed\Http\Message;
use type Nuxed\Contract\Http\Server\RequestHandlerInterface;
use type Nuxed\Contract\Http\Message\UriInterface;
use type Stringish;

trait ResponseFactoryTrait {
  require implements RequestHandlerInterface;

  protected function uri(string $uri): Message\Uri {
    return new Message\Uri($uri);
  }

  protected function redirect(
    UriInterface $uri,
    int $status = 302,
    KeyedContainer<string, Container<string>> $headers = dict[],
  ): Message\Response\RedirectResponse {
    return new Message\Response\RedirectResponse($uri, $status, $headers);
  }

  protected function json(
    mixed $data,
    int $status = 200,
    KeyedContainer<string, Container<string>> $headers = dict[],
  ): Message\Response\JsonResponse {
    return new Message\Response\JsonResponse($data, $status, $headers);
  }

  protected function html(
    Stringish $html,
    int $status = 200,
    KeyedContainer<string, Container<string>> $headers = dict[],
  ): Message\Response\HtmlResponse {
    return new Message\Response\HtmlResponse((string)$html, $status, $headers);
  }

  protected function xml(
    Stringish $xml,
    int $status = 200,
    KeyedContainer<string, Container<string>> $headers = dict[],
  ): Message\Response\XmlResponse {
    return new Message\Response\XmlResponse((string)$xml, $status, $headers);
  }

  protected function text(
    Stringish $text,
    int $status = 200,
    KeyedContainer<string, Container<string>> $headers = dict[],
  ): Message\Response\TextResponse {
    return new Message\Response\TextResponse((string)$text, $status, $headers);
  }

  protected function response(
    int $status = 200,
    KeyedContainer<string, Container<string>> $headers = dict[],
  ): Message\Response {
    return new Message\Response($status, $headers);
  }
}
