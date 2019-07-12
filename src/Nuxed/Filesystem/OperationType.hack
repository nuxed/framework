namespace Nuxed\Filesystem;

enum OperationType: int {
  /*
   * Will overwrite the destination file if one exists (file and folder)
   */
  OVERWRITE = 0;

  /*
   * Will merge folders together if they exist at the same location (folder only)
   */
  MERGE = 1;

  /*
   * Will not overwrite the destination file if it exists (file and folder)
   */
  SKIP = 2;
}
