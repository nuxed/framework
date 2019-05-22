namespace Nuxed\Io\Exception;

/**
 * Exception throw when trying to read or retrieve
 * a read handle of an unreadable node.
 */
class UnreadableNodeException extends RuntimeException implements IException {}
