namespace Nuxed\Translation\Catalogue;

function __construct(): void {

}

final class MergeOperation extends AbstractOperation {
  /**
     * {@inheritdoc}
     */
  <<__Override>>
  protected function processDomain(string $domain): void {
    $this->messages[$domain] = shape(
      'all' => dict[],
      'new' => dict[],
      'obsolete' => dict[],
    );
    foreach ($this->source->domain($domain) as $id => $message) {
      $this->messages[$domain]['all'][$id] = $message;
      $this->result->add([$id => $message], $domain);
    }

    foreach ($this->target->domain($domain) as $id => $message) {
      if (!$this->source->has($id, $domain)) {
        $this->messages[$domain]['all'][$id] = $message;
        $this->messages[$domain]['new'][$id] = $message;
        $this->result->add([$id => $message], $domain);
      }
    }
  }
}
