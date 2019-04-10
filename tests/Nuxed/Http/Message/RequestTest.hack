namespace Nuxed\Test\Http\Message;

use namespace Nuxed\Http\Message;
use namespace Nuxed\Http\Message\Exception;
use type Facebook\HackTest\HackTest;
use type Nuxed\Contract\Http\Message\StreamInterface;
use function Facebook\FBExpect\expect;

class RequestTest extends HackTest {
  public function testRequestUriMayBeUri(): void {
    $uri = Message\uri('/');
    $r = new Message\Request('GET', $uri);
    expect($r->getUri())->toBeSame($uri);
  }

  public async function testNullBody(): Awaitable<void> {
    $r = new Message\Request('GET', Message\uri('/'), dict[], null);
    expect($r->getBody())->toBeInstanceOf(StreamInterface::class);
    $body = await $r->getBody()->readAsync();
    expect($body)->toBeSame('');
  }

  public function testWithUri(): void {
    $r1 = new Message\Request('GET', Message\uri('/'));
    $u1 = $r1->getUri();
    $u2 = Message\uri('http://www.example.com');
    $r2 = $r1->withUri($u2);
    expect($r2)->toNotBeSame($r1);
    expect($r2->getUri())->toBeSame($u2);
    expect($r1->getUri())->toBeSame($u1);
  }

  public function testSameInstanceWhenSameUri(): void {
    $r1 = new Message\Request('GET', Message\uri('http://foo.com'));
    $r2 = $r1->withUri($r1->getUri());
    expect($r2)->toBeSame($r1);
  }

  public function testWithRequestTarget(): void {
    $r1 = new Message\Request('GET', Message\uri('/'));
    $r2 = $r1->withRequestTarget('*');
    expect($r2->getRequestTarget())->toBeSame('*');
    expect($r1->getRequestTarget())->toBeSame('/');
  }

  public function testRequestTargetDoesNotAllowSpaces(): void {
    expect(() ==> {
      $r1 = new Message\Request('GET', Message\uri('/'));
      $r1->withRequestTarget('/foo bar');
    })->toThrow(
      Exception\InvalidArgumentException::class,
      'Invalid request target provided; cannot contain whitespace',
    );
  }

  public function testRequestTargetDefaultsToSlash(): void {
    $r1 = new Message\Request('GET', Message\uri(''));
    expect($r1->getRequestTarget())->toBeSame('/');
    $r2 = new Message\Request('GET', Message\uri('*'));
    expect($r2->getRequestTarget())->toBeSame('*');
    $r3 = new Message\Request('GET', Message\uri('http://foo.com/bar baz/'));
    expect($r3->getRequestTarget())->toBeSame('/bar%20baz/');
  }

  public function testBuildsRequestTarget(): void {
    $r1 = new Message\Request('GET', Message\uri('http://foo.com/baz?bar=bam'));
    expect($r1->getRequestTarget())->toBeSame('/baz?bar=bam');
  }

  public function testBuildsRequestTargetWithFalseyQuery(): void {
    $r1 = new Message\Request('GET', Message\uri('http://foo.com/baz?0'));
    expect($r1->getRequestTarget())->toBeSame('/baz?0');
  }

  public function testHostIsAddedFirst(): void {
    $r = new Message\Request(
      'GET',
      Message\uri('http://foo.com/baz?bar=bam'),
      dict[
        'Foo' => vec['Bar'],
      ],
    );
    expect($r->getHeaders())->toBeSame(dict[
      'Host' => vec['foo.com'],
      'Foo' => vec['Bar'],
    ]);
  }

  public function testCanGetHeaderAsCsv(): void {
    $r = new Message\Request(
      'GET',
      Message\uri('http://foo.com/baz?bar=bam'),
      dict[
        'Foo' => vec['a', 'b', 'c'],
      ],
    );
    expect($r->getHeaderLine('Foo'))->toBeSame('a, b, c');
    expect($r->getHeaderLine('Bar'))->toBeSame('');
  }

  public function testHostIsNotOverwrittenWhenPreservingHost(): void {
    $r = new Message\Request(
      'GET',
      Message\uri('http://foo.com/baz?bar=bam'),
      dict[
        'Host' => vec[
          'facebook.com',
        ],
      ],
    );
    expect($r->getHeaders())->toBeSame(dict['Host' => vec['facebook.com']]);
    $r2 = $r->withUri(Message\uri('http://www.messenger.com/t/azjezz'), true);
    expect($r2->getHeaderLine('Host'))->toBeSame('facebook.com');
  }

  public function testOverridesHostWithUri(): void {
    $r = new Message\Request('GET', Message\uri('https://docs.hhvm.com/hack?bar=bam'));
    expect($r->getHeaders())->toBeSame(dict['Host' => vec['docs.hhvm.com']]);
    $r2 = $r->withUri(Message\uri('https://hacklang.org/tutorial.html'));
    expect($r2->getHeaderLine('Host'))->toBeSame('hacklang.org');
  }

  public function testUniqueAggregatesHeaders(): void {
    $r = new Message\Request(
      'GET',
      Message\uri(''),
      dict[
        'ZOO' => vec['zoobar'],
        'zoo' => vec['foobar', 'zoobar'],
      ],
    );
    expect($r->getHeaders())->toBeSame(dict['ZOO' => vec['zoobar', 'foobar']]);
    expect($r->getHeaderLine('zoo'))->toBeSame('zoobar, foobar');
  }

  public function testAddsPortToHeader(): void {
    $r = new Message\Request('GET', Message\uri('http://foo.com:8124/bar'));
    expect($r->getHeaderLine('host'))->toBeSame('foo.com:8124');
  }

  public function testAddsPortToHeaderAndReplacePreviousPort(): void {
    $r = new Message\Request('GET', Message\uri('http://foo.com:8124/bar'));
    $r = $r->withUri(Message\uri('http://foo.com:8125/bar'));
    expect($r->getHeaderLine('host'))->toBeSame('foo.com:8125');
  }

  public function testCannotHaveHeaderWithEmptyName(): void {
    expect(() ==> {
      $r = new Message\Request('GET', Message\uri('https://example.com/'));
      $r = $r->withHeader('', vec['Bar']);
    })->toThrow(
      Exception\InvalidArgumentException::class,
      'Header name must be an RFC 7230 compatible string.',
    );
  }

  public function testCanHaveHeaderWithEmptyValue(): void {
    $r = new Message\Request('GET', Message\uri('https://example.com/'));
    $r = $r->withHeader('Foo', vec['']);
    expect($r->getHeader('Foo'))->toBeSame(vec['']);
  }
}
