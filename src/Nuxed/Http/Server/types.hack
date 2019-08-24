namespace Nuxed\Http\Server;

use namespace Nuxed\Http\Message;

type CallableMiddleware = (function(
  Message\ServerRequest,
  IHandler,
): Awaitable<Message\Response>);

type CallableHandler = (function(
  Message\ServerRequest,
): Awaitable<Message\Response>);

type FunctionalMiddleware = (function(
  Message\ServerRequest,
  CallableHandler,
): Awaitable<Message\Response>);

type DoublePassMiddleware = (function(
  Message\ServerRequest,
  Message\Response,
  IHandler,
): Awaitable<Message\Response>);

type DoublePassFunctionalMiddleware = (function(
  Message\ServerRequest,
  Message\Response,
  CallableHandler,
): Awaitable<Message\Response>);

type DoublePassHandler = (function(
  Message\ServerRequest,
  Message\Response,
): Awaitable<Message\Response>);

type LazyMiddleware = (function(): IMiddleware);

type LazyHandler = (function(): IHandler);
