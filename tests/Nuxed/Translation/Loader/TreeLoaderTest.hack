namespace Nuxed\Test\Translation\Loader;

use namespace Facebook\HackTest;
use namespace Nuxed\Translation\Loader;
use namespace Nuxed\Translation\Exception;
use function Facebook\FBExpect\expect;

class TreeLoaderTest extends LoaderTest<this::Tree> {
  const type Tree = KeyedContainer<string, mixed>;

  protected function getLoader(): Loader\ILoader<this::Tree> {
    return new Loader\TreeLoader();
  }

  public function provideLoadData(
  ): Container<(this::Tree, string, string, KeyedContainer<string, string>)> {
    $fr = dict[

    ];

    return vec[
      tuple(
        dict[
          "layout" => dict[
            "home" => "Home",
            "login" => "Login",
            "register" => "Register",
            "logout" => "Logout",
            "settings" => "Settings",
            "forgot_password" => "Forgot your password ?",
            "logout_confirmation" => "Are you sure you want to logout ?",
            "password_recover" => "Recover password",
            "password_reset" => "Reset password",
          ],
        ],
        'en',
        'messages',
        dict[
          "layout.home" => "Home",
          "layout.login" => "Login",
          "layout.register" => "Register",
          "layout.logout" => "Logout",
          "layout.settings" => "Settings",
          "layout.forgot_password" => "Forgot your password ?",
          "layout.logout_confirmation" => "Are you sure you want to logout ?",
          "layout.password_recover" => "Recover password",
          "layout.password_reset" => "Reset password",
        ],
      ),
      tuple(
        dict[
          "layout.home" => "Home",
          "layout.login" => "Login",
          "layout.register" => "Register",
          "layout.logout" => "Logout",
          "layout.settings" => "Settings",
          "layout.forgot_password" => "Forgot your password ?",
          "layout.logout_confirmation" => "Are you sure you want to logout ?",
          "layout.password_recover" => "Recover password",
          "layout.password_reset" => "Reset password",
        ],
        'en',
        'messages',
        dict[
          "layout.home" => "Home",
          "layout.login" => "Login",
          "layout.register" => "Register",
          "layout.logout" => "Logout",
          "layout.settings" => "Settings",
          "layout.forgot_password" => "Forgot your password ?",
          "layout.logout_confirmation" => "Are you sure you want to logout ?",
          "layout.password_recover" => "Recover password",
          "layout.password_reset" => "Reset password",
        ],
      ),
      tuple(
        dict[
          "layout" => dict[
            "home" => "Accueil",
            "login" => "S'identifier",
            "register" => "Registre",
            "logout" => "Connectez - Out",
            "settings" => "Paramètres",
            "forgot_password" => "Mot de passe oublié ?",
            "logout_confirmation" =>
              "Êtes-vous sûr de vouloir vous déconnecter ?",
            "password_recover" => "Récupérer mot de passe",
            "password_reset" => "Réinitialiser le mot de passe",
          ],
        ],
        'fr',
        'messages',
        dict[
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
        ],
      ),

    ];
  }
}
