<?hh // strict

namespace Nuxed\Period;

use namespace HH\Lib\Str;
use type Nuxed\Lib\Json;
use type Nuxed\Contract\Lib\Jsonable;
use type Nuxed\Lib\StringableTrait;
use type DateInterval;
use type DatePeriod;
use type DateTimeImmutable;
use type DateTimeInterface;
use type DateTimeZone;
use type JsonSerializable;

final class Period implements JsonSerializable, Jsonable {
  use StringableTrait;

  const string ISO8601_FORMAT = 'Y-m-d\TH:i:s.i\Z';

  private DatePoint $startDate;
  private DatePoint $endDate;

  public function __construct(mixed $startDate, mixed $endDate) {
    $startDate = DatePoint::create($startDate);
    $endDate = DatePoint::create($endDate);
    if ($startDate > $endDate) {
      throw new Exception\LogicException(
        'The ending datepoint must be greater or equal to the starting datepoint',
      );
    }
    $this->startDate = $startDate;
    $this->endDate = $endDate;
  }

  /**
   * Creates new instance from a starting datepoint and a duration.
   */
  public static function after(mixed $startDate, mixed $duration): this {
    $startDate = DatePoint::create($startDate);
    $duration = Duration::create($duration);
    return new self($startDate, $startDate->add($duration));
  }

  /**
   * Creates new instance from a ending datepoint and a duration.
   */
  public static function before(mixed $endDate, mixed $duration): this {
    $endDate = DatePoint::create($endDate);
    $duration = Duration::create($duration);
    return new self($endDate->sub($duration), $endDate);
  }

  /**
   * Creates new instance where the given duration is simultaneously
   * substracted from and added to the datepoint.
   */
  public static function around(mixed $datepoint, mixed $duration): this {
    $datepoint = DatePoint::create($datepoint);
    $duration = Duration::create($duration);
    return new self($datepoint->sub($duration), $datepoint->add($duration));
  }

  /**
   * Creates new instance for a specific year.
   */
  public static function fromYear(int $year): this {
    $startDate = (new DateTimeImmutable())
      ->setDate($year, 1, 1)
      ->setTime(0, 0);

    return new self($startDate, $startDate->add(new DateInterval('P1Y')));
  }

  /**
   * Creates new instance for a specific ISO year.
   */
  public static function fromIsoYear(int $year): this {
    return new self(
      (new DateTimeImmutable())->setISODate($year, 1)->setTime(0, 0),
      (new DateTimeImmutable())->setISODate(++$year, 1)->setTime(0, 0),
    );
  }

  /**
   * Creates new instance for a specific year and semester.
   */
  public static function fromSemester(int $year, int $semester = 1): this {
    $month = (($semester - 1) * 6) + 1;
    $startDate =
      (new DateTimeImmutable())->setDate($year, $month, 1)->setTime(0, 0);
    return new self($startDate, $startDate->add(new DateInterval('P6M')));
  }

  /**
   * Creates new instance for a specific year and quarter.
   */
  public static function fromQuarter(int $year, int $quarter = 1): this {
    $month = (($quarter - 1) * 3) + 1;
    $startDate =
      (new DateTimeImmutable())->setDate($year, $month, 1)->setTime(0, 0);
    return new self($startDate, $startDate->add(new DateInterval('P3M')));
  }

  /**
   * Creates new instance for a specific year and month.
   */
  public static function fromMonth(int $year, int $month = 1): this {
    $startDate =
      (new DateTimeImmutable())->setDate($year, $month, 1)->setTime(0, 0);
    return new self($startDate, $startDate->add(new DateInterval('P1M')));
  }

  /**
   * Creates new instance for a specific ISO8601 week.
   */
  public static function fromIsoWeek(int $year, int $week = 1): this {
    $startDate = (new DateTimeImmutable())->setISODate($year, $week, 1)
      ->setTime(0, 0);
    return new self($startDate, $startDate->add(new DateInterval('P7D')));
  }

