namespace Nuxed\Translation\Catalogue;

/**
 * Merge operation between two catalogues as follows:
 * all = source ∪ target = {x: x ∈ source ∨ x ∈ target}
 * new = all ∖ source = {x: x ∈ target ∧ x ∉ source}
 * obsolete = source ∖ all = {x: x ∈ source ∧ x ∉ source ∧ x ∉ target} = ∅
 * Basically, the result contains messages from both catalogues.
 */
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
