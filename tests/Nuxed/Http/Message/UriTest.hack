namespace Nuxed\Test\Http\Message;

use namespace Nuxed\Http\Message;
use type Facebook\HackTest\HackTest;
use type Facebook\HackTest\DataProvider;
use function Facebook\FBExpect\expect;

class UriTest extends HackTest {
  const string RFC3986_BASE = 'http://a/b/c/d;p?q';

  public function testParsesProvidedUri(): void {
    $uri = new Message\Uri(
      'https://user:pass@example.com:8080/path/123?q=abc#test',
    );
    expect($uri->getScheme())->toBeSame('https');
    expect($uri->getAuthority())->toBeSame('user:pass@example.com:8080');
    expect($uri->getUserInfo())->toBeSame(tuple('user', 'pass'));
    expect($uri->getHost())->toBeSame('example.com');
    expect($uri->getPort())->toBeSame(8080);
    expect($uri->getPath())->toBeSame('/path/123');
    expect($uri->getQuery())->toBeSame('q=abc');
    expect($uri->getFragment())->toBeSame('test');
    expect($uri->toString())->toBeSame(
      'https://user:pass@example.com:8080/path/123?q=abc#test',
    );
  }

  public function testCanTransformAndRetrievePartsIndividually(): void {
    $uri = (new Message\Uri())
      ->withScheme('https')
      ->withUserInfo('user', 'pass')
      ->withHost('example.com')
      ->withPort(8080)
      ->withPath('/path/123')
      ->withQuery('q=abc')
      ->withFragment('test');
    expect($uri->getScheme())->toBeSame('https');
    expect($uri->getAuthority())->toBeSame('user:pass@example.com:8080');
    expect($uri->getUserInfo())->toBeSame(tuple('user', 'pass'));
    expect($uri->getHost())->toBeSame('example.com');
    expect($uri->getPort())->toBeSame(8080);
    expect($uri->getPath())->toBeSame('/path/123');
    expect($uri->getQuery())->toBeSame('q=abc');
    expect($uri->getFragment())->toBeSame('test');
    expect($uri->toString())->toBeSame(
      'https://user:pass@example.com:8080/path/123?q=abc#test',
    );
  }

  <<DataProvider('getValidUris')>>
  public function testValidUrisStayValid(string $input): void {
    $uri = new Message\Uri($input);
    expect($uri->toString())->toBeSame($input);
  }

  public function getValidUris(): Container<(string)> {
    return vec[
      tuple('urn:path-rootless'),
      tuple('urn:path:with:colon'),
      tuple('urn:/path-absolute'),
      tuple('urn:/'),
      // only scheme with empty path
      tuple('urn:'),
      // only path
      tuple('/'),
      tuple('relative/'),
      tuple('0'),
      // same document reference
      tuple(''),
      // network path without scheme
      tuple('//example.org'),
      tuple('//example.org/'),
      tuple('//example.org?q#h'),
      // only query
      tuple('?q'),
      tuple('?q=abc&foo=bar'),
      // only fragment
      tuple('#fragment'),
      // dot segments are not removed automatically
      tuple('./foo/../bar'),
    ];
  }

  <<DataProvider('getInvalidUris')>>
  public function testInvalidUrisThrowException(string $invalidUri): void {
    expect(() ==> {
      new Message\Uri($invalidUri);
    })->toThrow(
      Message\Exception\InvalidArgumentException::class,
      'Unable to parse URI',
    );
  }

  public function getInvalidUris(): Container<(string)> {
    return vec[
      // parse_url() requires the host component which makes sense for http(s)
      // but not when the scheme is not known or different. So '//' or '///' is
      // currently invalid as well but should not according to RFC 3986.
      tuple('http://'),
      tuple('urn://host:with:colon'), // host cannot contain ":"
    ];
  }

  public function testPortMustBeValid(): void {
    expect(() ==> {
      (new Message\Uri())->withPort(100000);
    })->toThrow(
      Message\Exception\InvalidArgumentException::class,
      'Invalid port: 100000. Must be between 1 and 65535',
    );
  }

