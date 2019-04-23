namespace Nuxed\Http\Emitter;

use namespace HH\Lib\Str;
use namespace HH\Lib\Regex;
use namespace HH\Lib\Experimental\IO;
use namespace Nuxed\Contract\Http\Message;

type MaxBufferLength = int;

final class SapiStreamEmitter extends SapiEmitter {
  /**
   * @param int $maxBufferLength Maximum output buffering size for each iteration
   */
  public function __construct(
    private MaxBufferLength $maxBufferLength = 8192,
  ) {}

  const type TContentRange = shape(
    'unit' => string,
    'first' => int,
    'last' => int,
    'length' => ?int,
    ...
  );

  <<__Override>>
  public async function emit(
    Message\ResponseInterface $response,
  ): Awaitable<bool> {
    $this->assertNoPreviousOutput();
    $this->emitHeaders($response);
    $this->emitStatusLine($response);

    $header = $response->getHeaderLine('Content-Range');
    $range = $this->parseContentRageHeader($header);
    if ($range is null || $range['unit'] !== 'bytes') {
      await $this->emitBody($response);
      return true;
    }

    await $this->emitBodyRange($response, $range);
    return true;
  }

  <<__Override>>
  protected async function emitBody(
    Message\ResponseInterface $response,
  ): Awaitable<void> {
    $stream = $response->getBody();
    if ($stream->isSeekable()) {
      $stream->seek(0);
    }

    $output = IO\request_output();
    while (!$stream->isEndOfFile()) {
      $content = await $stream->readAsync($this->maxBufferLength);
      await $output->writeAsync($content);
    }

    await $output->closeAsync();
  }

  protected async function emitBodyRange(
    Message\ResponseInterface $response,
    this::TContentRange $range,
  ): Awaitable<void> {
    $stream = $response->getBody();
    $length = $range['last'] - $range['first'] + 1;

    if ($stream->isSeekable()) {
      $stream->seek($range['first']);

      $first = 0;
    }

    $remaining = $length;
    $output = IO\server_output();
    while ($remaining >= $this->maxBufferLength && !$stream->isEndOfFile()) {
      $contents = await $stream->readAsync($this->maxBufferLength);
      $remaining -= Str\length($contents);
      await $output->writeAsync($contents);
    }

    if ($remaining > 0 && !$stream->isEndOfFile()) {
      $contents = await $stream->readAsync($remaining);
      await $output->writeAsync($contents);
    }
  }

  private function parseContentRageHeader(
    string $header,
  ): ?this::TContentRange {
    $pattern =
      re"/(?P<unit>[\w]+)\s+(?P<first>\d+)-(?P<last>\d+)\/(?P<length>\d+|\*)/";

    if (!Regex\matches($header, $pattern)) {
      return null;
    }

    $matches = Regex\first_match($header, $pattern) as nonnull;
    return shape(
      'unit' => $matches['unit'],
      'first' => (int)$matches['first'],
      'last' => (int)$matches['last'],
      'length' => $matches['length'] === '*' ? null : (int)$matches['length'],
    );
  }
}
