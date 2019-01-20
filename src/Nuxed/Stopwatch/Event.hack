namespace Nuxed\Stopwatch;

use namespace HH\Lib\C;
use namespace HH\Lib\Str;
use namespace HH\Lib\Vec;
use namespace HH\Lib\Math;
use function microtime;

class Event {
  private vec<Period> $periods = vec[];
  private float $origin;
  private string $category;
  private bool $morePrecision;
  private vec<num> $started = vec[];

  /**
   * @param float       $origin        The origin time in milliseconds
   * @param string|null $category      The event category or null to use the default
   * @param bool        $morePrecision If true, time is stored as float to keep the original microsecond precision
   */
  public function __construct(
    float $origin,
    ?string $category = null,
    bool $morePrecision = false,
  ) {
    $this->origin = $this->formatTime($origin);
    $this->category = $category ?? 'default';
    $this->morePrecision = $morePrecision;
  }

  /**
   * Gets the category.
   *
   * @return string The category
   */
  public function getCategory(): string {
    return $this->category;
  }

  /**
   * Gets the origin.
   *
   * @return float The origin in milliseconds
   */
  public function getOrigin(): float {
    return $this->origin;
  }

  /**
   * Starts a new event period.
   *
   * @return $this
   */
  public function start(): this {
    $this->started[] = $this->getNow();

    return $this;
  }

  /**
   * Stops the last started event period.
   *
   * @return $this
   *
   * @throws \LogicException When stop() is called without a matching call to start()
   */
  public function stop(): this {
    $started = C\last($this->started);
    if (null === $started || 0 === C\count($this->started)) {
      throw new Exception\LogicException(
        'stop() called but start() has not been called before.',
      );
    }

    $this->started = Vec\take($this->started, C\count($this->started) - 1);
    $this->periods[] =
      new Period($started, $this->getNow(), $this->morePrecision);

    return $this;
  }

  /**
   * Checks if the event was started.
   *
   * @return bool
   */
  public function isStarted(): bool {
    return !C\is_empty($this->started);
  }

  /**
   * Stops the current period and then starts a new one.
   *
   * @return $this
   */
  public function lap(): this {
    return $this->stop()->start();
  }

  /**
   * Stops all non already stopped periods.
   */
  public function ensureStopped(): void {
    while (0 !== C\count($this->started)) {
      $this->stop();
    }
  }

  /**
   * Gets all event periods.
   */
  public function getPeriods(): vec<Period> {
    return $this->periods;
  }

  /**
   * Gets the relative time of the start of the first period.
   *
   * @return num The time (in milliseconds)
   */
  public function getStartTime(): num {
    $first = C\first($this->periods);
    return $first?->getStartTime() ?? 0;
  }

  /**
   * Gets the relative time of the end of the last period.
   *
   * @return num The time (in milliseconds)
   */
  public function getEndTime(): num {
    $last = C\last($this->periods);
    return $last?->getEndTime() ?? 0;
  }

  /**
   * Gets the duration of the events (including all periods).
   *
   * @return num The duration (in milliseconds)
   */
  public function getDuration(): num {
    $periods = $this->periods;
    $stopped = C\count($periods);
    $left = C\count($this->started) - $stopped;

    for ($i = 0; $i < $left; ++$i) {
      $index = $stopped + $i;
      $periods[] = new Period(
        $this->started[$index],
        $this->getNow(),
        $this->morePrecision,
      );
    }

    $total = 0;
    foreach ($periods as $period) {
      $total += $period->getDuration();
    }

    return $total;
  }

  /**
   * Gets the max memory usage of all periods.
   *
   * @return num The memory usage (in bytes)
   */
  public function getMemory(): num {
    $memory = 0;
    foreach ($this->periods as $period) {
      if ($period->getMemory() > $memory) {
        $memory = $period->getMemory();
      }
    }

    return $memory;
  }

  /**
   * Return the current time relative to origin.
   *
   * @return float Time in ms
   */
  protected function getNow(): num {
    return $this->formatTime(microtime(true) * 1000 - $this->origin);
  }

  /**
   * Formats a time.
   *
   * @param num $time A raw time
   *
   * @return float The formatted time
   */
  private function formatTime(num $time): float {
    return Math\round($time, 1);
  }

  /**
   * @return string
   */
  public function __toString(): string {
    return Str\format(
      '%s: %.2F MiB - %d ms',
      $this->getCategory(),
      (float)($this->getMemory() / 1024 / 1024),
      (int)($this->getDuration()),
    );
  }
}