  /**
   * Creates new instance for a specific year, month and day.
   */
  public static function fromDay(
    int $year,
    int $month = 1,
    int $day = 1,
  ): this {
    $startDate = (new DateTimeImmutable())->setDate($year, $month, $day)
      ->setTime(0, 0);
    return new self($startDate, $startDate->add(new DateInterval('P1D')));
  }

  /**
   * Creates new instance from a DatePeriod.
   */
  public static function fromDatePeriod(DatePeriod $datePeriod): this {
    return new self($datePeriod->getStartDate(), $datePeriod->getEndDate());
  }

  /**
   * Returns the starting exluded datepoint.
   */
  public function getStartDate(): DatePoint {
    return $this->startDate;
  }

  /**
   * Returns the ending excluded datepoint.
   */
  public function getEndDate(): DatePoint {
    return $this->endDate;
  }

  /**
   * Returns the instance duration as expressed in seconds.
   */
  public function getTimestampInterval(): int {
    return (int)(
      $this->getEndDate()->getTimestamp() -
      $this->getStartDate()->getTimestamp()
    );
  }

  /**
   * Returns the instance duration as a DateInterval object.
   */
  public function getDateInterval(): DateInterval {
    return $this->getStartDate()->diff($this->getEndDate());
  }

  /**
   * Allows iteration over a set of dates and times,
   * recurring at regular intervals, over the instance.
   */
  public function getDatePeriod(mixed $duration, int $options = 0): DatePeriod {
    $duration = Duration::create($duration);
    return new DatePeriod(
      $this->getStartDate(),
      $duration,
      $this->getEndDate(),
      $options,
    );
  }

  /**
   * Allows iteration over a set of dates and times,
   * recurring at regular intervals, over the instance backwards
   * starting from the instance ending datepoint
   */
  public function getDatePeriodBackwards(
    mixed $duration,
  ): Container<DateTimeInterface> {
    $duration = Duration::create($duration);
    $date = $this->getEndDate();
    $result = vec[];
    while ($date > $this->getStartDate()) {
      $result[] = $date;
      $date = $date->sub($duration);
    }

    return $result;
  }

  /**
   * Returns the JSON representation of an instance.
   *
   * Based on the JSON representation of dates as
   * returned by Javascript Date.toJson() method.
   *
   * @link https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Date/toJSON
   * @link https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Date/toISOString
   */
  public function jsonSerialize(): mixed {
    $utc = new DateTimeZone('UTC');

    return shape(
      'startDate' => $this->getStartDate()
        ->setTimezone($utc)
        ->format(self::ISO8601_FORMAT),
      'endDate' => $this->getEndDate()
        ->setTimezone($utc)
        ->format(self::ISO8601_FORMAT),
    );
  }

  /**
   * @see JsonSerialize()
   */
  public function toJson(bool $pretty = false): string {
    return Json::encode($this->jsonSerialize(), $pretty);
  }

  /**
   * Returns the string representation as a ISO8601 interval format.
   *
   * @link https://en.wikipedia.org/wiki/ISO_8601#Time_intervals
   */
  public function toString(): string {
    $interval = $this->jsonSerialize() as
      shape('startDate' => string, 'endDate' => string, ...);

    return $interval['startDate'].'/'.$interval['endDate'];
  }

  /**
   * Returns the mathematical representation of an instance as a left close, right open interval.
   *
   * @link https://en.wikipedia.org/wiki/Interval_(mathematics)#Notations_for_intervals
   * @link https://www.postgresql.org/docs/9.3/static/rangetypes.html
   *
   * @param string $format the format of the outputted date string
   */
  public function format(string $format): string {
    return '['.
      $this->getStartDate()->format($format).
      ', '.
      $this->getEndDate()->format($format).
      ')';
  }

  /**
   * Compares two instances according to their duration.
   *
   * Returns:
   *
   *  -1 if the current Interval is lesser than the submitted Interval object.
   *  1 if the current Interval is greater than the submitted Interval object.
   *  0 if both Interval objects have the same duration.
   */
  public function durationCompare(this $interval): int {
    return $this->getEndDate() <=>
      $this->getStartDate()->add($interval->getDateInterval());
  }

