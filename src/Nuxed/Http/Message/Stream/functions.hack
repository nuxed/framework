namespace Nuxed\Http\Message\Stream;

use namespace Nuxed\Filesystem;
use namespace Nuxed\Http\Message;

function file(
  Filesystem\File $file
): Message\IStream {
  return new Message\Stream(
    \fopen($file->path()->toString(), 'wb+', false)
  );
}
