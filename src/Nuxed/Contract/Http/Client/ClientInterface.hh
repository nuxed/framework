<?hh // strict

namespace Nuxed\Contract\Http\Client;

use type Nuxed\Contract\Http\Message\RequestInterface;
use type Nuxed\Contract\Http\Message\ResponseInterface;

interface ClientInterface {
  /**
   * Sends a request and returns a response.
   *
   * @param RequestInterface $request
   *
   * @return ResponseInterface
   *
   * @throws \Nuxed\Contract\Http\Client\ClientExceptionInterface If an error happens while processing the request.
   */
  public function send(RequestInterface $request): ResponseInterface;
}
