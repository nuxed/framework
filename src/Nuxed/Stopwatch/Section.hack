namespace Nuxed\Stopwatch;

use namespace HH\Lib\C;
use namespace HH\Lib\Str;
use function microtime;

class Section {
  private dict<string, Event> $events = dict[];
  private vec<Section> $children = vec[];
  private ?string $id = null;

  /**
   * @param float|null $origin        Set the origin of the events in this section, use null to set their origin to their start time
   * @param bool       $morePrecision If true, time is stored as float to keep the original microsecond precision
   */
  public function __construct(
    private ?float $origin = null,
    private bool $morePrecision = false,
  ) {
  }

  /**
   * Returns the child section.
   *
   * @param string $id The child section identifier
   *
   * @return ?Section The child section or null when none found
   */
  public function get(string $id): ?Section {
    foreach ($this->children as $child) {
      if ($id === $child->getId()) {
        return $child;
      }
    }
    return null;
  }

  /**
   * Creates or re-opens a child section.
   *
   * @param ?string $id Null to create a new section, the identifier to re-open an existing one
   */
  public function open(?string $id = null): Section {
    $session = null;
    if ($id is nonnull) {
      $session = $this->get($id);
    }

    if (null === $session) {
      $session = new Section(microtime(true) * 1000, $this->morePrecision);
      $this->children[] = $session;
    }

    return $session;
  }

  /**
   * @return string The identifier of the section
   */
  public function getId(): ?string {
    return $this->id;
  }

  /**
   * Sets the session identifier.
   *
   * @param string $id The session identifier
   */
  public function setId(string $id): this {
    $this->id = $id;

    return $this;
  }

  /**
   * Starts an event.
   */
  public function startEvent(string $name, ?string $category): Event {
    if (!C\contains_key($this->events, $name)) {
      $this->events[$name] = new Event(
        $this->origin ?? microtime(true) * 1000,
        $category,
        $this->morePrecision,
      );
    }

    return $this->events[$name]->start();
  }

  /**
   * Checks if the event was started.
   *
   * @param string $name The event name
   */
  public function isEventStarted(string $name): bool {
    return C\contains_key($this->events, $name) &&
      $this->events[$name]->isStarted();
  }

  /**
   * Stops an event.
   *
   * @throws Exception\LogicException When the event has not been started
   */
  public function stopEvent(string $name): Event {
    if (!C\contains_key($this->events, $name)) {
      throw new Exception\LogicException(
        Str\format('Event "%s" is not started.', $name),
      );
    }

    return $this->events[$name]->stop();
  }

  /**
   * Stops then restarts an event.
   *
   * @throws Exception\LogicException When the event has not been started
   */
  public function lap(string $name): Event {
    return $this->stopEvent($name)->start();
  }

  /**
   * Returns a specific event by name.
   *
   * @throws Exception\LogicException When the event is not known
   */
  public function getEvent(string $name): Event {
    if (!C\contains_key($this->events, $name)) {
      throw new Exception\LogicException(
        Str\format('Event "%s" is not known.', $name),
      );
    }

    return $this->events[$name];
  }

  /**
   * Returns the events from this section.
   */
  public function getEvents(): KeyedContainer<string, Event> {
    return $this->events;
  }
}
