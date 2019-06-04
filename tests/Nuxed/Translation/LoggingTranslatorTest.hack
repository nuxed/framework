namespace Nuxed\Test\Translation;

use namespace HH\Lib\C;
use namespace HH\Lib\Str;
use namespace Nuxed\Log;
use namespace Nuxed\Translation;
use namespace Nuxed\Translation\Exception;
use namespace Facebook\HackTest;
use function Facebook\FBExpect\expect;

class LoggingTranslatorTest extends HackTest\HackTest {
  public function testTransWithNoTranslationIsLogged(): void {
    $logger = new Log\BufferingLogger();
    $translator = new Translation\Translator('en');
    $loggableTranslator = new Translation\LoggingTranslator(
      $translator,
      $logger,
    );
    expect($loggableTranslator->trans('bar'))->toBeSame('bar');
    $logs = $logger->cleanLogs();
    expect(C\count($logs))->toBeSame(1);
    $log = C\firstx($logs);
    expect($log['level'])->toBeSame(Log\LogLevel::WARNING);
    expect($log['message'])->toBeSame('Translation not found.');
    expect($log['context'])->toBeSame(
      dict[
        'id' => 'bar',
        'domain' => 'messages',
        'locale' => 'en',
      ],
    );
  }

  public function testTransFallbackIsLogged(): void {
    $logger = new Log\BufferingLogger();
    $translator = new Translation\Translator('fr');
    $translator->setFallbackLocales(vec['en']);
    $translator->addLoader(
      Translation\Format::Tree,
      new Translation\Loader\TreeLoader(),
    );
    $translator->addResource(
      Translation\Format::Tree,
      dict['hello' => 'Hello {name}!'],
      'en',
    );
    $loggableTranslator = new Translation\LoggingTranslator(
      $translator,
      $logger,
    );
    expect($loggableTranslator->trans('hello', dict['name' => 'Saif']))
      ->toBeSame('Hello Saif!');
    $logs = $logger->cleanLogs();
    expect(C\count($logs))->toBeSame(1);
    $log = C\firstx($logs);
    expect($log['level'])->toBeSame(Log\LogLevel::DEBUG);
    expect($log['message'])->toBeSame('Translation use fallback catalogue.');
    expect($log['context'])->toBeSame(
      dict[
        'id' => 'hello',
        'domain' => 'messages',
        'locale' => 'fr',
      ],
    );
  }

  public function testSetLocaleIsLogged(): void {
    $logger = new Log\BufferingLogger();
    $translator = new Translation\Translator('fr');
    $loggableTranslator = new Translation\LoggingTranslator(
      $translator,
      $logger,
    );
    $loggableTranslator->setLocale('en');
    $logs = $logger->cleanLogs();
    expect(C\count($logs))->toBeSame(1);
    $log = C\firstx($logs);
    expect($log['level'])->toBeSame(Log\LogLevel::DEBUG);
    expect($log['message'])->toBeSame(
      'The locale of the translator has changed from "fr" to "en".',
    );
  }
}
