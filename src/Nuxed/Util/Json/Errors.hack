namespace Nuxed\Util\Json;

const dict<int, string> Errors = dict[
  \JSON_ERROR_NONE => 'No error',
  \JSON_ERROR_DEPTH => 'Maximum stack depth exceeded',
  \JSON_ERROR_STATE_MISMATCH => 'State mismatch (invalid or malformed JSON)',
  \JSON_ERROR_CTRL_CHAR =>
    'Control character error, possibly incorrectly encoded',
  \JSON_ERROR_SYNTAX => 'Syntax error',
  \JSON_ERROR_UTF8 =>
    'Malformed UTF-8 characters, possibly incorrectly encoded',
  \JSON_ERROR_INF_OR_NAN => 'Inf and NaN cannot be JSON encoded',
  \JSON_ERROR_UNSUPPORTED_TYPE =>
    'A value of a type that cannot be encoded was given',
];