namespace Nuxed\Crypto\Str;

function equals(string $known, string $user): bool {
  return \hash_equals($known, $user);
}
