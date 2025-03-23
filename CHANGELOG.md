## Changelog

### [Unreleased]

- Fix gem load error by moving the entrypoint to the correct path.
- Support enabling/disabling all tasks in a namespace with a magic comment.
- Improve task search to allow more flexible and intuitive matching.

### [0.1.3] - 2025-03-22

- Change required Ruby version to 3.0.0.
- Add `DisableWithComment` rule to disable a specific task with a magic comment.

### [0.1.2] - 2025-03-22

- Update plugin registration for Sidekiq 7.3+ compatibility.

### [0.1.1] - 2025-02-25

- Add an environment confirmation input to the task enqueuing form.

### [0.1.0] - 2025-02-23

- Initial release.
