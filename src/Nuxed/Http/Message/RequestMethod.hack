namespace Nuxed\Http\Message;

/**
 * Defines constants for common HTTP request methods.
 */
final abstract class RequestMethod {
  const string METHOD_HEAD = 'HEAD';
  const string METHOD_GET = 'GET';
  const string METHOD_POST = 'POST';
  const string METHOD_PUT = 'PUT';
  const string METHOD_PATCH = 'PATCH';
  const string METHOD_DELETE = 'DELETE';
  const string METHOD_PURGE = 'PURGE';
  const string METHOD_OPTIONS = 'OPTIONS';
  const string METHOD_TRACE = 'TRACE';
  const string METHOD_CONNECT = 'CONNECT';
  const string METHOD_REPORT = 'REPORT';
  const string METHOD_LOCK = 'LOCK';
  const string METHOD_UNLOCK = 'UNLOCK';
  const string METHOD_COPY = 'COPY';
  const string METHOD_MOVE = 'MOVE';
  const string METHOD_MERGE = 'MERGE';
  const string METHOD_NOTIFY = 'NOTIFY';
  const string METHOD_SUBSCRIBE = 'SUBSCRIBE';
  const string METHOD_UNSUBSCRIBE = 'UNSUBSCRIBE';
}
