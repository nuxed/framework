namespace Nuxed\Contract\Http\Message;

enum UploadedFileError: int {
  ERROR_OK = 0;
  ERROR_EXCEEDS_MAX_INI_SIZE = 1;
  ERROR_EXCEEDS_MAX_FORM_SIZE = 2;
  ERROR_INCOMPLETE = 3;
  ERROR_NO_FILE = 4;
  ERROR_TMP_DIR_NOT_SPECIFIED = 6;
  ERROR_TMP_DIR_NOT_WRITEABLE = 7;
  ERROR_CANCELED_BY_EXTENSION = 8;
}
