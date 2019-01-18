<?hh // strict

namespace Nuxed\Contract\Event;

type EventListener = (function(EventInterface): void);
