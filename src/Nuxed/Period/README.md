# The Nuxed Perid Component

This repository is read-only. Please refer to the official framework repository for any issues or pull requests.

---

The Nuxed Period component is a time range API.

> Note! This package is a hack implementation of The PHP Leagues `league/period` package.
> we would like to thank everyone how have contributed to the League/Period package.
> League Period : <https://github.com/thephpleague/period>
> League Period Contributors : <https://github.com/thephpleague/period/graphs/contributors>

---

## Installation

This package can be install with Composer.

```console
composer install nuxed/markdown
```

---

## Usage

> The Period component is Hack's missing time range API. it is based on [`league/period`](https://github.com/thephpleague/period) php packages, which is based on [Resolving Feature Envy in the Domain](https://verraes.net/2014/08/resolving-feature-envy-in-the-domain/) By Mathias Verraes and extends the concept to cover all basic operations regarding interval.

In your code, you will always have to typehint against the `Nuxed\Period\Period` class directly because it is a immutable value object class marked as final and the library does not provide an interface.

### Accessing the interval properties

```hack
use type Nuxed\Period\Period;
use type DateTimeImmutable;
use type DateTime;

$interval = new Period(
    new DateTime('2014-10-03 08:12:37'),
    new DateTimeImmutable('2014-10-03 08:12:37')
);

$start = $interval->getStartDate(); // returns a `Nuxed\Period\DatePoint` object
$end = $interval->getEndDate(); // returns a `Nuxed\Period\DatePoint` object
$duration = $interval->getDateInterval(); // returns a `Nuxed\Period\Duration` object
$durationInSeconds = $interval->getTimestampInterval(); // returns the duration in seconds

print $interval->toString();
// result: 2014-10-03T08:12:37Z/2014-10-03T09:12:37Z
```

### Iterate over the interval

A simple example on how to get all the days from a selected month.

```hack
foreach (Period::fromMonth(2014, 10)->getDatePeriod('1 DAY') as $day) {
    $day->format('Y-m-d');
}
```

### Comparing intervals

```hack
$interval = Period::after('2014-01-01', '1 WEEK');
$alt_interval = Period::fromIsoWeek(2014, 1);
$interval->durationEquals($alt_interval); // returns true
$interval->equals($alt_interval);         // returns false
```

### Modifying Interval

```hack
$period = Period::after('2014-01-01', '1 WEEK');
$altPeriod = $period->endingOn('2014-02-03');
$period->contains($altPeriod); //return false;
$altPeriod->durationGreaterThan($period); //return true;
```

### Accessing all gaps between intervals

```hack
$sequence = new Sequence(
    new Period('2018-01-01', '2018-01-31'),
    new Period('2017-01-01', '2017-01-31'),
    new Period('2020-01-01', '2020-01-31')
);
$gaps = $sequence->gaps(); // a new Sequence object
print $gaps->count();
// result: 2
```

### Building Blocks

#### Definitions

##### Concepts

- *interval* - `Period` is a Hack implementation of a datetime interval which consists of :
  - two datepoints;
  - the duration between them;
  - a boundary type.
- *datepoint* - A position in time expressed as a `DateTimeImmutable` object. The starting datepoint is always less than or equal to the ending datepoint.
- *duration* - The continuous portion of time between two datepoints expressed as a `DateInterval` object. The duration cannot be negative.
- *boundary type* - An included datepoint means that the boundary datepoint itself is included in the interval as well, while an excluded datepoint means that the boundary datepoint is not included in the interval. The package supports included and excluded datepoint, thus, the following boundary types are supported:
  - included starting datepoint and excluded ending datepoint : `[start, end);`
  - included starting datepoint and included ending datepoint : `[start, end];`
  - excluded starting datepoint and included ending datepoint : `(start, end];`
  - excluded starting datepoint and excluded ending datepoint : `(start, end);`

> infinite or unbounded intervals are not supported.

##### Arguments

Since this package relies heavily on `DateTimeImmutable` and `DateInterval` objects and because it is sometimes complicated to get your hands on such objects the package comes bundled with:

- Two classes:
  - `Nuxed\Period\DatePoint`
  - `Nuxed\Period\Duration`

### DatePoint

A datepoint is a position in time expressed as a `DateTimeImmutable` object.

The `DatePoint` class is introduced to ease `DatePoint` manipulation. This class extends Hack's DateTimeImmutable class by adding a new named constructor and several getter methods.

#### Named constructor

> public static function create(mixed $datepoint): this

Returns a `DatePoint` object or throws:

- a TypeError if the submitted parameter have the wrong type.

> *Parameters*

- `$datepoint` can be:
  - a `DateTimeInterface` implementing object.
  - a `string` parsable by the `DateTime` constructor.
  - an `integer` interpreted as a timestamp.

>Because we are using Hack's parser, values exceeding ranges will be added to their parent values.
>If no timezone information is given, the returned `DatePoint` object will use the current timezone.

#### Examples