  /**
   * Tells whether the current instance duration is equal to the submitted one.
   */
  public function durationEquals(this $interval): bool {
    return 0 === $this->durationCompare($interval);
  }

  /**
   * Tells whether the current instance duration is greater than the submitted one.
   */
  public function durationGreaterThan(this $interval): bool {
    return 1 === $this->durationCompare($interval);
  }

  /**
   * Tells whether the current instance duration is less than the submitted one.
   */
  public function durationLessThan(this $interval): bool {
    return -1 === $this->durationCompare($interval);
  }

  /**
   * Tells whether two intervals share the same datepoints.
   *
   * [--------------------)
   * [--------------------)
   */
  public function equals(this $interval): bool {
    return $this->getStartDate()->getTimestamp() ===
      $interval->getStartDate()->getTimestamp() &&
      $this->getEndDate()->getTimestamp() ===
        $interval->getEndDate()->getTimestamp();
  }

  /**
   * Tells whether two intervals abuts.
   *
   * [--------------------)
   *                      [--------------------)
   * or
   *                      [--------------------)
   * [--------------------)
   */
  public function abuts(this $interval): bool {
    return $this->getStartDate()->getTimestamp() ===
      $interval->getEndDate()->getTimestamp() ||
      $this->getEndDate()->getTimestamp() ===
        $interval->getStartDate()->getTimestamp();
  }

  /**
   * Tells whether two intervals overlaps.
   *
   * [--------------------)
   *          [--------------------)
   */
  public function overlaps(this $interval): bool {
    return $this->getStartDate() < $interval->getEndDate() &&
      $this->getEndDate() > $interval->getStartDate();
  }

  /**
   * Tells whether an interval is entirely after the specified index.
   * The index can be a DateTimeInterface object or another Period object.
   *
   *                          [--------------------)
   * [--------------------)
   */
  public function isAfter(mixed $index): bool {
    if ($index is DatePeriod) {
      $index = static::fromDatePeriod($index);
    }
    if ($index is Period) {
      return $this->getStartDate() >= $index->getEndDate();
    }

    return $this->getStartDate() > DatePoint::create($index);
  }

  /**
   * Tells whether an instance is entirely before the specified index.
   *
   * The index can be a DateTimeInterface object or another Period object.
   *
   * [--------------------)
   *                          [--------------------)
   */
  public function isBefore(mixed $index): bool {
    if ($index is DatePeriod) {
      $index = static::fromDatePeriod($index);
    }
    if ($index is Period) {
      return $this->getEndDate() <= $index->getStartDate();
    }

    return $this->endDate <= DatePoint::create($index);
  }

  /**
   * Tells whether an instance fully contains the specified index.
   *
   * The index can be a DateTimeInterface object or another Period object.
   */
  public function contains(mixed $index): bool {
    if ($index is DatePeriod) {
      $index = static::fromDatePeriod($index);
    }
    if ($index is Period) {
      return $this->containsInterval($index);
    }

    return $this->containsDatepoint(DatePoint::create($index));
  }

  /**
   * Tells whether an instance fully contains another instance.
   *
   * [--------------------)
   *     [----------)
   */
  private function containsInterval(this $interval): bool {
    return $this->containsDatepoint($interval->startDate) &&
      (
        $interval->endDate >= $this->startDate &&
        $interval->endDate <= $this->endDate
      );
  }

  /**
   * Tells whether an instance contains a datepoint.
   *
   * [------|------------)
   */
  private function containsDatepoint(mixed $datepoint): bool {
    $datepoint = DatePoint::create($datepoint);
    return $datepoint >= $this->startDate && $datepoint < $this->endDate;
  }

  /**
   * Allows splitting an instance in smaller Period objects according to a given interval.
   *
   * The returned iterable Interval set is ordered so that:
   * <ul>
   * <li>The first returned object MUST share the starting datepoint of the parent object.</li>
   * <li>The last returned object MUST share the ending datepoint of the parent object.</li>
   * <li>The last returned object MUST have a duration equal or lesser than the submitted interval.</li>
   * <li>All returned objects except for the first one MUST start immediately after the previously returned object</li>
   * </ul>
   *
   * @param mixed $duration a Duration
   *
   * @return iterable<Period>
   */
  public function split(mixed $duration): Container<Period> {
    $duration = Duration::create($duration);
    $result = vec[];
    foreach ($this->getDatePeriod($duration) as $startDate) {
      $endDate = $startDate->add($duration);
      if ($endDate > $this->endDate) {
        $endDate = $this->endDate;
      }

      $result[] = new self(DatePoint::create($startDate), $endDate);
    }
    return $result;
  }

