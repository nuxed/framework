namespace Nuxed\Filesystem\Exception;

/**
 * Exception throw when trying to write or retrieve
 * a write handle of an unwritable node.
 */
class UnwritableNodeException extends RuntimeException implements IException {}
