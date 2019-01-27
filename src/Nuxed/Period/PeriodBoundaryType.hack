namespace Nuxed\Period;

enum PeriodBoundaryType: string {
  INCLUDE_START_EXCLUDE_END = '[)';
  EXCLUDE_START_INCLUDE_END = '(]';
  EXCLUDE_ALL = '()';
  INCLUDE_ALL = '[]';
}