  public function testWithPortCannotBeZero(): void {
    expect(() ==> {
      (new Message\Uri())->withPort(0);
    })->toThrow(
      Message\Exception\InvalidArgumentException::class,
      'Invalid port: 0. Must be between 1 and 65535',
    );
  }

  public function testParseUriPortCannotBeZero(): void {
    expect(() ==> {
      new Message\Uri('//example.com:0');
    })->toThrow(
      Message\Exception\InvalidArgumentException::class,
      'Unable to parse URI',
    );
  }

  public function testCanParseFalseyUriParts(): void {
    $uri = new Message\Uri('0://0:0@0/0?0#0');
    expect($uri->getScheme())->toBeSame('0');
    expect($uri->getAuthority())->toBeSame('0:0@0');
    expect($uri->getUserInfo())->toBeSame(tuple('0', '0'));
    expect($uri->getHost())->toBeSame('0');
    expect($uri->getPath())->toBeSame('/0');
    expect($uri->getQuery())->toBeSame('0');
    expect($uri->getFragment())->toBeSame('0');
    expect($uri->toString())->toBeSame('0://0:0@0/0?0#0');
  }

  public function testCanConstructFalseyUriParts(): void {
    $uri = (new Message\Uri())
      ->withScheme('0')
      ->withUserInfo('0', '0')
      ->withHost('0')
      ->withPath('/0')
      ->withQuery('0')
      ->withFragment('0');
    expect($uri->getScheme())->toBeSame('0');
    expect($uri->getAuthority())->toBeSame('0:0@0');
    expect($uri->getUserInfo())->toBeSame(tuple('0', '0'));
    expect($uri->getHost())->toBeSame('0');
    expect($uri->getPath())->toBeSame('/0');
    expect($uri->getQuery())->toBeSame('0');
    expect($uri->getFragment())->toBeSame('0');
    expect($uri->toString())->toBeSame('0://0:0@0/0?0#0');
  }

