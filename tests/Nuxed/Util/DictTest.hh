<?hh // strict

namespace Nuxed\Test\Util;

use type Facebook\HackTest\HackTest;
use type Facebook\HackTest\DataProvider;
use type Nuxed\Util\Dict;
use type InvariantException;
use function Facebook\FBExpect\expect;

class DictTest extends HackTest {

  <<DataProvider('provideUnionData')>>
  public function testUnion<Tk as arraykey, Tv>(
    Container<KeyedContainer<Tk, Tv>> $containers,
    dict<Tk, Tv> $expected,
  ): void {
    expect(Dict::union(...$containers))->toBeSame($expected);
  }

  public function provideUnionData(
  ): Container<
    (Container<KeyedContainer<arraykey, mixed>>, dict<arraykey, mixed>),
  > {
    return vec[
      tuple(
        vec[
          Map {'a' => 'apple', 'b' => 'banana'},
          dict['a' => 'pear', 'b' => 'strawberry', 'c' => 'cherry'],
          darray['c' => 'chocolat'],
        ],
        dict['a' => 'apple', 'b' => 'banana', 'c' => 'cherry'],
      ),
      tuple(
        vec[
          dict['a' => 'pear', 'b' => 'strawberry', 'c' => 'cherry'],
          Map {'a' => 'apple', 'b' => 'banana'},
          darray['c' => 'chocolat'],
        ],
        dict['a' => 'pear', 'b' => 'strawberry', 'c' => 'cherry'],
      ),
      tuple(
        vec[
          darray['c' => 'chocolat'],
          dict['a' => 'pear', 'b' => 'strawberry', 'c' => 'cherry'],
          Map {'a' => 'apple', 'b' => 'banana'},
        ],
        dict['c' => 'chocolat', 'a' => 'pear', 'b' => 'strawberry'],
      ),
    ];
  }

  <<DataProvider('provideOnlyData')>>
  public function testOnly<Tk as arraykey, Tv>(
    KeyedContainer<Tk, Tv> $container,
    Container<Tk> $keys,
    dict<Tk, Tv> $expected,
  ): void {
    expect(Dict::only($container, $keys))->toBeSame($expected);
  }

  public function provideOnlyData(
  ): Container<(
    KeyedContainer<arraykey, mixed>,
    Container<arraykey>,
    dict<arraykey, mixed>,
  )> {
    return vec[
      tuple(
        Map {
          'a' => 5,
          'b' => 45,
          'c' => 34,
          'd' => 93,
        },
        keyset['a', 'b'],
        dict['a' => 5, 'b' => 45],
      ),
      tuple(Map {'a' => 5, 'b' => 45}, keyset[], dict[]),
      tuple(
        Map {'a' => 5, 'b' => 45},
        vec['a', 'b'],
        dict['a' => 5, 'b' => 45],
      ),
      tuple(
        Map {'a' => 5, 'b' => 45},
        vec['a', 'b', 'c', 'd'],
        dict['a' => 5, 'b' => 45],
      ),
    ];
  }

  <<DataProvider('provideCombineData')>>
  public function testCombine<To as int, Tk as arraykey, Tv>(
    KeyedContainer<To, Tk> $keys,
    KeyedContainer<To, Tv> $values,
    dict<Tk, Tv> $expected,
  ): void {
    expect(Dict::combine($keys, $values))->toBeSame($expected);
  }

  public function provideCombineData(
  ): Container<(
    KeyedContainer<int, arraykey>,
    KeyedContainer<int, mixed>,
    dict<arraykey, mixed>,
  )> {
    $a = Set {};
    $b = Vector {};
    $c = Map {};
    return vec[
      tuple(
        vec['a', 'b', 'c'],
        vec['a', 'b', 'c'],
        dict['a' => 'a', 'b' => 'b', 'c' => 'c'],
      ),
      tuple(
        vec[1, 2, 3],
        vec['a', 'b', 'c'],
        dict[1 => 'a', 2 => 'b', 3 => 'c'],
      ),
      tuple(
        vec['a', 'b', 'c'],
        vec[1, 2, 3],
        dict['a' => 1, 'b' => 2, 'c' => 3],
      ),
      tuple(
        vec['a', 'b', 'c'],
        vec['d', 'e', 'f'],
        dict['a' => 'd', 'b' => 'e', 'c' => 'f'],
      ),
      tuple(
        vec['1', '2', '3'],
        vec[$a, $b, $c],
        dict['1' => $a, '2' => $b, '3' => $c],
      ),
    ];
  }

  public function testCombineThrowsWhenArgumentsAreNotOfTheSameSize(): void {
    expect(() ==> {
      Dict::combine(vec['a', 'v'], dict[]);
    })->toThrow(
      InvariantException::class,
      'Both parameters should have an equal number of elements',
    );
  }
}
