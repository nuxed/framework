namespace Nuxed\Log\Handler;

use const LOG_AUTH;
use const LOG_AUTHPRIV;
use const LOG_CRON;
use const LOG_DAEMON;
use const LOG_KERN;
use const LOG_LPR;
use const LOG_MAIL;
use const LOG_NEWS;
use const LOG_SYSLOG;
use const LOG_USER;
use const LOG_UUCP;
use const LOG_LOCAL0;
use const LOG_LOCAL1;
use const LOG_LOCAL2;
use const LOG_LOCAL3;
use const LOG_LOCAL4;
use const LOG_LOCAL5;
use const LOG_LOCAL6;
use const LOG_LOCAL7;

enum SysLogFacility: int {
  AUTH = LOG_AUTH;
  AUTHPRIV = LOG_AUTHPRIV;
  CRON = LOG_CRON;
  DAEMON = LOG_DAEMON;
  KERN = LOG_KERN;
  LPR = LOG_LPR;
  MAIL = LOG_MAIL;
  NEWS = LOG_NEWS;
  SYSLOG = LOG_SYSLOG;
  USER = LOG_USER;
  UUCP = LOG_UUCP;
  LOCAL0 = LOG_LOCAL0;
  LOCAL1 = LOG_LOCAL1;
  LOCAL2 = LOG_LOCAL2;
  LOCAL3 = LOG_LOCAL3;
  LOCAL4 = LOG_LOCAL4;
  LOCAL5 = LOG_LOCAL5;
  LOCAL6 = LOG_LOCAL6;
  LOCAL7 = LOG_LOCAL7;
}
