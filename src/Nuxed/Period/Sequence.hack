namespace Nuxed\Period;

use namespace HH\Lib\Vec;
use type IteratorAggregate;
use type Countable;
use const ARRAY_FILTER_USE_BOTH;

final class Sequence implements Countable, IteratorAggregate<Period> {
  public Vector<Period> $intervals;

  /**
   * new instance.
   *
   * @param Period ...$intervals
   */
  public function __construct(Period ...$intervals) {
    $this->intervals = new Vector($intervals);
  }

  /**
   * Returns the sequence boundaries as a Period instance.
   *
   * If the sequence contains no interval null is returned.
   *
   * @return ?Period
   */
  public function getBoundaries(): ?Period {
    $period = $this->intervals->get(0);
    if (null === $period) {
      return null;
    }

    if (2 === $this->intervals->count()) {
      return $period->merge($this->intervals->at(1), ...vec[]);
    }

    $intervals = clone $this->intervals;
    return $period->merge(
      $intervals->at(1),
      ...$intervals->slice(2, $intervals->count() - 2)
    );
  }

  /**
   * Returns the gaps inside the instance.
   */
  public function gaps(): this {
    $sequence = new self();
    $interval = null;
    $sorted = Vec\sort(
      $this->intervals,
      (Period $a, Period $b): int ==> $a->getStartDate() <=> $b->getStartDate(),
    );

    foreach ($sorted as $period) {
      if (null === $interval) {
        $interval = $period;
        continue;
      }

      if (!$interval->overlaps($period) && !$interval->abuts($period)) {
        $sequence->intervals[] = $interval->gap($period);
      }

      if (!$interval->contains($period)) {
        $interval = $period;
      }
    }

    return $sequence;
  }

  /**
   * Returns the intersections inside the instance.
   */
  public function getIntersections(): this {
    $sequence = new self();
    $current = null;
    $isPreviouslyContained = false;
    $sorted = Vec\sort(
      $this->intervals,
      (Period $a, Period $b): int ==> $a->getStartDate() <=> $b->getStartDate(),
    );
    foreach ($sorted as $period) {
      if (null === $current) {
        $current = $period;
        continue;
      }

      $isContained = $current->contains($period);
      if ($isContained && $isPreviouslyContained) {
        continue;
      }

      if ($current->overlaps($period)) {
        $sequence->intervals[] = $current->intersect($period);
      }

      $isPreviouslyContained = $isContained;
      if (!$isContained) {
        $current = $period;
      }
    }

    return $sequence;
  }

  /**
   * Tells whether some intervals in the current instance satisfies the predicate.
   */
  public function some((function(Period, int): bool) $predicate): bool {
    foreach ($this->intervals as $offset => $interval) {
      if (true === $predicate($interval, $offset)) {
        return true;
      }
    }

    return false;
  }

  /**
   * Tells whether all intervals in the current instance satisfies the predicate.
   */
  public function every((function(Period, int): bool) $predicate): bool {
    foreach ($this->intervals as $offset => $interval) {
      if (true !== $predicate($interval, $offset)) {
        return false;
      }
    }

    return 0 !== $this->intervals->count();
  }

  public function count(): int {
    return $this->intervals->count();
  }

  public function getIterator(): Iterator<Period> {
    return $this->intervals->getIterator();
  }
}
