namespace Nuxed\Contract\Lib;

interface Jsonable {
  /**
   * Return a valid json string.
   * the implementation MUST not call Nuxed\Lib\Json::encode
   * on it self, instead the inner data.
   *
   * e.g :
   * <code>
   *     public function toJson(): string
   *     {
   *         return \Nuxed\Lib\Json::encode($this->data);
   *     }
   * </code>
   */
  public function toJson(bool $pretty = false): string;
}
