namespace Nuxed\Test\Translation\Loader;

use namespace Facebook\HackTest;
use namespace Nuxed\Translation\Loader;
use namespace Nuxed\Translation\Exception;
use function Facebook\FBExpect\expect;

class YamlFileLoaderTest extends LoaderTest<string> {
  protected function getLoader(): Loader\ILoader<string> {
    if (!\function_exists('yaml_parse_file')) {
      static::markTestSkipped(
        'Yaml extension is required to use the yaml loader.',
      );
    }

    return new Loader\YamlFileLoader();
  }

  public function provideLoadData(
  ): Container<(string, string, string, KeyedContainer<string, string>)> {
    $en = dict[
      "layout.home" => "Home",
      "layout.login" => "Login",
      "layout.register" => "Register",
      "layout.logout" => "Logout",
      "layout.settings" => "Settings",
      "layout.forgot_password" => "Forgot your password ?",
      "layout.logout_confirmation" => "Are you sure you want to logout ?",
      "layout.password_recover" => "Recover password",
      "layout.password_reset" => "Reset password",
    ];

    $fr = dict[
      "layout.home" => "Accueil",
      "layout.login" => "S'identifier",
      "layout.register" => "Registre",
      "layout.logout" => "Connectez - Out",
      "layout.settings" => "Paramètres",
      "layout.forgot_password" => "Mot de passe oublié ?",
      "layout.logout_confirmation" =>
        "Êtes-vous sûr de vouloir vous déconnecter ?",
      "layout.password_recover" => "Récupérer mot de passe",
      "layout.password_reset" => "Réinitialiser le mot de passe",
    ];

    return vec[
      tuple(__DIR__.'/../fixtures/messages.en.yaml', 'en', 'messages', $en),
      tuple(__DIR__.'/../fixtures/messages.fr.yaml', 'fr', 'messages', $fr),
    ];
  }
}
