namespace Nuxed\Http\Message;

use namespace HH\Lib\Str;
use namespace HH\Lib\C;
use namespace HH\Lib\Vec;
use namespace HH\Lib\Math;

/**
 * Logic largely refactored from the Symfony HttpFoundation Symfony\Component\HttpFoundation\IpUtils class.
 *
 * @copyright Copyright (c) 2004-2019 Fabien Potencier. (https://symfony.com)
 * @license   https://github.com/symfony/symfony/blob/master/LICENSE MIT License
 */
final abstract class IpUtils {
  private static dict<string, bool> $checkedIps = dict[];

  /**
   * Checks if an IPv4 or IPv6 address is contained in the list of given IPs or subnets.
   *
   * @param string              $requestIp IP to check
   * @param Container<string>   $ips       List of IPs or subnets
   *
   * @return bool Whether the IP is valid
   */
  public static function checkIp(
    string $requestIp,
    Container<string> $ips,
  ): bool {
    if (Str\contains($requestIp, ':')) {
      $check = ($requestIp, $ip) ==> static::checkIp6($requestIp, $ip);
    } else {
      $check = ($requestIp, $ip) ==> static::checkIp4($requestIp, $ip);
    }

    foreach ($ips as $ip) {
      if ($check($requestIp, $ip)) {
        return true;
      }
    }

    return false;
  }

  /**
   * Compares two IPv4 addresses.
   * In case a subnet is given, it checks if it contains the request IP.
   *
   * @param string $requestIp IPv4 address to check
   * @param string $ip        IPv4 address or subnet in CIDR notation
   *
   * @return bool Whether the request IP matches the IP, or whether the request IP is within the CIDR subnet
   */
  public static function checkIp4(string $requestIp, string $ip): bool {
    $cacheKey = $requestIp.'-'.$ip;
    if (C\contains_key(static::$checkedIps, $cacheKey)) {
      return static::$checkedIps[$cacheKey];
    }

    if (!\filter_var($requestIp, \FILTER_VALIDATE_IP, \FILTER_FLAG_IPV4)) {
      return self::$checkedIps[$cacheKey] = false;
    }

    if (Str\contains($ip, '/')) {
      list($address, $netmask) = Str\split($ip, '/', 2);
      if ('0' === $netmask) {
        return self::$checkedIps[$cacheKey] = \filter_var(
          $address,
          \FILTER_VALIDATE_IP,
          \FILTER_FLAG_IPV4,
        );
      }

      $netmask = (int)$netmask;

      if ($netmask < 0 || $netmask > 32) {
        return self::$checkedIps[$cacheKey] = false;
      }
    } else {
      $address = $ip;
      $netmask = 32;
    }

    if (false === \ip2long($address)) {
      return self::$checkedIps[$cacheKey] = false;
    }

    return self::$checkedIps[$cacheKey] = (
      0 ===
        \substr_compare(
          Str\format('%032b', \ip2long($requestIp)),
          Str\format('%032b', \ip2long($address)),
          0,
          $netmask,
        )
    );
  }

  /**
   * Compares two IPv6 addresses.
   * In case a subnet is given, it checks if it contains the request IP.
   *
   * @author David Soria Parra <dsp at php dot net>
   *
   * @see https://github.com/dsp/v6tools
   *
   * @param string $requestIp IPv6 address to check
   * @param string $ip        IPv6 address or subnet in CIDR notation
   *
   * @return bool Whether the IP is valid
   */
  public static function checkIp6(string $requestIp, string $ip): bool {
    $cacheKey = $requestIp.'-'.$ip;
    if (C\contains_key(static::$checkedIps, $cacheKey)) {
      return static::$checkedIps[$cacheKey];
    }

    if (Str\contains($ip, '/')) {
      list($address, $netmask) = Str\split($ip, '/', 2);
      if ('0' === $netmask) {
        return (bool)\unpack('n*', @\inet_pton($address));
      }
      $netmask = (int)$netmask;
      if ($netmask < 1 || $netmask > 128) {
        return self::$checkedIps[$cacheKey] = false;
      }
    } else {
      $address = $ip;
      $netmask = 128;
    }

    $bytesAddr = \unpack('n*', @\inet_pton($address));
    $bytesTest = \unpack('n*', @\inet_pton($requestIp));
    if (!$bytesAddr || !$bytesTest) {
      return self::$checkedIps[$cacheKey] = false;
    }

    for ($i = 1, $ceil = Math\ceil($netmask / 16); $i <= $ceil; ++$i) {
      $left = $netmask - 16 * ($i - 1);
      $left = ($left <= 16) ? $left : 16;
      $mask = ~(0xffff >> $left) & 0xffff;
      if (($bytesAddr[$i] & $mask) != ($bytesTest[$i] & $mask)) {
        return self::$checkedIps[$cacheKey] = false;
      }
    }
    return self::$checkedIps[$cacheKey] = true;
  }
}
