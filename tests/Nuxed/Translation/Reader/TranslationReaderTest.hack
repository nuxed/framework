namespace Nuxed\Test\Translation\Reader;

use namespace Facebook\HackTest;
use namespace Nuxed\Translation;
use namespace Nuxed\Translation\Reader;
use namespace Nuxed\Translation\Loader;

use function Facebook\FBExpect\expect;

class TranslationReaderTest extends HackTest\HackTest {
  <<HackTest\DataProvider('provideLoaders')>>
  public function testRead(
    string $format,
    Loader\ILoader<string> $loader,
  ): void {
    $reader = new Reader\TranslationReader();
    $reader->addLoader($format, $loader);
    $catalogue = new Translation\MessageCatalogue('en');
    $reader->read(__DIR__.'/../fixtures/', $catalogue);

    $domains = $catalogue->getDomains();
    expect($domains)->toContain('user');
    expect($domains)->toContain('messages');
    expect($catalogue->domain('messages'))
      ->toBeSame(dict[
        "layout.home" => "Home",
        "layout.login" => "Login",
        "layout.register" => "Register",
        "layout.logout" => "Logout",
        "layout.settings" => "Settings",
        "layout.forgot_password" => "Forgot your password ?",
        "layout.logout_confirmation" => "Are you sure you want to logout ?",
        "layout.password_recover" => "Recover password",
        "layout.password_reset" => "Reset password",
      ]);
    expect($catalogue->domain('user'))
      ->toBeSame(dict[
        "group.edit.submit" => "Update group",
        "group.show.name" => "Group name",
        "group.new.submit" => "Create group",
        "group.flash.updated" => "The group has been updated.",
        "group.flash.created" => "The group has been created.",
        "group.flash.deleted" => "The group has been deleted.",
        "security.login.username" => "Username",
        "security.login.password" => "Password",
        "security.login.remember_me" => "Remember me",
        "security.login.submit" => "Log in",
        "profile.show.username" => "Username",
        "profile.show.email" => "Email",
        "profile.edit.submit" => "Update",
        "profile.flash.updated" => "The profile has been updated.",
      ]);
  }

  public function provideLoaders(
  ): Container<(string, Loader\ILoader<string>)> {
    $loaders = vec[
      tuple('ini', new Loader\IniFileLoader()),
      tuple('json', new Loader\JsonFileLoader()),
    ];

    if (\function_exists('yaml_parse_file')) {
      $loaders[] = tuple('yaml', new Loader\YamlFileLoader());
      $loaders[] = tuple('yml', new Loader\YamlFileLoader());
    }

    return $loaders;
  }
}
