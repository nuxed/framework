namespace Nuxed\Io\Exception;

/**
 * Exception throw when trying to read or retrieve
 * a read handle of an unreadable file.
 */
class UnreadableFileException
  extends RuntimeException
  implements ExceptionInterface {}
