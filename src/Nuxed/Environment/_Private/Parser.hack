namespace Nuxed\Environment\_Private;

use namespace HH\Lib\{C, Regex, Str, Vec};
use namespace Nuxed\Environment\Exception;

final abstract class Parser {
  /**
   * Parse the given environment variable entry into a name and value.
   */
  public static function parse(string $entry): (string, ?string) {
    $name = $entry;
    $value = null;
    if (Str\contains($entry, '=')) {
      list($name, $value) = Vec\map(
        Str\split($entry, '=', 2),
        ($str) ==> Str\trim($str),
      );
    }

    return tuple(self::parseName($name), self::parseValue($value));
  }

  public static function parseName(string $name): string {
    if ($name === '') {
      throw new Exception\InvalidArgumentException(
        'Failed to parse environment variable name : name cannot be empty.',
      );
    }

    $name = Str\trim(
      Str\replace_every($name, dict['export ' => '', '\'' => '', '"' => '']),
    );
    if (!Regex\matches($name, re"~\A[a-zA-Z0-9_.]+\z~")) {
      throw new Exception\InvalidArgumentException(
        Str\format(
          'Failed to parse environment variable name : an invalid name ( %s ).',
          $name,
        ),
      );
    }

    return $name;
  }

  /**
   * Strips quotes and comments from the environment variable value.
   */
  public static function parseValue(?string $value): ?string {
    if ($value === null || Str\trim($value) === '') {
      return $value;
    }

    return C\reduce(
      Str\chunk($value),
      ((string, State) $data, string $char): (string, State) ==> {
        switch ($data[1]) {
          case State::INITIAL:
            if ($char === '"' || $char === '\'') {
              return tuple($data[0], State::QUOTED);
            } else if ($char === '#') {
              return tuple($data[0], State::COMMENT);
            } else {
              return tuple($data[0].$char, State::UNQUOTED);
            }
          case State::UNQUOTED:
            if ($char === '#') {
              return tuple($data[0], State::COMMENT);
            } else if (\ctype_space($char)) {
              return tuple($data[0], State::WHITESPACE);
            }

            return tuple($data[0].$char, State::UNQUOTED);
          case State::QUOTED:
            if ($char === $value[0]) {
              return tuple($data[0], State::WHITESPACE);
            } else if ($char === '\\') {
              return tuple($data[0], State::ESCAPE);
            }

            return tuple($data[0].$char, State::QUOTED);
          case State::ESCAPE:
            if ($char === $value[0] || $char === '\\') {
              return tuple($data[0].$char, State::QUOTED);
            }

            throw new Exception\InvalidArgumentException(
              Str\format(
                'Failed to parse environment entry : an unexpected escape sequence ( %s ).',
                $value,
              ),
            );
          case State::WHITESPACE:
            if ($char === '#') {
              return tuple($data[0], State::COMMENT);
            } else if (!\ctype_space($char)) {
              throw new Exception\InvalidArgumentException(
                Str\format(
                  'Failed to parse environment entry : unexpected whitespace ( %s ).',
                  $value,
                ),
              );
            }

            return tuple($data[0], State::WHITESPACE);
          case State::COMMENT:
            return tuple($data[0], State::COMMENT);
        }
      },
      tuple('', State::INITIAL),
    )[0];
  }
}