  public function getResolveTestCases(): Container<(string, string, string)> {
    return vec[
      tuple(self::RFC3986_BASE, 'g:h', 'g:h'),
      tuple(self::RFC3986_BASE, 'g', 'http://a/b/c/g'),
      tuple(self::RFC3986_BASE, './g', 'http://a/b/c/g'),
      tuple(self::RFC3986_BASE, 'g/', 'http://a/b/c/g/'),
      tuple(self::RFC3986_BASE, '/g', 'http://a/g'),
      tuple(self::RFC3986_BASE, '//g', 'http://g'),
      tuple(self::RFC3986_BASE, '?y', 'http://a/b/c/d;p?y'),
      tuple(self::RFC3986_BASE, 'g?y', 'http://a/b/c/g?y'),
      tuple(self::RFC3986_BASE, '#s', 'http://a/b/c/d;p?q#s'),
      tuple(self::RFC3986_BASE, 'g#s', 'http://a/b/c/g#s'),
      tuple(self::RFC3986_BASE, 'g?y#s', 'http://a/b/c/g?y#s'),
      tuple(self::RFC3986_BASE, ';x', 'http://a/b/c/;x'),
      tuple(self::RFC3986_BASE, 'g;x', 'http://a/b/c/g;x'),
      tuple(self::RFC3986_BASE, 'g;x?y#s', 'http://a/b/c/g;x?y#s'),
      tuple(self::RFC3986_BASE, '', self::RFC3986_BASE),
      tuple(self::RFC3986_BASE, '.', 'http://a/b/c/'),
      tuple(self::RFC3986_BASE, './', 'http://a/b/c/'),
      tuple(self::RFC3986_BASE, '..', 'http://a/b/'),
      tuple(self::RFC3986_BASE, '../', 'http://a/b/'),
      tuple(self::RFC3986_BASE, '../g', 'http://a/b/g'),
      tuple(self::RFC3986_BASE, '../..', 'http://a/'),
      tuple(self::RFC3986_BASE, '../../', 'http://a/'),
      tuple(self::RFC3986_BASE, '../../g', 'http://a/g'),
      tuple(self::RFC3986_BASE, '../../../g', 'http://a/g'),
      tuple(self::RFC3986_BASE, '../../../../g', 'http://a/g'),
      tuple(self::RFC3986_BASE, '/./g', 'http://a/g'),
      tuple(self::RFC3986_BASE, '/../g', 'http://a/g'),
      tuple(self::RFC3986_BASE, 'g.', 'http://a/b/c/g.'),
      tuple(self::RFC3986_BASE, '.g', 'http://a/b/c/.g'),
      tuple(self::RFC3986_BASE, 'g..', 'http://a/b/c/g..'),
      tuple(self::RFC3986_BASE, '..g', 'http://a/b/c/..g'),
      tuple(self::RFC3986_BASE, './../g', 'http://a/b/g'),
      tuple(self::RFC3986_BASE, 'foo////g', 'http://a/b/c/foo////g'),
      tuple(self::RFC3986_BASE, './g/.', 'http://a/b/c/g/'),
      tuple(self::RFC3986_BASE, 'g/./h', 'http://a/b/c/g/h'),
      tuple(self::RFC3986_BASE, 'g/../h', 'http://a/b/c/h'),
      tuple(self::RFC3986_BASE, 'g;x=1/./y', 'http://a/b/c/g;x=1/y'),
      tuple(self::RFC3986_BASE, 'g;x=1/../y', 'http://a/b/c/y'),
      // dot-segments in the query or fragment
      tuple(self::RFC3986_BASE, 'g?y/./x', 'http://a/b/c/g?y/./x'),
      tuple(self::RFC3986_BASE, 'g?y/../x', 'http://a/b/c/g?y/../x'),
      tuple(self::RFC3986_BASE, 'g#s/./x', 'http://a/b/c/g#s/./x'),
      tuple(self::RFC3986_BASE, 'g#s/../x', 'http://a/b/c/g#s/../x'),
      tuple(self::RFC3986_BASE, 'g#s/../x', 'http://a/b/c/g#s/../x'),
      tuple(self::RFC3986_BASE, '?y#s', 'http://a/b/c/d;p?y#s'),
      tuple('http://a/b/c/d;p?q#s', '?y', 'http://a/b/c/d;p?y'),
      tuple('http://u@a/b/c/d;p?q', '.', 'http://u@a/b/c/'),
      tuple('http://u:p@a/b/c/d;p?q', '.', 'http://u:p@a/b/c/'),
      tuple('http://a/b/c/d/', 'e', 'http://a/b/c/d/e'),
      tuple('urn:no-slash', 'e', 'urn:e'),
      // falsey relative parts
      tuple(self::RFC3986_BASE, '//0', 'http://0'),
      tuple(self::RFC3986_BASE, '0', 'http://a/b/c/0'),
      tuple(self::RFC3986_BASE, '?0', 'http://a/b/c/d;p?0'),
      tuple(self::RFC3986_BASE, '#0', 'http://a/b/c/d;p?q#0'),
    ];
  }

  public function testSchemeIsNormalizedToLowercase(): void {
    $uri = new Message\Uri('HTTP://example.com');
    expect($uri->getScheme())->toBeSame('http');
    expect($uri->toString())->toBeSame('http://example.com');
    $uri = (new Message\Uri('//example.com'))->withScheme('HTTP');
    expect($uri->getScheme())->toBeSame('http');
    expect($uri->toString())->toBeSame('http://example.com');
  }

  public function testHostIsNormalizedToLowercase(): void {
    $uri = new Message\Uri('//eXaMpLe.CoM');
    expect($uri->getHost())->toBeSame('example.com');
    expect($uri->toString())->toBeSame('//example.com');
    $uri = (new Message\Uri())->withHost('eXaMpLe.CoM');
    expect($uri->getHost())->toBeSame('example.com');
    expect($uri->toString())->toBeSame('//example.com');
  }

