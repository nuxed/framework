namespace Nuxed\Stopwatch;

use namespace HH\Lib\{C, Str, Vec};

final class Stopwatch {
  private dict<string, Section> $sections = dict[];
  private vec<Section> $activeSections = vec[];

  /**
   * @param bool $morePrecision If true, time is stored as float to keep the original microsecond precision
   */
  public function __construct(private bool $morePrecision = false) {
    $this->reset();
  }

  public function getSections(): KeyedContainer<string, Section> {
    return $this->sections;
  }

  /**
   * Creates a new section or re-opens an existing section.
   *
   * @param string|null $id The id of the session to re-open, null to create a new one
   *
   * @throws Exception\LogicException When the section to re-open is not reachable
   */
  public function openSection(?string $id = null): void {
    $current = C\last($this->activeSections) as Section;
    if (null !== $id && null === $current->get($id)) {
      throw new Exception\LogicException(Str\format(
        'The section "%s" has been started at an other level and can not be opened.',
        $id,
      ));
    }

    $this->start('__section__.child', 'section');
    $this->activeSections[] = $current->open($id);
    $this->start('__section__');
  }

  /**
   * Stops the last started section.
   *
   * The id parameter is used to retrieve the events from this section.
   *
   * @see getSectionEvents()
   *
   * @throws Exception\LogicException When there's no started section to be stopped
   */
  public function stopSection(string $id): void {
    $this->stop('__section__');

    if (1 === C\count($this->activeSections)) {
      throw new Exception\LogicException(
        'There is no started section to stop.',
      );
    }

    $section = C\last($this->activeSections) as Section;
    $this->activeSections = Vec\take(
      $this->activeSections,
      C\count($this->activeSections) - 1,
    );
    $this->sections[$id] = $section->setId($id);
    $this->stop('__section__.child');
  }

  /**
   * Starts an event.
   *
   * @param string      $name     The event name
   * @param string|null $category The event category
   */
  public function start(string $name, ?string $category = null): Event {
    return C\last($this->activeSections) as Section->startEvent(
      $name,
      $category,
    );
  }

  /**
   * Checks if the event was started.
   */
  public function isStarted(string $name): bool {
    return C\last($this->activeSections) as Section->isEventStarted($name);
  }

  /**
   * Stops an event.
   */
  public function stop(string $name): Event {
    return C\last($this->activeSections) as Section->stopEvent($name);
  }

  /**
   * Stops then restarts an event.
   */
  public function lap(string $name): Event {
    return C\last($this->activeSections) as Section->stopEvent($name)->start();
  }

  /**
   * Returns a specific event by name.
   */
  public function getEvent(string $name): Event {
    return C\last($this->activeSections) as Section->getEvent($name);
  }

  /**
   * Gets all events for a given section.
   *
   * @param string $id A section identifier
   */
  public function getSectionEvents(string $id): KeyedContainer<string, Event> {
    return idx($this->sections, $id)?->getEvents() ?? dict[];
  }

  /**
   * Resets the stopwatch to its original state.
   */
  public function reset(): void {
    $section = new Section(null, $this->morePrecision);
    $this->sections['__root__'] = $section;
    $this->activeSections[] = $section;
  }
}
