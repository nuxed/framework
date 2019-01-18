<?hh // strict

namespace Nuxed\Log\Handler;

use namespace HH\Lib\{C, Str, Dict};
use type Nuxed\Contract\Log\LogLevel;
use type Nuxed\Log\record;
use type Nuxed\Log\Exception\InvalidArgumentException;
use type DateTimeImmutable;
use function preg_match;
use function substr_count;
use function file_exists;
use function date;
use function pathinfo;
use function glob;
use function is_writable;
use function unlink;

class RotatingFileHandler extends StreamHandler {
  const string FILE_PER_DAY = 'Y-m-d';
  const string FILE_PER_MONTH = 'Y-m';
  const string FILE_PER_YEAR = 'Y';

  protected string $filename;
  protected int $maxFiles;
  protected ?bool $mustRotate = null;
  protected DateTimeImmutable $nextRotation;
  protected string $filenameFormat;
  protected string $dateFormat;

  /**
   * @param string     $filename
   * @param int        $maxFiles       The maximal amount of files to keep (0 means unlimited)
   * @param LogLevel   $level          The minimum logging level at which this handler will be triggered
   * @param bool       $bubble         Whether the messages that are handled can bubble up the stack or not
   * @param int|null   $filePermission Optional file permissions (default (0644) are only for owner read/write)
   * @param bool       $useLocking     Try to lock log file before doing any writes
   */
  <<__Override>>
  public function __construct(
    string $filename,
    int $maxFiles = 0,
    LogLevel $level = LogLevel::DEBUG,
    bool $bubble = true,
    ?int $filePermission = null,
    bool $useLocking = false,
  ) {
    $this->filename = $filename;
    $this->maxFiles = $maxFiles;
    $this->nextRotation = new DateTimeImmutable('tomorrow');
    $this->filenameFormat = '{filename}-{date}';
    $this->dateFormat = static::FILE_PER_DAY;

    parent::__construct(
      $this->getTimedFilename(),
      $level,
      $bubble,
      $filePermission,
      $useLocking,
    );
  }

  <<__Override>>
  public function close(): void {
    parent::close();

    if (true === $this->mustRotate) {
      $this->rotate();
    }
  }

  <<__Override>>
  public function reset(): void {
    parent::reset();

    if (true === $this->mustRotate) {
      $this->rotate();
    }
  }

  public function setFilenameFormat(
    string $filenameFormat,
    string $dateFormat,
  ): this {
    if (!preg_match('{^Y(([/_.-]?m)([/_.-]?d)?)?$}', $dateFormat)) {
      throw new InvalidArgumentException(
        'Invalid date format - format must be one of '.
        'RotatingFileHandler::FILE_PER_DAY ("Y-m-d"), RotatingFileHandler::FILE_PER_MONTH ("Y-m") '.
        'or RotatingFileHandler::FILE_PER_YEAR ("Y"), or you can set one of the '.
        'date formats using slashes, underscores and/or dots instead of dashes.',
      );
    }
    if (substr_count($filenameFormat, '{date}') === 0) {
      throw new InvalidArgumentException(
        'Invalid filename format - format must contain at least `{date}`, because otherwise rotating is impossible.',
      );
    }
    $this->filenameFormat = $filenameFormat;
    $this->dateFormat = $dateFormat;
    $this->url = $this->getTimedFilename();
    $this->close();

    return $this;
  }

  <<__Override>>
  protected function write(record $record): void {
    // on the first record written, if the log is new, we should rotate (once per day)
    if (null === $this->mustRotate) {
      $this->mustRotate = !file_exists($this->url);
    }

    if ($this->nextRotation <= $record['time']) {
      $this->mustRotate = true;
      $this->close();
    }

    parent::write($record);
  }

  private function rotate(): void {
    // update filename
    $this->url = $this->getTimedFilename();
    $this->nextRotation = new DateTimeImmutable('tomorrow');

    // skip GC of old logs if files are unlimited
    if (0 === $this->maxFiles) {
      return;
    }

    $logFiles = dict(glob($this->getGlobPattern()));

    if ($this->maxFiles >= C\count($logFiles)) {
      // no files to remove
      return;
    }

    // Sorting the files by name to remove the older ones
    $logFiles = Dict\take(
      Dict\reverse(Dict\sort(
        $logFiles,
        (string $a, string $b): int ==> Str\compare($b, $a),
      )),
      $this->maxFiles,
    );

    foreach ($logFiles as $file) {
      if (is_writable($file)) {
        // suppress errors here as unlink() might fail if two processes
        // are cleaning up/rotating at the same time
        @unlink($file);
      }
    }

    $this->mustRotate = false;
  }

  private function getTimedFilename(): string {
    $fileInfo = dict(pathinfo($this->filename));

    $timedFilename = Str\replace_every(
      $fileInfo['dirname'].'/'.$this->filenameFormat,
      dict[
        '{filename}' => $fileInfo['filename'],
        '{date}' => date($this->dateFormat),
      ],
    );

    if (
      C\contains_key($fileInfo, 'extension') && '' !== $fileInfo['extension']
    ) {
      $timedFilename .= '.'.$fileInfo['extension'];
    }

    return $timedFilename;
  }

  private function getGlobPattern(): string {
    $fileInfo = dict(pathinfo($this->filename));

    $glob = Str\replace_every(
      $fileInfo['dirname'].'/'.$this->filenameFormat,
      dict[
        '{filename}' => $fileInfo['filename'],
        '{date}' => '[0-9][0-9][0-9][0-9]*',
      ],
    );

    if (
      C\contains_key($fileInfo, 'extension') && '' !== $fileInfo['extension']
    ) {
      $glob .= '.'.$fileInfo['extension'];
    }

    return $glob;
  }
}