  public function testPortIsNullIfStandardPortForScheme(): void {
    // HTTPS standard port
    $uri = new Message\Uri('https://example.com:443');
    expect($uri->getPort())->toBeNull();
    expect($uri->getAuthority())->toBeSame('example.com');
    $uri = (new Message\Uri('https://example.com'))->withPort(443);
    expect($uri->getPort())->toBeNull();
    expect($uri->getAuthority())->toBeSame('example.com');
    // HTTP standard port
    $uri = new Message\Uri('http://example.com:80');
    expect($uri->getPort())->toBeNull();
    expect($uri->getAuthority())->toBeSame('example.com');
    $uri = (new Message\Uri('http://example.com'))->withPort(80);
    expect($uri->getPort())->toBeNull();
    expect($uri->getAuthority())->toBeSame('example.com');
  }

  public function testPortIsReturnedIfSchemeUnknown(): void {
    $uri = (new Message\Uri('//example.com'))->withPort(80);
    expect($uri->getPort())->toBeSame(80);
    expect($uri->getAuthority())->toBeSame('example.com:80');
  }

  public function testStandardPortIsNullIfSchemeChanges(): void {
    $uri = new Message\Uri('http://example.com:443');
    expect($uri->getScheme())->toBeSame('http');
    expect($uri->getPort())->toBeSame(443);
    $uri = $uri->withScheme('https');
    expect($uri->getPort())->toBeNull();
  }

  public function testPortCanBeRemoved(): void {
    $uri = (new Message\Uri('http://example.com:8080'))->withPort(null);
    expect($uri->getPort())->toBeNull();
    expect($uri->toString())->toBeSame('http://example.com');
  }

  public function testAuthorityWithUserInfoButWithoutHost(): void {
    $uri = (new Message\Uri())->withUserInfo('user', 'pass');
    expect($uri->getUserInfo())->toBeSame(tuple('user', 'pass'));
    expect($uri->getAuthority())->toBeSame('');
  }

  public function uriComponentsEncodingProvider(
  ): Container<(string, string, string, string, string)> {
    $unreserved = 'a-zA-Z0-9.-_~!$&\'()*+,;=:@';
    return vec[
      // Percent encode spaces
      tuple(
        '/pa th?q=va lue#frag ment',
        '/pa%20th',
        'q=va%20lue',
        'frag%20ment',
        '/pa%20th?q=va%20lue#frag%20ment',
      ),
      // Percent encode multibyte
      tuple(
        '/€?€#€',
        '/%E2%82%AC',
        '%E2%82%AC',
        '%E2%82%AC',
        '/%E2%82%AC?%E2%82%AC#%E2%82%AC',
      ),
      // Don't encode something that's already encoded
      tuple(
        '/pa%20th?q=va%20lue#frag%20ment',
        '/pa%20th',
        'q=va%20lue',
        'frag%20ment',
        '/pa%20th?q=va%20lue#frag%20ment',
      ),
      // Percent encode invalid percent encodings
      tuple(
        '/pa%2-th?q=va%2-lue#frag%2-ment',
        '/pa%252-th',
        'q=va%252-lue',
        'frag%252-ment',
        '/pa%252-th?q=va%252-lue#frag%252-ment',
      ),
      // Don't encode path segments
      tuple(
        '/pa/th//two?q=va/lue#frag/ment',
        '/pa/th//two',
        'q=va/lue',
        'frag/ment',
        '/pa/th//two?q=va/lue#frag/ment',
      ),
      // Don't encode unreserved chars or sub-delimiters
      tuple(
        "/$unreserved?$unreserved#$unreserved",
        "/$unreserved",
        $unreserved,
        $unreserved,
        "/$unreserved?$unreserved#$unreserved",
      ),
      // Encoded unreserved chars are not decoded
      tuple(
        '/p%61th?q=v%61lue#fr%61gment',
        '/p%61th',
        'q=v%61lue',
        'fr%61gment',
        '/p%61th?q=v%61lue#fr%61gment',
      ),
    ];
  }

