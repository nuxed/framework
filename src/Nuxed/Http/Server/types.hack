namespace Nuxed\Http\Server;

use namespace Nuxed\Http\Message;

type CallableMiddleware = (function(
  Message\ServerRequest,
  IRequestHandler,
): Awaitable<Message\Response>);

type CallableRequestHandler = (function(
  Message\ServerRequest,
): Awaitable<Message\Response>);

type FunctionalMiddleware = (function(
  Message\ServerRequest,
  CallableRequestHandler,
): Awaitable<Message\Response>);

type DoublePassMiddleware = (function(
  Message\ServerRequest,
  Message\Response,
  IRequestHandler,
): Awaitable<Message\Response>);

type DoublePassFunctionalMiddleware = (function(
  Message\ServerRequest,
  Message\Response,
  CallableRequestHandler,
): Awaitable<Message\Response>);

type DoublePassRequestHandler = (function(
  Message\ServerRequest,
  Message\Response,
): Awaitable<Message\Response>);

type LazyMiddleware = (function(): IMiddleware);

type LazyRequestHandler = (function(): IRequestHandler);
