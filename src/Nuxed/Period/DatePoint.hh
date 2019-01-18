<?hh // strict

namespace Nuxed\Period;

use namespace HH\Lib\{Str, Math};
use type DateInterval;
use type DateTime;
use type DateTimeImmutable;
use type DateTimeInterface;
use type DateTimeZone;
use const FILTER_VALIDATE_INT;

final class DatePoint extends DateTimeImmutable {
  /**
   * Returns a position in time expressed as a DateTimeImmutable object.
   *
   * A datepoint can be
   * - a DateTimeInterface object
   * - a integer interpreted as a timestamp
   * - a string parsable by DateTime::__construct
   */
  public static function create(mixed $datepoint): this {
    if ($datepoint instanceof DateTimeInterface) {
      return new self(
        $datepoint->format('Y-m-d H:i:s.u'),
        $datepoint->getTimezone(),
      );
    }

    if ($datepoint is int) {
      return new self(Str\format('@%d', $datepoint));
    }

    return new self($datepoint);
  }

  <<__Override>>
  public static function createFromFormat(
    string $format,
    mixed $datetime,
    ?DateTimeZone $timezone = null,
  ): ?this {
    $datepoint = parent::createFromFormat($format, $datetime, $timezone);
    if (false !== $datepoint) {
      return self::create($datepoint);
    }
    return null;
  }

  /**
   * @inheritdoc
   */
  <<__Override>>
  public static function createFromMutable(DateTime $datetime): this {
    return self::create(parent::createFromMutable($datetime));
  }

  /**
   * Returns a Period instance.
   *
   *  - the starting datepoint represents the beginning of the current datepoint second
   *  - the duration is equal to 1 second
   */
  public function getSecond(): Period {
    $datepoint = $this->setTime(
      (int)$this->format('H'),
      (int)$this->format('i'),
      (int)$this->format('s'),
    );

    return new Period($datepoint, $datepoint->add(new DateInterval('PT1S')));
  }

  /**
   * Returns a Period instance.
   *
   *  - the starting datepoint represents the beginning of the current datepoint minute
   *  - the duration is equal to 1 minute
   */
  public function getMinute(): Period {
    $datepoint =
      $this->setTime((int)$this->format('H'), (int)$this->format('i'), 0);

    return new Period($datepoint, $datepoint->add(new DateInterval('PT1M')));
  }

  /**
   * Returns a Period instance.
   *
   *  - the starting datepoint represents the beginning of the current datepoint hour
   *  - the duration is equal to 1 hour
   */
  public function getHour(): Period {
    $datepoint = $this->setTime((int)$this->format('H'), 0);

    return new Period($datepoint, $datepoint->add(new DateInterval('PT1H')));
  }

  /**
   * Returns a Period instance.
   *
   *  - the starting datepoint represents the beginning of the current datepoint day
   *  - the duration is equal to 1 day
   */
  public function getDay(): Period {
    $datepoint = $this->setTime(0, 0);

    return new Period($datepoint, $datepoint->add(new DateInterval('P1D')));
  }

  /**
   * Returns a Period instance.
   *
   *  - the starting datepoint represents the beginning of the current datepoint iso week day
   *  - the duration is equal to 7 days
   */
  public function getIsoWeek(): Period {
    $startDate = $this
      ->setTime(0, 0)
      ->setISODate((int)$this->format('o'), (int)$this->format('W'), 1);

    return new Period($startDate, $startDate->add(new DateInterval('P7D')));
  }

  /**
   * Returns a Period instance.
   *
   *  - the starting datepoint represents the beginning of the current datepoint month
   *  - the duration is equal to 1 month
   */
  public function getMonth(): Period {
    $startDate = $this
      ->setTime(0, 0)
      ->setDate((int)$this->format('Y'), (int)$this->format('n'), 1);

    return new Period($startDate, $startDate->add(new DateInterval('P1M')));
  }

  /**
   * Returns a Period instance.
   *
   *  - the starting datepoint represents the beginning of the current datepoint quarter
   *  - the duration is equal to 3 months
   */
  public function getQuarter(): Period {
    $startDate = $this
      ->setTime(0, 0)
      ->setDate(
        (int)$this->format('Y'),
        (Math\int_div((int)$this->format('n'), 3) * 3) + 1,
        1,
      );

    return new Period($startDate, $startDate->add(new DateInterval('P3M')));
  }

  /**
   * Returns a Period instance.
   *
   *  - the starting datepoint represents the beginning of the current datepoint semester
   *  - the duration is equal to 6 months
   */
  public function getSemester(): Period {
    $startDate = $this
      ->setTime(0, 0)
      ->setDate(
        (int)$this->format('Y'),
        (Math\int_div((int)$this->format('n'), 6) * 6) + 1,
        1,
      );

    return new Period($startDate, $startDate->add(new DateInterval('P6M')));
  }

  /**
   * Returns a Period instance.
   *
   *  - the starting datepoint represents the beginning of the current datepoint year
   *  - the duration is equal to 1 year
   */
  public function getYear(): Period {
    $year = (int)$this->format('Y');
    $datepoint = $this->setTime(0, 0);

    return new Period(
      $datepoint->setDate($year, 1, 1),
      $datepoint->setDate(++$year, 1, 1),
    );
  }

  /**
   * Returns a Period instance.
   *
   *  - the starting datepoint represents the beginning of the current datepoint iso year
   *  - the duration is equal to 1 iso year
   */
  public function getIsoYear(): Period {
    $year = (int)$this->format('o');
    $datepoint = $this->setTime(0, 0);

    return new Period(
      $datepoint->setISODate($year, 1, 1),
      $datepoint->setISODate(++$year, 1, 1),
    );
  }
}
