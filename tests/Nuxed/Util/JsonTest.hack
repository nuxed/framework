namespace Nuxed\Test\Util;

use namespace Facebook\TypeAssert;
use namespace Facebook\TypeSpec;
use namespace Nuxed\Util\Exception;
use type Facebook\HackTest\HackTest;
use type Facebook\HackTest\DataProvider;
use type Nuxed\Util\Json;
use function Facebook\FBExpect\expect;

class JsonTest extends HackTest {
  public function testEncode(): void {
    expect(Json::encode(vec['a']))->toBeSame('["a"]');
  }

  public function testPrettyEncode(): void {
    expect(Json::encode(
      dict[
        "name" => "nuxed/framework",
        "type" => "framework",
        "description" =>
          "Hack framework for building web applications with expressive, elegant syntax.",
        "keywords" => vec[
          "hack",
          "hhvm",
          "framework",
          "nuxed",
        ],
        "license" => "MIT",
      ],
      true,
    ))->toBeSame('{
    "name": "nuxed/framework",
    "type": "framework",
    "description": "Hack framework for building web applications with expressive, elegant syntax.",
    "keywords": [
        "hack",
        "hhvm",
        "framework",
        "nuxed"
    ],
    "license": "MIT"
}');
  }

  public function testDecode(): void {
    expect(Json::decode(
      '{
    "name": "nuxed/framework",
    "type": "framework",
    "description": "Hack framework for building web applications with expressive, elegant syntax.",
    "keywords": [
        "hack",
        "hhvm",
        "framework",
        "nuxed"
    ],
    "license": "MIT"
}',
    ))->toBeSame(dict[
      "name" => "nuxed/framework",
      "type" => "framework",
      "description" =>
        "Hack framework for building web applications with expressive, elegant syntax.",
      "keywords" => vec[
        "hack",
        "hhvm",
        "framework",
        "nuxed",
      ],
      "license" => "MIT",
    ]);
  }

  public function testDecodeUsingHackArrays(): void {
    $decoded = Json::decode('{
  "a": "b",
  "b": {
    "a": "b"
  },
  "c": ["a", "b", "c"]
}');
    $decodedSpec = TypeSpec\dict(TypeSpec\string(), TypeSpec\mixed());
    $decoded = $decodedSpec->assertType($decoded);
    $bSpec = TypeSpec\dict(TypeSpec\string(), TypeSpec\string());
    $b = $bSpec->assertType($decoded['b']);
    $cSpec = TypeSpec\vec(TypeSpec\string());
    $c = $cSpec->assertType($decoded['c']);
  }

  public function testEncodeThrowsWithMalformedUtf8(): void {
    expect(() ==> {
      Json::encode(["bad utf\xFF"]);
    })->toThrow(
      Exception\JsonEncodeException::class,
      'Malformed UTF-8 characters, possibly incorrectly encoded',
    );
  }

  public function testEncodeThrowsWithNAN(): void {
    expect(() ==> {
      Json::encode(\NAN);
    })->toThrow(
      Exception\JsonEncodeException::class,
      'Inf and NaN cannot be JSON encoded',
    );
  }

  public function testEncodeThrowsWithInf(): void {
    expect(() ==> {
      Json::encode(\INF);
    })->toThrow(
      Exception\JsonEncodeException::class,
      'Inf and NaN cannot be JSON encoded',
    );
  }

  public function testEncodePreserveZeroFraction(): void {
    expect(Json::encode(1.0))->toBeSame('1.0');
  }

  public function testJsonUnescapedUnicodeAndUnescapedSlashes(): void {
    expect(
      Json::encode("/I\u{F1}t\u{EB}rn\u{E2}ti\u{F4}n\u{E0}liz\u{E6}ti\u{F8}n"),
    )
      ->toBeSame(
        "\"/I\u{F1}t\u{EB}rn\u{E2}ti\u{F4}n\u{E0}liz\u{E6}ti\u{F8}n\"",
      );
    // Known issue.
    // expect(Json::encode("\u{2028}\u{2029}"))->toBeSame('"\u2028\u2029"');
  }

  public function testDecodeThrowsWithInvalidSyntax(): void {
    expect(() ==> {
      Json::decode('{"a" => 4}');
    })->toThrow(Exception\JsonDecodeException::class, 'Syntax error');
    expect(() ==> {
      Json::decode('{');
    })->toThrow(Exception\JsonDecodeException::class, 'Syntax error');
    expect(() ==> {
      Json::decode('{"a": 4}}');
    })->toThrow(
      Exception\JsonDecodeException::class,
      'invalid or malformed JSON',
    );
  }

  public function testDecodeNull(): void {
    expect(Json::decode('null'))->toBeNull();
    expect(Json::decode('     null  '))->toBeNull();
  }

  public function testDecodeInvalidPropertyNameWithObject(): void {
    expect(() ==> {
      Json::decode('{"\u0000": 1}', false);
    })->toThrow(Exception\JsonDecodeException::class, 'Cannot access property');
  }

  public function testDecodeMalformedUtf8(): void {
    expect(() ==> {
      Json::decode("\"\xC1\xBF\"");
    })->toThrow(
      Exception\JsonDecodeException::class,
      'Malformed UTF-8 characters, possibly incorrectly encoded',
    );
  }
}
