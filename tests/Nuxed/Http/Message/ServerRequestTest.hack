namespace Nuxed\Test\Http\Message;

use namespace HH\Lib\C;
use namespace Nuxed\Http\Message;
use type Facebook\HackTest\HackTest;
use function Facebook\FBExpect\expect;

class ServerRequestTest extends HackTest {
  public function testUploadsFiles(): void {
    $request1 = new Message\ServerRequest('GET', Message\uri('/'));
    $file = new Message\UploadedFile(
      Message\stream('test'),
      null,
      Message\UploadedFileError::ERROR_OK,
    );
    $request2 = $request1->withUploadedFiles(['file' => $file]);
    expect($request2)->toNotBeSame($request1);
    expect($request1->getUploadedFiles())->toBeEmpty();
    expect($request2->getUploadedFiles())->toNotBeEmpty();
    expect(C\count($request2->getUploadedFiles()))->toBeSame(1);
    expect($request2->getUploadedFiles()['file'])->toBeSame($file);
  }

  public function testServerParams(): void {
    $params = dict['name' => 'value'];
    $request = new Message\ServerRequest(
      'GET',
      Message\uri('/'),
      dict[],
      null,
      '1.1',
      $params,
    );
    expect($request->getServerParams())->toBeSame($params);
  }

  public function testCookieParams(): void {
    $request1 = new Message\ServerRequest('GET', Message\uri('/'));
    $params = dict['name' => 'value'];
    $request2 = $request1->withCookieParams($params);
    expect($request1)->toNotBeSame($request2);
    expect($request1->getCookieParams())->toBeEmpty();
    expect($request2->getCookieParams())->toBeSame($params);
  }

  public function testQueryParams(): void {
    $request1 = new Message\ServerRequest('GET', Message\uri('/'));
    $params = dict['name' => 'value'];
    $request2 = $request1->withQueryParams($params);
    expect($request1)->toNotBeSame($request2);
    expect($request1->getQueryParams())->toBeEmpty();
    expect($request2->getQueryParams())->toBeSame($params);
  }

  public function testParsedBody(): void {
    $request1 = new Message\ServerRequest('GET', Message\uri('/'));
    $params = dict['name' => 'value'];
    $request2 = $request1->withParsedBody($params);
    expect($request1)->toNotBeSame($request2);
    expect($request1->getParsedBody())->toBeEmpty();
    expect($request2->getParsedBody())->toBeSame($params);
  }

  public function testAttributes(): void {
    $request1 = new Message\ServerRequest('GET', Message\uri('/'));
    $request2 = $request1->withAttribute('name', 'value');
    $request3 = $request2->withAttribute('other', 'otherValue');
    $request4 = $request3->withoutAttribute('other');
    $request5 = $request3->withoutAttribute('unknown');
    expect($request1)->toNotBeSame($request2);
    expect($request2)->toNotBeSame($request3);
    expect($request3)->toNotBeSame($request4);
    expect($request4)->toNotBeSame($request5);
    expect($request1->getAttributes())->toBeEmpty();
    expect($request1->getAttribute('name'))->toBeNull();
    expect($request1->getAttribute('name', 'something'))->toBeSame(
      'something',
      'Should return the default value',
    );
    expect($request2->getAttribute('name'))->toBeSame('value');
    expect($request2->getAttributes())->toBeSame(dict['name' => 'value']);
    expect($request3->getAttributes())->toBeSame(
      dict['name' => 'value', 'other' => 'otherValue'],
    );
    expect($request4->getAttributes())->toBeSame(dict['name' => 'value']);
  }

  public function testNullAttribute(): void {
    $request = (
      new Message\ServerRequest('GET', Message\uri('/'))
    )->withAttribute('name', null);
    expect($request->getAttributes())->toBeSame(dict['name' => null]);
    expect($request->getAttribute('name', 'different-default'))->toBeNull();
    $requestWithoutAttribute = $request->withoutAttribute('name');
    expect($requestWithoutAttribute->getAttributes())->toBeSame(dict[]);
    expect($requestWithoutAttribute->getAttribute('name', 'different-default'))
      ->toBeSame('different-default');
  }
}
