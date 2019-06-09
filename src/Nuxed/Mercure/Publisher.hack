namespace Nuxed\Mercure;

use namespace HH\Lib\Str;
use namespace HH\Lib\Regex;
use namespace Nuxed\Http\Client;
use namespace Nuxed\Http\Message;

/**
 * Publishes an update to the hub.
 *
 * @author Saif Eddin Gmati <azjezz@protonmail.com>
 *
 * Logic largely refactored from the Symfony Mercure component.
 *
 * @see       https://github.com/symfony/mercure
 * @copyright Copyright (c) 2018 Kévin Dunglas
 * @license   https://github.com/symfony/mercure/blob/master/LICENSE MIT License
 */
final class Publisher {
  public function __construct(
    private Message\Uri $hub,
    private IJwtProvider $provider,
    private Client\IHttpClient $http = Client\HttpClient::create(),
  ) {}

  public async function publish(Update $update): Awaitable<string> {
    $request = Message\request('POST', $this->hub)
      ->withHeader('Authorization', vec[
        Str\format('Bearer %s', $this->getJwt()),
      ]);
    await $request->getBody()->writeAsync($this->buildQuery($update));
    $response = await $this->http->send($request);

    return await $response->getBody()->readAsync();
  }

  private function buildQuery(Update $update): string {
    $query = '';
    foreach ($update->getTopics() as $topic) {
      $query .= Str\format('topic=%s&', \urlencode($topic));
    }

    $query .= Str\format('data=%s&', \urlencode($update->getData()));
    foreach ($update->getTargets() as $target) {
      $query .= Str\format('target=%s&', \urlencode($target));
    }

    $id = $update->getId();
    if ($id is nonnull) {
      $query .= Str\format('id=%s&', \urlencode($id));
    }

    $type = $update->getType();
    if ($type is nonnull) {
      $query .= Str\format('type=%s&', \urlencode($type));
    }

    $retry = $update->getRetry();
    if ($retry is nonnull) {
      $query .= Str\format('retry=%d', $retry);
    }

    return Str\trim_right($query, '&');
  }

  private function getJwt(): string {
    $jwt = $this->provider->getJwt();
    $this->validateJwt($jwt);

    return $jwt;
  }

  /**
   * Regex ported from Windows Azure Active Directory IdentityModel Extensions for .Net.
   *
   * @throws Exception\InvalidArgumentException
   *
   * @license MIT
   * @copyright Copyright (c) Microsoft Corporation
   *
   * @see https://github.com/AzureAD/azure-activedirectory-identitymodel-extensions-for-dotnet/blob/6e7a53e241e4566998d3bf365f03acd0da699a31/src/Microsoft.IdentityModel.JsonWebTokens/JwtConstants.cs#L58
   */
  private function validateJwt(string $jwt): void {
    if (
      !Regex\matches(
        $jwt,
        re"/^[A-Za-z0-9-_]+\.[A-Za-z0-9-_]+\.[A-Za-z0-9-_]*$/",
      )
    ) {
      throw new Exception\InvalidArgumentException(
        'The provided JWT is not valid',
      );
    }
  }
}
