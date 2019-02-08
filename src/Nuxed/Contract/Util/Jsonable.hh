<?hh // strict

namespace Nuxed\Contract\Util;

interface Jsonable {
  /**
   * Return a valid json string.
   * the implementation MUST not call Nuxed\Util\Json::encode
   * on it self, instead the inner data.
   *
   * e.g :
   * <code>
   *     public function toJson(): string
   *     {
   *         return \Nuxed\Util\Json::encode($this->data);
   *     }
   * </code>
   */
  public function toJson(bool $pretty = false): string;
}