  <<DataProvider('uriComponentsEncodingProvider')>>
  public function testUriComponentsGetEncodedProperly(
    string $input,
    string $path,
    string $query,
    string $fragment,
    string $output,
  ): void {
    $uri = new Message\Uri($input);
    expect($uri->getPath())->toBeSame($path);
    expect($uri->getQuery())->toBeSame($query);
    expect($uri->getFragment())->toBeSame($fragment);
    expect($uri->toString())->toBeSame($output);
  }

  public function testWithPathEncodesProperly(): void {
    $uri = (new Message\Uri())->withPath('/baz?#€/b%61r');
    // Query and fragment delimiters and multibyte chars are encoded.
    expect($uri->getPath())->toBeSame('/baz%3F%23%E2%82%AC/b%61r');
    expect($uri->toString())->toBeSame('/baz%3F%23%E2%82%AC/b%61r');
  }

  public function testWithQueryEncodesProperly(): void {
    $uri = (new Message\Uri())->withQuery('?=#&€=/&b%61r');
    // A query starting with a "?" is valid and must not be magically removed. Otherwise it would be impossible to
    // construct such an URI. Also the "?" and "/" does not need to be encoded in the query.
    expect($uri->getQuery())->toBeSame('?=%23&%E2%82%AC=/&b%61r');
    expect($uri->toString())->toBeSame('??=%23&%E2%82%AC=/&b%61r');
  }

  public function testWithFragmentEncodesProperly(): void {
    $uri = (new Message\Uri())->withFragment('#€?/b%61r');
    // A fragment starting with a "#" is valid and must not be magically removed. Otherwise it would be impossible to
    // construct such an URI. Also the "?" and "/" does not need to be encoded in the fragment.
    expect($uri->getFragment())->toBeSame('%23%E2%82%AC?/b%61r');
    expect($uri->toString())->toBeSame('#%23%E2%82%AC?/b%61r');
  }

  public function testAllowsForRelativeUri(): void {
    $uri = (new Message\Uri())->withPath('foo');
    expect($uri->getPath())->toBeSame('foo');
    expect($uri->toString())->toBeSame('foo');
  }

  public function testAddsSlashForRelativeUriStringWithHost(): void {
    // If the path is rootless and an authority is present, the path MUST
    // be prefixed by "/".
    $uri = (new Message\Uri())->withPath('foo')->withHost('example.com');
    expect($uri->getPath())->toBeSame('foo');
    // concatenating a relative path with a host doesn't work: "//example.comfoo" would be wrong
    expect($uri->toString())->toBeSame('//example.com/foo');
  }

  public function testRemoveExtraSlashesWihoutHost(): void {
    // If the path is starting with more than one "/" and no authority is
    // present, the starting slashes MUST be reduced to one.
    $uri = (new Message\Uri())->withPath('//foo');
    expect($uri->getPath())->toBeSame('//foo');
    // URI "//foo" would be interpreted as network reference and thus change the original path to the host
    expect($uri->toString())->toBeSame('/foo');
  }

  public function testDefaultReturnValuesOfGetters(): void {
    $uri = new Message\Uri();
    expect($uri->getScheme())->toBeSame('');
    expect($uri->getAuthority())->toBeSame('');
    expect($uri->getUserInfo())->toBeSame(tuple('', null));
    expect($uri->getHost())->toBeSame('');
    expect($uri->getPort())->toBeNull();
    expect($uri->getPath())->toBeSame('');
    expect($uri->getQuery())->toBeSame('');
    expect($uri->getFragment())->toBeSame('');
  }

  public function testImmutability(): void {
    $uri = new Message\Uri();
    expect($uri->withScheme('https'))->toNotBeSame($uri);
    expect($uri->withUserInfo('user', 'pass'))->toNotBeSame($uri);
    expect($uri->withHost('example.com'))->toNotBeSame($uri);
    expect($uri->withPort(8080))->toNotBeSame($uri);
    expect($uri->withPath('/path/123'))->toNotBeSame($uri);
    expect($uri->withQuery('q=abc'))->toNotBeSame($uri);
    expect($uri->withFragment('test'))->toNotBeSame($uri);
  }
}