  /**
   * Allows splitting an instance in smaller Period objects according to a given interval.
   *
   * The returned iterable Period set is ordered so that:
   * - The first returned object MUST share the ending datepoint of the parent object.
   * - The last returned object MUST share the starting datepoint of the parent object.
   * - The last returned object MUST have a duration equal or lesser than the submitted interval.
   * - All returned objects except for the first one MUST end immediately before the previously returned object.
   */
  public function splitBackwards(mixed $duration): Container<Period> {
    $endDate = $this->endDate;
    $duration = Duration::create($duration);
    $result = vec[];
    do {
      $startDate = $endDate->sub($duration);
      if ($startDate < $this->startDate) {
        $startDate = $this->startDate;
      }
      $result[] = new self($startDate, $endDate);

      $endDate = $startDate;
    } while ($endDate > $this->startDate);
    return $result;
  }

  /**
   * Returns the computed intersection between two instances as a new instance.
   *
   * [--------------------)
   *          ∩
   *                 [----------)
   *          =
   *                 [----)
   *
   * @throws Exception If both objects do not overlaps
   */
  public function intersect(this $interval): this {
    if (!$this->overlaps($interval)) {
      throw new Exception\LogicException(
        Str\format('Both %s objects should overlaps', self::class),
      );
    }

    return new self(
      ($interval->startDate > $this->startDate)
        ? $interval->startDate
        : $this->startDate,
      ($interval->endDate < $this->endDate)
        ? $interval->endDate
        : $this->endDate,
    );
  }

  /**
   * Returns the computed difference between two overlapping instances as
   * an array containing Period objects or the null value.
   *
   * The array will always contains 2 elements:
   *
   * <ul>
   * <li>an NULL filled array if both objects have the same datepoints</li>
   * <li>one Period object and NULL if both objects share one datepoint</li>
   * <li>two Period objects if both objects share no datepoint</li>
   * </ul>
   *
   * [--------------------)
   *          \
   *                [-----------)
   *          =
   * [--------------)  +  [-----)
   *
   * @return array<null|Period>
   */
  public function diff(this $interval): (?Period, ?Period) {
    if ($interval->equals($this)) {
      return tuple(null, null);
    }

    $intersect = $this->intersect($interval);
    $merge = $this->merge($interval);
    if ($merge->startDate === $intersect->startDate) {
      return tuple($merge->startingOn($intersect->endDate), null);
    }

    if ($merge->endDate === $intersect->endDate) {
      return tuple($merge->endingOn($intersect->startDate), null);
    }

    return tuple(
      $merge->endingOn($intersect->startDate),
      $merge->startingOn($intersect->endDate),
    );
  }

  /**
   * Returns the computed gap between two instances as a new instance.
   *
   * [--------------------)
   *          +
   *                          [----------)
   *          =
   *                      [---)
   *
   * @throws Exception If both instance overlaps
   */
  public function gap(this $interval): this {
    if ($this->overlaps($interval)) {
      throw new Exception\LogicException(
        Str\format('Both %s objects must not overlaps', self::class),
      );
    }

    if ($interval->startDate > $this->startDate) {
      return new self($this->endDate, $interval->startDate);
    }

    return new self($interval->endDate, $this->startDate);
  }

  /**
   * Returns the difference between two instances expressed in seconds.
   */
  public function timestampIntervalDiff(this $interval): int {
    return $this->getTimestampInterval() - $interval->getTimestampInterval();
  }

  /**
   * Returns the difference between two instances expressed with a DateInterval object.
   */
  public function dateIntervalDiff(this $interval): DateInterval {
    return $this->endDate
      ->diff($this->startDate->add($interval->getDateInterval()));
  }

