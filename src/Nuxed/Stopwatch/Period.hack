namespace Nuxed\Stopwatch;


class Period {
  private num $start;
  private num $end;
  private num $memory;

  /**
   * @param num $start         The relative time of the start of the period (in milliseconds)
   * @param num $end           The relative time of the end of the period (in milliseconds)
   * @param bool      $morePrecision If true, time is stored as float to keep the original microsecond precision
   */
  public function __construct(
    num $start,
    num $end,
    bool $morePrecision = true,
  ) {
    $this->start = $morePrecision ? (float)$start : (int)$start;
    $this->end = $morePrecision ? (float)$end : (int)$end;
    $this->memory = \memory_get_usage(true);
  }

  /**
   * Gets the relative time of the start of the period.
   *
   * @return num The time (in milliseconds)
   */
  public function getStartTime(): num {
    return $this->start;
  }
  /**
   * Gets the relative time of the end of the period.
   *
   * @return num The time (in milliseconds)
   */
  public function getEndTime(): num {
    return $this->end;
  }

  /**
   * Gets the time spent in this period.
   *
   * @return num The period duration (in milliseconds)
   */
  public function getDuration(): num {
    return $this->end - $this->start;
  }

  /**
   * Gets the memory usage.
   *
   * @return int The memory usage (in bytes)
   */
  public function getMemory(): num {
    return $this->memory;
  }
}
