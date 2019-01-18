<?hh // strict

namespace Nuxed\Period;

use namespace HH\Lib\Str;
use type DateInterval;
use function gettype;
use function is_object;
use function get_class;
use const FILTER_VALIDATE_INT;

final class Duration extends DateInterval {

  /**
   * Returns a continuous portion of time between two datepoints
   * expressed as a DateInterval object.
   *
   * The duration can be :
   *  an Period object.
   *  a DateInterval object.
   *  an integer interpreted as the duration expressed in seconds.
   *  a string parsable by DateInterval::createFromDateString.
   */
  public static function create(mixed $duration): this {
    if ($duration instanceof Period) {
      $duration = $duration->getDateInterval();
    }

    if ($duration instanceof DateInterval) {
      $new = new self('PT0S');
      $new->d = $duration->d;
      $new->h = $duration->h;
      $new->i = $duration->i;
      $new->m = $duration->m;
      $new->s = $duration->s;
      $new->y = $duration->y;
      $new->days = $duration->days;
      $new->invert = $duration->invert;
      return $new;
    }

    if ($duration is int) {
      return new self(Str\format('PT%dS', $duration));
    }

    if ($duration is string) {
      return static::createFromDateString($duration);
    }

    throw new Exception\InvalidArgumentException(Str\format(
      '%s was expecting Period, DateInterval, int or a string; %s given',
      __FUNCTION__,
      is_object($duration) ? get_class($duration) : gettype($duration),
    ));
  }

  /**
   * {@inheritdoc}
   */
  <<__Override>>
  public static function createFromDateString(string $duration): this {
    return static::create(parent::createFromDateString($duration));
  }

  /**
   * Returns the ISO8601 interval string representation.
   *
   * Microseconds fractions are included
   */
  public function __toString(): string {
    $date = 'P';
    foreach (
      ['Y' => $this->y, 'M' => $this->m, 'D' => $this->d] as $key => $value
    ) {
      if (0 !== $value) {
        $date .= $value.$key;
      }
    }

    $time = 'T';
    foreach (['H' => $this->h, 'M' => $this->i] as $key => $value) {
      if (0 !== $value) {
        $time .= $value.$key;
      }
    }

    if (0 !== $this->s) {
      $time .= $this->s.'S';

      return $date.$time;
    }

    if ('T' !== $time) {
      return $date.$time;
    }

    if ('P' !== $date) {
      return $date;
    }

    return 'PT0S';
  }
}
