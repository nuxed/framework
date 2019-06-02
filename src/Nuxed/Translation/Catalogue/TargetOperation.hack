namespace Nuxed\Translation\Catalogue;

/**
 * Target operation between two catalogues:
 * intersection = source ∩ target = {x: x ∈ source ∧ x ∈ target}
 * all = intersection ∪ (target ∖ intersection) = target
 * new = all ∖ source = {x: x ∈ target ∧ x ∉ source}
 * obsolete = source ∖ all = source ∖ target = {x: x ∈ source ∧ x ∉ target}
 * Basically, the result contains messages from the target catalogue.
 */
class TargetOperation extends AbstractOperation {
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

    // For 'all' messages, the code can't be simplified as ``$this->messages[$domain]['all'] = $target->all($domain);``,
    // because doing so will drop messages like {x: x ∈ source ∧ x ∉ target.all ∧ x ∈ target.fallback}
    //
    // For 'new' messages, the code can't be simplified as ``array_diff_assoc($this->target->all($domain), $this->source->all($domain));``
    // because doing so will not exclude messages like {x: x ∈ target ∧ x ∉ source.all ∧ x ∈ source.fallback}
    //
    // For 'obsolete' messages, the code can't be simplified as ``array_diff_assoc($this->source->all($domain), $this->target->all($domain))``
    // because doing so will not exclude messages like {x: x ∈ source ∧ x ∉ target.all ∧ x ∈ target.fallback}
    foreach ($this->source->domain($domain) as $id => $message) {
      if ($this->target->has($id, $domain)) {
        $this->messages[$domain]['all'][$id] = $message;
        $this->result->add([$id => $message], $domain);
      } else {
        $this->messages[$domain]['obsolete'][$id] = $message;
      }
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