Using the `$datepoint` argument

```hack
use type Nuxed\Period\Datepoint;

Datepoint::create('yesterday');
// returns new Datepoint('yesterday')
Datepoint::create(2018);
// returns new Datepoint('@2018')
Datepoint::create(new DateTime('2018-10-15'));  
// returns new Datepoint('2018-10-15')
Datepoint::create(new DateTimeImmutable('2018-10-15'));  
// returns new Datepoint('2018-10-15')
```

#### Accessubg calendar interval

Once you’ve got a `DatePoint` instantiated object, you can access a set of calendar type interval using the following methods.

```hack
public DatePoint::getSecond(): Period;
public DatePoint::getMinute(): Period;
public DatePoint::getHour(): Period;
public DatePoint::getDay(): Period;
public DatePoint::getIsoWeek(): Period;
public DatePoint::getMonth(): Period;
public DatePoint::getQuarter(): Period;
public DatePoint::getSemester(): Period;
public DatePoint::getYear(): Period;
public DatePoint::getIsoYear(): Period;
```

For each these methods a `Period` object is returned with:

- the `Period::INCLUDE_START_EXCLUDE_END` boundary type;
- the starting datepoint represents the beginning of the current datepoint calendar interval;
- the duration associated with the given calendar interval;

> *Examples*

```hack
use type Nuxed\Period\DatePoint;

$datepoint = new DatePoint('2018-06-18 08:35:25');
$hour = $datepoint->getHour();
// new Period('2018-06-18 08:00:00', '2018-06-18 09:00:00');
$month = $datepoint->getMonth();
// new Period('2018-06-01 00:00:00', '2018-07-01 00:00:00');
$month->contains($datepoint); // true
$hour->contains($datepoint); // true
$month->contains($hour); // true
```

### Duration

A duration is the continuous portion of time between two datepoints expressed as a `DateInterval` object. The duration cannot be negative.

The `Duration` class is introduced to ease duration manipulation. This class extends Hack’s `DateInterval` class by adding a new named constructor.

#### Named constructor

> public static function create(mixed $duration): this

Converts its single input into a `Duration` object or throws a `TypeError` otherwise.

> *Parameter*

`$duration` can be :

- a `Nuxed\Period\Period` object;
- a `DateInterval` object;
- a `string` parsable by `DateInterval::createFromDateString` method.
- an `integer` interpreted as the interval expressed in seconds.

> *Examples*

```hack
use type Nuxed\Period\Duration;
use type Nuxed\Period\Period;

Duration::create('1 DAY');
// returns new DateInterval('P1D')
Duration::create(2018);
// returns new DateInterval('PT2018S')
Duration::create(new DateInterval('PT1H'));
// returns new DateInterval('PT1H')
Duration::create(new Period('now', 'tomorrow'));
// returns (new DateTime('yesterday'))->diff(new DateTime('tomorrow'))
```

#### Duration::__construct

The constructor supports fraction on the smallest value.

For instance, the following is works while throwing an Exception on `DateInterval`.

```hack
use type Nuxed\Period\Duration;
use type DateInterval;

$duration = new Duration('PT5M0.5S');
$duration->f; // 0.5;

new DateInterval('PT5M0.5S'); // will throw an Exception
```

#### Duration representations

> *String representation*

```hack
public Duration::toString(void): string
```

Returns the string representation of a `Duration` object using [ISO8601 time interval representation](http://en.wikipedia.org/wiki/ISO_8601#Durations)

```hack
$duration = new Duration('PT5M0.5S');
print $duration->toString();
// result: PT5M0.5S
```

As per the specification the smallest value (ie the second) can accept a decimal fraction.

### Period

#### Instatiation

>datepoint and duration conversions are done internally using the `Nuxed\Period\DatePoint` and the `Nuxed\Period\Duration` classes.

##### The constructor

```hack
  public Period::__construct(
    mixed $startDate,
    mixed $endDate,
    private PeriodBoundaryType $boundaryType =
      PeriodBoundaryType::INCLUDE_START_EXCLUDE_END,
  )
```

> *Parameters*

- The `$startDate` represents the starting datepoint.
- The `$endDate` represents the ending datepoint.
- The `$boundaryType` represents the interval boundary type.

Both `$startDate` and `$endDate` parameters are datepoints. `$endDate` must be greater or equal to `$startDate` or the instantiation will throw a `Nuxed\Period\Exception\LogicException`.

> *Example*

```hack
use type Nuxed\Period\Period;
use type Nuxed\Period\PeriodBoundaryType;

$period1 = new Period(
    '2012-04-01 08:30:25',
    '2013-09-04 12:35:21',
    PeriodBoundaryType::EXCLUDE_ALL
);
```

---

## Security Vulnerabilities

If you discover a security vulnerability within Nuxed Markdown, please send an e-mail to Saif Eddin Gmati via azjezz@protonmail.com.

---

## License

The Nuxed framework is open-sourced software licensed under the MIT-licensed.