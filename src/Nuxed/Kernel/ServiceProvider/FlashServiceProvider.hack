namespace Nuxed\Kernel\ServiceProvider;

use namespace Nuxed\Http;

class FlashServiceProvider extends AbstractServiceProvider {
  protected vec<string> $provides = vec[
    Http\Flash\FlashMessagesMiddleware::class,
  ];

  <<__Override>>
  public function register(): void {
    $this->share(Http\Flash\FlashMessagesMiddleware::class);
  }
}
