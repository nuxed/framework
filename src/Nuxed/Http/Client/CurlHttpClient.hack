namespace Nuxed\Http\Client;

use namespace HH\Asio;
use namespace HH\Lib\C;
use namespace HH\Lib\Str;
use namespace HH\Lib\Dict;
use namespace HH\Lib\Math;
use namespace HH\Lib\Regex;
use namespace Nuxed\Http\Message;

final class CurlHttpClient extends HttpClient {
  public function __construct(HttpClientOptions $options) {
    parent::__construct($options);
  }

  /**
   * Sends a request and returns a response.
   *
   * @param Message\Request $request
   *
   * @return Awaitable<Message\Response>
   *
   * @throws Exception\IException If an error happens while processing the request.
   */
  <<__Override>>
  public async function send(
    Message\Request $request,
  ): Awaitable<Message\Response> {
    $request = $this->prepare($request);
    $uri = $request->getUri();

    $timeout = $this->options['timeout'] ??
      (float)\ini_get('default_socket_timeout');
    $ciphers = $this->options['ciphers'] ?? null;
    if ($ciphers is nonnull) {
      $ciphers = Str\join($ciphers, ',')
        |> $$ === '' ? null : $$;
    }

    $curlOptions = dict[
      \CURLOPT_URL => $uri->toString(),
      \CURLOPT_USERAGENT => 'Nuxed HttpClient/Curl',
      \CURLOPT_TCP_NODELAY => true,
      \CURLOPT_PROTOCOLS => \CURLPROTO_HTTP | \CURLPROTO_HTTPS,
      \CURLOPT_REDIR_PROTOCOLS => \CURLPROTO_HTTP | \CURLPROTO_HTTPS,
      \CURLOPT_FOLLOWLOCATION => true,
      \CURLOPT_RETURNTRANSFER => true,
      \CURLOPT_HEADER => true,
      \CURLOPT_MAXREDIRS =>
        Math\max(vec[0, $this->options['max_redirects'] ?? 0]),
      \CURLOPT_COOKIEFILE => '', // Keep track of cookies during redirects
      \CURLOPT_CONNECTTIMEOUT_MS => 1000 * $timeout,
      \CURLOPT_PROXY => $this->options['proxy'] ?? null,
      \CURLOPT_NOPROXY => $this->options['no_proxy'] ?? '',
      \CURLOPT_SSL_VERIFYPEER => $this->options['verify_peer'] ?? true,
      \CURLOPT_SSL_VERIFYHOST =>
        ($this->options['verify_host'] ?? true) ? 2 : 0,
      \CURLOPT_CAINFO => $this->options['cafile'] ?? null,
      \CURLOPT_CAPATH => $this->options['capath'] ?? null,
      \CURLOPT_SSL_CIPHER_LIST => $ciphers,
      \CURLOPT_SSLCERT => $this->options['local_cert'] ?? null,
      \CURLOPT_SSLKEY => $this->options['local_pk'] ?? null,
      \CURLOPT_KEYPASSWD => $this->options['passphrase'] ?? null,
      \CURLOPT_CERTINFO => $this->options['capture_peer_cert_chain'] ?? null,
      \CURLOPT_HEADEROPT => \CURLHEADER_SEPARATE,
    ];

    $protocolVersion = (float)$request->getProtocolVersion();
    if (1.0 === $protocolVersion) {
      $curlOptions[\CURLOPT_HTTP_VERSION] = \CURL_HTTP_VERSION_1_0;
    } else if (1.1 === $protocolVersion) {
      $curlOptions[\CURLOPT_HTTP_VERSION] = \CURL_HTTP_VERSION_1_1;
    } else {
      $curlOptions[\CURLOPT_HTTP_VERSION] = \CURL_HTTP_VERSION_2_0;
    }

    $method = $request->getMethod();

    if ('POST' === $method) {
      // Use CURLOPT_POST to have browser-like POST-to-GET redirects for 301, 302 and 303
      $curlOptions[\CURLOPT_POST] = true;
    } else {
      $curlOptions[\CURLOPT_CUSTOMREQUEST] = $method;
    }

    if ($timeout < 1) {
      $curlOptions[\CURLOPT_NOSIGNAL] = true;
    }

    if (!$request->hasHeader('accept-encoding')) {
      $curlOptions[\CURLOPT_ENCODING] = ''; // Enable HTTP compression
    }


    $headers = vec[];
    foreach ($request->getHeaders() as $name => $_values) {
      $headers[] = Str\format('%s: %s', $name, $request->getHeaderLine($name));
    }

    // Prevent curl from sending its default Accept and Expect headers
    foreach (vec['Accept', 'Expect'] as $header) {
      if (!$request->hasHeader($header)) {
        $headers[] = $header.':';
      }
    }
    $curlOptions[\CURLOPT_HTTPHEADER] = $headers;

    $content = await $request->getBody()->readAsync();
    if ('' !== $content) {
      $curlOptions[\CURLOPT_POSTFIELDS] = $content;
    }

    $fingerprint = $this->options['peer_fingerprint'] ?? dict[];
    foreach ($fingerprint as $algo => $digest) {
      if ($algo !== 'pin-sha256') {
        throw new Exception\RequestException(
          $request,
          Str\format('%s supports only "pin-sha256" fingerprints.', __CLASS__),
        );
      }

      $curlOptions[\CURLOPT_PINNEDPUBLICKEY] = Str\format(
        'sha256//%s',
        Str\join($digest, ';sha256//'),
      );
    }

    $bindto = $this->options['bindto'] ?? '0';
    if (\file_exists($bindto)) {
      $curlOptions[\CURLOPT_UNIX_SOCKET_PATH] = $bindto;
    } else {
      $curlOptions[\CURLOPT_INTERFACE] = $bindto;
    }

    $ch = \curl_init();
    foreach ($curlOptions as $opt => $value) {
      if (null !== $value) {
        $set = \curl_setopt($ch, $opt, $value);
        if (!$set && \CURLOPT_CERTINFO !== $opt) {
          $const = (string)(
            C\first(Dict\filter_with_key(
              \get_defined_constants(),
              ($key, $value) ==> $opt === $value &&
                'C' === $key[0] &&
                (
                  Str\starts_with($key, 'CURLOPT_') ||
                  Str\starts_with($key, 'CURLINFO_')
                ),
            )) ??
            $opt
          );

          throw new Exception\RequestException(
            $request,
            Str\format('Curl option "%s" is not supported.', $const),
          );
        }
      }
    }

    $result = await Asio\curl_exec($ch);
    $error = \curl_error($ch);
    if ($error !== '') {
      throw new Exception\NetworkException($request, $error);
    }

    $status = (int)\curl_getinfo($ch, \CURLINFO_RESPONSE_CODE);
    $response = new Message\Response($status);

    $size = (int)\curl_getinfo($ch, \CURLINFO_HEADER_SIZE);
    $content = Str\slice($result, $size);

    $response = $response->withBody(Message\stream(Str\slice($result, $size)));
    $headers = Str\split(Str\slice($result, 0, $size), "\n");
    foreach ($headers as $header) {
      if (!Str\contains($header, ':')) {
        if (Str\starts_with($header, 'HTTP')) {
          $header = Str\trim($header)
            |> Str\slice($$, 0, Str\search($header, (string)$status))
            |> Str\trim($$);

          $response = Regex\first_match(
            $header,
            re"#^(HTTP/)?(?P<version>[1-9]\d*(?:\.\d)?)$#",
          ) as nonnull
            |> $$['version']
            |> Str\contains($$, '.') ? $$ : ($$.'.0')
            |> $response->withProtocolVersion($$);
        }
        continue;
      }

      $response = Str\split($header, ':', 2)
        |> tuple(Str\trim($$[0]), vec[Str\trim($$[1])])
        |> $response->withAddedHeader($$[0], $$[1]);
    }

    return $response;
  }
}
