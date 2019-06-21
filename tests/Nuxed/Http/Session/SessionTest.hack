namespace Nuxed\Test\Http\Session;

use namespace Nuxed\Http\Session;
use type Facebook\HackTest\HackTest;
use function Facebook\FBExpect\expect;

class SessionTest extends HackTest {
  public function testGetId(): void {
    $session = new Session\Session(dict[], 'example');
    expect($session->getId())->toBeSame('example');
  }

  public function testGet(): void {
    $session = new Session\Session(dict[
      'foo' => 'bar',
      'bar' => null,
      'baz' => 'qux',
    ]);

    expect($session->get('foo'))->toBeSame('bar');
    expect($session->get('bar'))->toBeNull();
    expect($session->get('bar', 1))->toBeNull();
    expect($session->get('baz'))->toBeSame('qux');
    expect($session->get('qux'))->toBeNull();
    expect($session->get('qux', 1))->toBeSame(1);
  }

  public function testContain(): void {
    $session = new Session\Session(dict[
      'foo' => 'bar',
      'bar' => null,
      'baz' => 'qux',
    ]);

    expect($session->contains('foo'))->toBeTrue();
    expect($session->contains('bar'))->toBeTrue();
    expect($session->contains('baz'))->toBeTrue();
    expect($session->contains('qux'))->toBeFalse();
  }

  public function testPut(): void {
    $session = new Session\Session(dict[]);
    $session->put('foo', 'bar');
    expect($session->contains('foo'))->toBeTrue();
    expect($session->get('foo'))->toBeSame('bar');
    expect($session->changed())->toBeTrue();
    expect($session->items())->toBeSame(dict['foo' => 'bar']);
  }

  public function testAdd(): void {
    $session = new Session\Session(dict[]);
    $session->add('a', 'b');
    $session->add('a', 'c');
    expect($session->contains('a'))->toBeTrue();
    expect($session->get('a'))->toBeSame('b');
    expect($session->changed())->toBeTrue();
    expect($session->items())->toBeSame(dict['a' => 'b']);
  }

  public function testIncrement(): void {
    $session = new Session\Session(dict[]);
    $session->put('a', 1);
    $session->increment('a', 3);
    $session->increment('a', 0);
    $session->increment('a');
    $session->increment('a', 4);
    expect($session->get('a'))->toBeSame(9);
  }

  public function testDecrement(): void {
    $session = new Session\Session(dict[]);
    $session->put('a', 1);
    $session->decrement('a', 3);
    $session->decrement('a', 0);
    $session->decrement('a');
    $session->decrement('a', 4);
    expect($session->get('a'))->toBeSame(-7);
  }

  public function testIncrementAndDecrementOnNonNumericValues(): void {
    $session = new Session\Session(dict[]);
    $session->put('a', 'b');
    expect(() ==> $session->increment('a'))
      ->toThrow(\TypeAssertionException::class);
    expect(() ==> $session->decrement('a'))
      ->toThrow(\TypeAssertionException::class);
  }

  public function testRemember(): void {
    $session = new Session\Session(dict[]);
    $session->put('a', 'b');
    $a = $session->remember('a', () ==> 'c');
    expect($a)->toBeSame('b');
    $a = $session->get('a');
    expect($a)->toBeSame('b');
    $d = $session->remember('d', () ==> 'c');
    expect($d)->toBeSame('c');
    $d = $session->get('d');
    expect($d)->toBeSame('c');
  }

  public function testForget(): void {
    $session = new Session\Session(dict[
      'foo' => 'bar',
      'bar' => 'baz',
      'baz' => 'qux',
      'qux' => 'foo',
    ]);
    expect($session->contains('foo'))->toBeTrue();
    $session->forget('foo');
    expect($session->contains('foo'))->toBeFalse();
    expect($session->changed())->toBeTrue();
    expect($session->contains('bar'))->toBeTrue();
    $session->forget('bar');
    expect($session->contains('bar'))->toBeFalse();
    expect($session->items())->toBeSame(dict[
      'baz' => 'qux',
      'qux' => 'foo',
    ]);
  }

  public function testClear(): void {
    $session = new Session\Session(dict[
      'foo' => 'bar',
      'bar' => 'baz',
      'baz' => 'qux',
      'qux' => 'foo',
    ]);
    expect($session->contains('foo'))->toBeTrue();
    expect($session->contains('bar'))->toBeTrue();
    expect($session->contains('baz'))->toBeTrue();
    expect($session->contains('qux'))->toBeTrue();
    $session->clear();
    expect($session->contains('foo'))->toBeFalse();
    expect($session->contains('bar'))->toBeFalse();
    expect($session->contains('baz'))->toBeFalse();
    expect($session->contains('qux'))->toBeFalse();
    expect($session->changed())->toBeTrue();
    // session is not flushed, we just clear the data.
    expect($session->flushed())->toBeFalse();
  }

  public function testFlush(): void {
    $session = new Session\Session(dict[
      'foo' => 'bar',
      'bar' => 'baz',
      'baz' => 'qux',
      'qux' => 'foo',
    ]);
    expect($session->contains('foo'))->toBeTrue();
    expect($session->contains('bar'))->toBeTrue();
    expect($session->contains('baz'))->toBeTrue();
    expect($session->contains('qux'))->toBeTrue();
    $session->flush();
    expect($session->contains('foo'))->toBeFalse();
    expect($session->contains('bar'))->toBeFalse();
    expect($session->contains('baz'))->toBeFalse();
    expect($session->contains('qux'))->toBeFalse();
    expect($session->changed())->toBeTrue();
    expect($session->flushed())->toBeTrue();
  }

  public function testFlushed(): void {
    $session = new Session\Session(dict[]);
    expect($session->flushed())->toBeFalse();
    $session->flush();
    expect($session->flushed())->toBeTrue();
  }

  public function testChanged(): void {
    $session = new Session\Session(dict[]);
    expect($session->changed())->toBeFalse();
    $session->put('foo', 'bar');
    expect($session->changed())->toBeTrue();
    $session->forget('foo');
    expect($session->changed())->toBeFalse();
  }

  public function testRegenerate(): void {
    $session = new Session\Session(dict[]);
    $new = $session->regenerate();
    expect($session->regenerated())->toBeFalse();
    expect($new->regenerated())->toBeTrue();
    expect($session)->toNotBeSame($new);
  }

  public function testRegenerated(): void {
    $session = new Session\Session(dict[]);
    expect($session->regenerated())->toBeFalse();
    $session = $session->regenerate();
    expect($session->regenerated())->toBeTrue();
  }

  public function testExpire(): void {
    $session = new Session\Session(dict[]);
    $session->expire(300);
    expect($session->age())->toBeSame(300);
    expect($session->get(Session\Session::SESSION_AGE_KEY))->toBeSame(300);
  }

  public function testAge(): void {
    $session = new Session\Session(dict[]);
    expect($session->age())->toBeSame(0);
    $session = new Session\Session(dict[
      Session\Session::SESSION_AGE_KEY => 300,
    ]);
    expect($session->age())->toBeSame(300);
  }
}
