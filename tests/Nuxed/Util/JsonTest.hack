namespace Nuxed\Test\Util;

use namespace Facebook\TypeAssert;
use namespace Facebook\TypeSpec;
use namespace Nuxed\Util\Exception;
use type Facebook\HackTest\HackTest;
use type Facebook\HackTest\DataProvider;
use namespace Nuxed\Util\Json;
use function Facebook\FBExpect\expect;

class JsonTest extends HackTest {
  const type TStructOne = dict<string, int>;
  const type TStructTwo = shape(
    'foo' => string,
    'bar' => vec<this::TStructOne>,
    ...
  );

  public function testEncode(): void {
    expect(Json\encode(vec['a']))->toBeSame('["a"]');
  }

  public function testPrettyEncode(): void {
    expect(Json\encode(
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
    expect(Json\decode(
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
    $decoded = Json\decode('{
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
      Json\encode(vec["bad utf\xFF"]);
    })->toThrow(
      Json\Exception\JsonEncodeException::class,
      'Malformed UTF-8 characters, possibly incorrectly encoded',
    );
  }

  public function testEncodeThrowsWithNAN(): void {
    expect(() ==> {
      Json\encode(\NAN);
    })->toThrow(
      Json\Exception\JsonEncodeException::class,
      'Inf and NaN cannot be JSON encoded',
    );
  }

  public function testEncodeThrowsWithInf(): void {
    expect(() ==> {
      Json\encode(\INF);
    })->toThrow(
      Json\Exception\JsonEncodeException::class,
      'Inf and NaN cannot be JSON encoded',
    );
  }

  public function testEncodePreserveZeroFraction(): void {
    expect(Json\encode(1.0))->toBeSame('1.0');
  }

  public function testJsonUnescapedUnicodeAndUnescapedSlashes(): void {
    expect(
      Json\encode("/I\u{F1}t\u{EB}rn\u{E2}ti\u{F4}n\u{E0}liz\u{E6}ti\u{F8}n"),
    )
      ->toBeSame(
        "\"/I\u{F1}t\u{EB}rn\u{E2}ti\u{F4}n\u{E0}liz\u{E6}ti\u{F8}n\"",
      );

    expect(Json\encode("\u{2028}\u{2029}"))->toBeSame("\"\u{2028}\u{2029}\"");
  }

  public function testDecodeThrowsWithInvalidSyntax(): void {
    expect(() ==> {
      Json\decode('{"a" => 4}');
    })->toThrow(Json\Exception\JsonDecodeException::class, 'Syntax error');
    expect(() ==> {
      Json\decode('{');
    })->toThrow(Json\Exception\JsonDecodeException::class, 'Syntax error');
    expect(() ==> {
      Json\decode('{"a": 4}}');
    })->toThrow(
      Json\Exception\JsonDecodeException::class,
      'invalid or malformed JSON',
    );
  }

  public function testDecodeNull(): void {
    expect(Json\decode('null'))->toBeNull();
    expect(Json\decode('     null  '))->toBeNull();
  }

  public function testDecodeInvalidPropertyNameWithObject(): void {
    expect(() ==> {
      Json\decode('{"\u0000": 1}', false);
    })->toThrow(
      Json\Exception\JsonDecodeException::class,
      'Cannot access property',
    );
  }

  public function testDecodeMalformedUtf8(): void {
    expect(() ==> {
      Json\decode("\"\xC1\xBF\"");
    })->toThrow(
      Json\Exception\JsonDecodeException::class,
      'Malformed UTF-8 characters, possibly incorrectly encoded',
    );
  }

  public function testStructure(): void {
    $json = Json\encode(dict['foo' => 32, 'bar' => 3, 'c' => 5]);

    expect(Json\structure($json, type_structure($this, 'TStructOne')))
      ->toBeSame(dict['foo' => 32, 'bar' => 3, 'c' => 5]);

    expect(() ==> Json\structure($json, type_structure($this, 'TStructTwo')))
      ->toThrow(Json\Exception\JsonDecodeException::class);

    $json = Json\encode(dict[
      'foo' => 'hello',
      'bar' => vec[
        dict['foo' => 32, 'bar' => 3, 'c' => 5],
      ],
    ]);

    expect(Json\structure($json, type_structure($this, 'TStructTwo')))
      ->toBeSame(shape(
        'foo' => 'hello',
        'bar' => vec[
          dict['foo' => 32, 'bar' => 3, 'c' => 5],
        ],
      ));
  }
}
