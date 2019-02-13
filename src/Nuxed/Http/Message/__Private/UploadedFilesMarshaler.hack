namespace Nuxed\Http\Message\__Private;

use namespace HH\Lib\Str;
use namespace HH\Lib\C;
use namespace Nuxed\Http\Message\Exception;
use type Nuxed\Http\Message\Stream;
use type Nuxed\Http\Message\UploadedFile;
use type Nuxed\Contract\Http\Message\UploadedFileError;
use type Nuxed\Contract\Http\Message\UploadedFileInterface;
use function is_readable;
use function fopen;

type file_spec = shape(
  'tmp_name' => string,
  'size' => ?int,
  'error' => int,
  ?'name' => string,
  ?'type' => string,
  ...
);

class UploadedFilesMarshaler {
  public function marshal(
    KeyedContainer<string, mixed> $files,
  ): KeyedContainer<string, UploadedFileInterface> {
    $result = dict[];
    foreach ($files as $index_name => $file_entry) {
      if (!($file_entry is KeyedContainer<_, _>)) {
        continue;
      }

      /* HH_IGNORE_ERROR[2049] */
      /* HH_IGNORE_ERROR[4107] */
      if (\darray($file_entry) is file_spec) {
        /* HH_IGNORE_ERROR[2049] */
        /* HH_IGNORE_ERROR[4107] */
        $result[$index_name] = $this->createUploadedFile(\darray($file_entry));
      } else {
        /* HH_IGNORE_ERROR[4110] */
        $file_count = C\count($file_entry['tmp_name']);
        for ($i = 0; $i < $file_count; $i++) {
          $key = Str\format('%s[%d]', $index_name, $i);
          $result[$key] = $this->createUploadedFile(
            darray[
              /* HH_IGNORE_ERROR[4110] */
              /* HH_IGNORE_ERROR[4005] */
              'tmp_name' => $file_entry['tmp_name'][$i],
              /* HH_IGNORE_ERROR[4110] */
              /* HH_IGNORE_ERROR[4005] */
              'size' => $file_entry['size'][$i],
              /* HH_IGNORE_ERROR[4110] */
              /* HH_IGNORE_ERROR[4005] */
              'error' => $file_entry['error'][$i],
              /* HH_IGNORE_ERROR[4110] */
              /* HH_IGNORE_ERROR[4005] */
              'type' => $file_entry['type'][$i] ?? null,
              /* HH_IGNORE_ERROR[4110] */
              /* HH_IGNORE_ERROR[4005] */
              'name' => $file_entry['name'][$i] ?? null,
            ],
          );
        }
      }
    }

    return $result;
  }

  private function createUploadedFile(
    darray<arraykey, mixed> $fileSpec,
  ): UploadedFileInterface {
    if (!$fileSpec is file_spec) {
      throw new Exception\InvalidArgumentException(Str\format(
        '$fileSpec provided to %s MUST contain each of the keys "tmp_name", '.
        ' "size", and "error"; one or more were missing',
        __FUNCTION__,
      ));
    }

    $tmpName = $fileSpec['tmp_name'];

    if (!is_readable($tmpName)) {
      throw new Exception\InvalidArgumentException(
        Str\format('uploaded file "%s" is not readable', $fileSpec['tmp_name']),
      );
    }

    $stream = new Stream(fopen($tmpName, 'rb'));

    $error = $fileSpec['error'];

    if ($error > 8 || $error < 0) {
      throw new Exception\InvalidArgumentException(
        'Invalid error status for UploadedFile; must be an UPLOAD_ERR_* constant',
      );
    }

    $error = UploadedFileError::assert($error);

    return new UploadedFile(
      $stream,
      $fileSpec['size'],
      $error,
      $fileSpec['name'] ?? null,
      $fileSpec['type'] ?? null,
    );
  }
}
