namespace Nuxed\Log;

use type Nuxed\Log\LogLevel;
use type DateTime;

type LogRecord = shape(
  'level' => LogLevel,
  'message' => string,
  'context' => dict<string, mixed>,
  'time' => DateTime,
  'extra' => dict<string, mixed>,
  ?'formatted' => string,
  ...
);
