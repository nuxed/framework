## Nuxed
##### Hack framework for building web applications with expressive, elegant syntax.

*DO NOT USE; Nuxed is under heavy active development*

---
[![Build Status](https://travis-ci.org/nuxed/framework.svg?branch=master)](https://travis-ci.org/nuxed/framework)

---
#### Sample

A simple example using `Nuxed\Http\Kernel\Kernel`, the heart of the `Nuxed\Http` package.

`main.hack` :
```hack
<?hh // strict

use namespace Nuxed\Http;
use type Nuxed\Contract\Http\Message\ServerRequestInterface as Request;
use type Nuxed\Contract\Http\Message\ResponseInterface as Response;

require __DIR__ . '/path/to/vendor/hh_autoload.hh';

<<__EntryPoint>>
async function main(): Awaitable<void> {
  /**
   * Create an Http kernel instance.
   */
  $kernel = new Http\Kernel\Kernel();

  /**
   * Add a simple route
   */
  $kernel->get(
    '/',
    (Request $request): Response ==> {
      return new Http\Message\Response\JsonResponse(dict[
        'message' => 'Hello, World!',
      ])
        |> $$->withAddedHeader('X-Powered-By', vec['Nuxed@master']);
    },
  );

  /**
   * Create a server request instance from the global
   * variables ( $_SERVER, $_POST, $_GET ... etc)
   */
  $request = Http\Message\ServerRequest::capture();

  /**
   * Handle the request and return a response instance
   */
  $response = $kernel->handle($request);

  /**
   * Send the response to the client.
   */
  $kernel->emit($response);

  /**
   * Perform any final actions for the request lifecycle.
   */
  $kernel->terminate($request, $response);
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
➜  public git:(master) ✗ hhvm -m daemon -c server.ini
```

---
#### Security Vulnerabilities
If you discover a security vulnerability within Nuxed, please send an e-mail to Saif Eddin Gmati via azjezz@protonmail.com.

---
#### License
The Nuxed framework is open-sourced software licensed under the MIT-licensed.