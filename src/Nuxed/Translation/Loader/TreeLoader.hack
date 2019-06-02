namespace Nuxed\Translation\Loader;

use namespace HH\Lib\Str;
use namespace Facebook\TypeSpec;
use namespace Nuxed\Translation;

final class TreeLoader implements ILoader<KeyedContainer<string, mixed>> {
  /**
   * @param tree<arraykey, string> $resource
   */
  public function load(
    KeyedContainer<string, mixed> $resource,
    string $locale,
    string $domain = 'messages',
  ): Translation\MessageCatalogue {
    $catalogue = new Translation\MessageCatalogue($locale);
    $catalogue->add($this->flatten($resource), $domain);
    return $catalogue;
  }

  final protected function flatten(
    KeyedContainer<string, mixed> $tree,
  ): KeyedContainer<string, string> {
    $result = dict[];
    foreach ($tree as $key => $value) {
      if ($value is arraykey || $value is num) {
        $result[$key] = $value is num
          ? Str\format_number($value, 2)
          : (string)$value;
      } else {
        $value = TypeSpec\dict(TypeSpec\string(), TypeSpec\mixed())
          ->coerceType($value);
        foreach ($this->flatten($value) as $k => $v) {
          $result[$key.'.'.$k] = $v;
        }
      }
    }

    return $result;
  }
}