  /**
   * Returns an instance with the specified starting datepoint.
   *
   * This method MUST retain the state of the current instance, and return
   * an instance that contains the specified starting datepoint.
   */
  public function startingOn(mixed $startDate): this {
    $startDate = DatePoint::create($startDate);
    if ($startDate === $this->startDate) {
      return $this;
    }

    return new self($startDate, $this->endDate);
  }

  /**
   * Returns an instance with the specified ending datepoint.
   *
   * This method MUST retain the state of the current instance, and return
   * an instance that contains the specified ending datepoint.
   */
  public function endingOn(mixed $endDate): this {
    $endDate = DatePoint::create($endDate);
    if ($endDate === $this->endDate) {
      return $this;
    }

    return new self($this->startDate, $endDate);
  }

  /**
   * Returns a new instance with a new ending datepoint.
   *
   * This method MUST retain the state of the current instance, and return
   * an instance that contains the specified ending datepoint.
   */
  public function withDurationAfterStart(mixed $duration): this {
    return $this->endingOn($this->startDate->add(Duration::create($duration)));
  }

  /**
   * Returns a new instance with a new starting datepoint.
   *
   * This method MUST retain the state of the current instance, and return
   * an instance that contains the specified starting datepoint.
   */
  public function withDurationBeforeEnd(mixed $duration): this {
    return $this->startingOn($this->endDate->sub(Duration::create($duration)));
  }

  /**
   * Returns a new instance with a new starting datepoint
   * moved forward or backward by the given interval.
   *
   * This method MUST retain the state of the current instance, and return
   * an instance that contains the specified starting datepoint.
   */
  public function moveStartDate(mixed $duration): this {
    return
      $this->startingOn($this->startDate->add(Duration::create($duration)));
  }

  /**
   * Returns a new instance with a new ending datepoint
   * moved forward or backward by the given interval.
   *
   * This method MUST retain the state of the current instance, and return
   * an instance that contains the specified ending datepoint.
   *
   * @param mixed $duration a Duration
   */
  public function moveEndDate(mixed $duration): this {
    return $this->endingOn($this->endDate->add(Duration::create($duration)));
  }

  /**
   * Returns a new instance where the datepoints
   * are moved forwards or backward simultaneously by the given DateInterval.
   *
   * This method MUST retain the state of the current instance, and return
   * an instance that contains the specified new datepoints.
   *
   * @param mixed $duration a Duration
   */
  public function move(mixed $duration): this {
    $duration = Duration::create($duration);
    $interval = new self(
      $this->startDate->add($duration),
      $this->endDate->add($duration),
    );
    if ($this->equals($interval)) {
      return $this;
    }

    return $interval;
  }

  /**
   * Returns an instance where the given DateInterval is simultaneously
   * substracted from the starting datepoint and added to the ending datepoint.
   *
   * Depending on the duration value, the resulting instance duration will be expanded or shrinked.
   *
   * This method MUST retain the state of the current instance, and return
   * an instance that contains the specified new datepoints.
   *
   * @param mixed $duration a Duration
   */
  public function expand(mixed $duration): this {
    $duration = Duration::create($duration);
    $interval = new self(
      $this->startDate->sub($duration),
      $this->endDate->add($duration),
    );
    if ($this->equals($interval)) {
      return $this;
    }

    return $interval;
  }

  /**
   * Merges one or more instances to return a new instance.
   * The resulting instance represents the largest duration possible.
   *
   * This method MUST retain the state of the current instance, and return
   * an instance that contains the specified new datepoints.
   *
   * [--------------------)
   *          U
   *                 [----------)
   *          =
   * [--------------------------)
   *
   *
   * @param Period ...$intervals
   */
  public function merge(this $interval, this ...$intervals): this {
    $intervals[] = $interval;
    $carry = $this;
    foreach ($intervals as $interval) {
      if ($carry->startDate > $interval->startDate) {
        $carry = $carry->startingOn($interval->startDate);
      }

      if ($carry->endDate < $interval->endDate) {
        $carry = $carry->endingOn($interval->endDate);
      }
    }
    return $carry;
  }
}
