namespace Nuxed\Http\Session;

enum CacheLimiter: string {
  NOCACHE = 'nocache';
  PUBLIC = 'public';
  PRIVATE = 'private';
  PRIVATE_NO_EXPIRE = 'private_no_expire';
}
