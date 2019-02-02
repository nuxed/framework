<?hh // strict

namespace Nuxed\Test\Http\Message;

use type Nuxed\Http\Message\Cookie;
use type Nuxed\Contract\Http\Message\CookieSameSite;
use type DateTime;
use type Facebook\HackTest\HackTest;
use function Facebook\FBExpect\expect;

class CookieTest extends HackTest {
  public function testGetters(): void {
    $cookie = new Cookie(
      'hello',
      $e = new DateTime('2020-12-31'),
      '/',
      'www.facebook.com',
      true,
      true,
      $s = CookieSameSite::STRICT,
    );
    expect($cookie->getValue())->toBeSame('hello');
    expect($cookie->getExpires())->toBeSame($e);
    expect($cookie->getPath())->toBeSame('/');
    expect($cookie->getDomain())->toBeSame('www.facebook.com');
    expect($cookie->isSecure())->toBeTrue();
    expect($cookie->isHttpOnly())->toBeTrue();
  }

  public function testWithValue(): void {
    $cookie = new Cookie('hhvm');
    $cookie2 = $cookie->withValue('hack');
    expect($cookie->getValue())->toBeSame('hhvm');
    expect($cookie2->getValue())->toBeSame('hack');
    expect($cookie2)->toNotBeSame($cookie);
  }

  public function testWithExpires(): void {
    $cookie = new Cookie('hhvm', $e = new DateTime('2000-01-01'));
    $cookie2 = $cookie->withExpires(null);
    $cookie3 = $cookie2->withExpires(new DateTime());
    expect($cookie2)->toNotBeSame($cookie);
    expect($cookie3)->toNotBeSame($cookie2);
    expect($cookie2->getExpires())->toBeNull();
    expect($cookie3->getExpires())->toBeInstanceOf(DateTime::class);
  }

  public function testWithPath(): void {
    $cookie = new Cookie('waffle', new DateTime(), '/auth');
    $cookie2 = $cookie->withPath('/');
    expect($cookie2)->toNotBeSame($cookie);
    expect($cookie2->getPath())->toBeSame('/');
  }

  public function testWithDomain(): void {
    $cookie = new Cookie('waffle', new DateTime(), '/', 'thefacebook.com');
    $cookie2 = $cookie->withDomain('facebook.com');
    expect($cookie2)->toNotBeSame($cookie);
    expect($cookie2->getDomain())->toBeSame('facebook.com');
  }

  public function testWithAndWithoutSecure(): void {
    $cookie = new Cookie('waffle', null, null, null, false);
    expect($cookie->isSecure())->toBeFalse();
    $cookie2 = $cookie->withSecure(true);
    expect($cookie2)->toNotBeSame($cookie);
    expect($cookie2->isSecure())->toBeTrue();
    $cookie3 = $cookie2->withoutSecure();
    expect($cookie3->isSecure())->toBeFalse();
  }

  public function testWithAndWithoutHttpOnly(): void {
    $cookie = new Cookie('waffle', null, null, null, false, false);
    expect($cookie->isHttpOnly())->toBeFalse();
    $cookie2 = $cookie->withHttpOnly(true);
    expect($cookie2)->toNotBeSame($cookie);
    expect($cookie2->isHttpOnly())->toBeTrue();
    $cookie3 = $cookie2->withoutHttpOnly();
    expect($cookie3->isHttpOnly())->toBeFalse();
  }

  public function testWithSameSite(): void {
    $cookie = new Cookie('waffle', null, null, null, false, false, null);
    $sss = CookieSameSite::STRICT;
    $ssl = CookieSameSite::LAX;
    expect($cookie->getSameSite())->toBeNull();
    $cookie2 = $cookie->withSameSite($sss);
    expect($cookie2)->toNotBeSame($cookie);
    expect($cookie2->getSameSite())->toBeSame($sss);
    $cookie3 = $cookie2->withSameSite($ssl);
    expect($cookie3)->toNotBeSame($cookie2);
    expect($cookie3->getSameSite())->toBeSame($ssl);
  }
}
