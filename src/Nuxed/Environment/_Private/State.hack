namespace Nuxed\Environment\_Private;

enum State: int {
  INITIAL = 0;
  UNQUOTED = 1;
  QUOTED = 2;
  ESCAPE = 3;
  WHITESPACE = 4;
  COMMENT = 5;
}
