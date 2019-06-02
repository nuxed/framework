namespace Nuxed\Mercure;

/**
 * Represents an update to send to the hub.
 *
 * @see https://github.com/dunglas/mercure/blob/master/spec/mercure.md#hub
 * @see https://github.com/dunglas/mercure/blob/master/hub/update.go
 */
final class Update {
  public function __construct(
    private Container<string> $topics,
    private string $data,
    private Container<string> $targets = vec[],
    private ?string $id = null,
    private ?string $type = null,
    private ?int $retry = null,
  ) {}

  public function getTopics(): Container<string> {
    return $this->topics;
  }

  public function getData(): string {
    return $this->data;
  }

  public function getTargets(): Container<string> {
    return $this->targets;
  }

  public function getId(): ?string {
    return $this->id;
  }

  public function getType(): ?string {
    return $this->type;
  }

  public function getRetry(): ?int {
    return $this->retry;
  }
}
