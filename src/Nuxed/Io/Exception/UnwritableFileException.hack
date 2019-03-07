namespace Nuxed\Io\Exception;

/**
 * Exception throw when trying to write or retrieve
 * a write handle of an unwritable file.
 */
class UnwritableFileException
  extends RuntimeException
  implements ExceptionInterface {}
