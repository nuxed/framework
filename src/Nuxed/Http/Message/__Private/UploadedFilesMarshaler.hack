namespace Nuxed\Http\Message\__Private;

use namespace HH\Lib\Str;
use namespace HH\Lib\Dict;
use namespace Nuxed\Http\Message\Exception;
use namespace Facebook\TypeSpec;
use namespace Facebook\TypeAssert;
use type Nuxed\Http\Message\Stream;
use type Nuxed\Http\Message\UploadedFile;
use type Nuxed\Contract\Http\Message\UploadedFileError;
use type Nuxed\Contract\Http\Message\UploadedFileInterface;
use function is_readable;
use function fopen;

/**
 * Logic largely refactored from the Zend-Diactoros Zend\Diactoros\normalizeUploadedFiles function.
 *
 * @see       https://github.com/zendframework/zend-diactoros/blob/master/src/functions/normalize_uploaded_files.php
 * @copyright Copyright (c) 2018 Zend Technologies USA Inc. (https://www.zend.com)
 * @license   https://github.com/zendframework/zend-diactoros/blob/master/LICENSE.md New BSD License
 */
class UploadedFilesMarshaler {
  const type FileStructure = shape(
    'tmp_name' => string,
    'size' => ?int,
    'error' => int,
    ?'name' => ?string,
    ?'type' => ?string,
    ...
  );

  public function marshal(
    KeyedContainer<arraykey, mixed> $files,
    ?string $prefix = null,
  ): KeyedContainer<string, UploadedFileInterface> {
    $result = dict[];
    foreach ($files as $index => $file) {
      if ($prefix is nonnull) {
        $index = Str\format('%s[%s]', $prefix, (string)$index);
      } else {
        $index = (string)$index;
      }

      if ($file is UploadedFileInterface) {
        $result[$index] = $file;
        continue;
      }

      $spec = $this->matchesFileStructure($file);
      if ($spec is nonnull) {
        $result[$index] = $this->createUploadedFile($spec);
        continue;
      }

      try {
        $tree = $this->marshalUploadedFileTree($index, $file);
        if ($tree is nonnull) {
          $result = Dict\merge($result, $tree);
        }
      } catch (\OutOfBoundsException $e) {
        try {
          $spec = TypeSpec\dict(TypeSpec\arraykey(), TypeSpec\mixed());
          $result = Dict\merge(
            $result,
            $this->marshal($spec->coerceType($file), $index),
          );
        } catch (TypeAssert\TypeCoercionException $e) {
          throw new Exception\InvalidArgumentException(
            'Invalid value in files specification',
            $e->getCode(),
            $e,
          );
        }
      }
    }

    return $result;
  }

  private function createUploadedFile(
    this::FileStructure $fileSpec,
  ): UploadedFileInterface {
    $tmpName = $fileSpec['tmp_name'];

    if (!is_readable($tmpName)) {
      throw new Exception\InvalidArgumentException(
        Str\format('uploaded file "%s" is not readable', $fileSpec['tmp_name']),
      );
    }

    $stream = new Stream(fopen($tmpName, 'rb'));

    $error = $fileSpec['error'];

    $error = UploadedFileError::assert($error);

    return new UploadedFile(
      $stream,
      $fileSpec['size'],
      $error,
      $fileSpec['name'] ?? null,
      $fileSpec['type'] ?? null,
    );
  }

  private function matchesFileStructure(mixed $value): ?this::FileStructure {
    try {
      return TypeAssert\matches_type_structure(
        \type_structure($this, 'FileStructure'),
        $value,
      );
    } catch (TypeAssert\IncorrectTypeException $e) {
      return null;
    }
  }

  private function marshalUploadedFileTreeRecursively(
    string $index,
    KeyedContainer<arraykey, mixed> $tmp,
    KeyedContainer<arraykey, mixed> $size,
    KeyedContainer<arraykey, mixed> $error,
    ?KeyedContainer<arraykey, mixed> $name = null,
    ?KeyedContainer<arraykey, mixed> $type = null,
  ): KeyedContainer<string, UploadedFileInterface> {
    $files = dict[];
    foreach ($tmp as $k => $v) {
      $key = Str\format('%s[%s]', $index, (string)$k);
      if ($v is KeyedContainer<_, _>) {
        $spec = TypeSpec\dict(TypeSpec\arraykey(), TypeSpec\mixed());
        $nullableSpec = TypeSpec\nullable($spec);
        $files = Dict\merge(
          $files,
          $this->marshalUploadedFileTreeRecursively(
            $key,
            $spec->coerceType($tmp[$k]),
            $spec->coerceType($size[$k]),
            $spec->coerceType($error[$k]),
            $nullableSpec->coerceType($name[$k] ?? null),
            $nullableSpec->coerceType($type[$k] ?? null),
          ),
        );
      } else {
        $files[$key] =
          $this->createUploadedFile($this->matchesFileStructure(shape(
            'tmp_name' => $tmp[$k],
            'size' => $size[$k],
            'error' => $error[$k],
            'name' => $name[$k] ?? null,
            'type' => $type[$k] ?? null,
          )) as nonnull);
      }
    }

    return $files;
  }

  private function marshalUploadedFileTree(
    string $index,
    mixed $file,
  ): ?KeyedContainer<string, UploadedFileInterface> {
    try {
      $files =
        TypeSpec\dict(TypeSpec\string(), TypeSpec\mixed())->coerceType($file);
      $spec = TypeSpec\dict(TypeSpec\arraykey(), TypeSpec\mixed());
      $nullableSpec = TypeSpec\nullable($spec);
      return $this->marshalUploadedFileTreeRecursively(
        $index,
        $spec->coerceType($files['tmp_name']),
        $spec->coerceType($files['size']),
        $spec->coerceType($files['error']),
        $nullableSpec->coerceType($files['name'] ?? null),
        $nullableSpec->coerceType($files['type'] ?? null),
      );
    } catch (TypeAssert\TypeCoercionException $e) {
      return null;
    }
  }
}
