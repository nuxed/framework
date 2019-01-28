
# Nuxed

## Hack framework for building web applications with expressive, elegant syntax

> *DO NOT USE; Nuxed is under heavy active development*

---
[![Build Status](https://travis-ci.org/nuxed/framework.svg?branch=master)](https://travis-ci.org/nuxed/framework) [![Join the chat at https://gitter.im/Nuxed/framework](https://badges.gitter.im/Nuxed/framework.svg)](https://gitter.im/Nuxed/framework?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

---

### Usage Example

A simple example using `Nuxed\Kernel\Kernel`, the heart of the `Nuxed` framework.

`main.hack` :

```hack
<?hh // strict

use namespace Nuxed\Kernel;
use namespace Nuxed\Http\Message;
use type Nuxed\Contract\Http\Message\ServerRequestInterface as Request;
use type Nuxed\Contract\Http\Message\ResponseInterface as Response;

require __DIR__.'/../../vendor/hh_autoload.hh';

<<__EntryPoint>>
async function main(): Awaitable<noreturn> {
  /**
   * Create the container and kernel instances.
   *
   * you can use the container instance to register
   * services.
   */
  list($container, $kernel) = Kernel\Kernel::create();
  
  /**
   * Add a simple route
   */
  $kernel->get(
    '/',
    (Request $request): Response ==>
      new Message\Response\JsonResponse(dict[
        'message' => 'Hello, World'
      ])
  );

  /**
   * run the kernel application.
   */
  return await $kernel->run();
}
```

`server.ini`

```ini
hhvm.force_hh=true
hhvm.server.port = 8080
hhvm.server.type = "proxygen"
hhvm.server.default_document = "main.hack"
hhvm.server.error_document404 = "main.hack"
hhvm.server.utf8ize_replace = true
```

Run the application :

```console
➜ hhvm -m daemon -c /etc/hhvm/server.ini -d hhvm.log.file=log.txt
```

---

### Security Vulnerabilities

If you discover a security vulnerability within Nuxed, please send an e-mail to Saif Eddin Gmati via azjezz@protonmail.com.

---

### License

The Nuxed framework is open-sourced software licensed under the MIT-licensed.
