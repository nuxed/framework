namespace Nuxed\Translation;

final class Format {
  const classname<Loader\ILoader<string>>
    Json = Loader\JsonFileLoader::class,
    Ini = Loader\IniFileLoader::class,
    Yaml = Loader\YamlFileLoader::class;

  const classname<Loader\ILoader<KeyedContainer<string, mixed>>> Tree =
    Loader\TreeLoader::class;
}
