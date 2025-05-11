## Changelog

### [Unreleased]

- Enable CI workflows on all branches. (#4)
- Add description to task list. (#2)
- Detect magic comment before multiline desc. (#3)
- Fix style tag rendering and plugin registration for Sidekiq Web UI 7.3+ and 8.0+. (#1)
- Enable horizontal scroll on tasks table for mobile. (#5)

### [0.1.5] - 2025-05-04

- Add duration, status and error reports to history.
- Fix Code Climate report by updating CI runner from `ubuntu-20.04` to `ubuntu-22.04`.

### [0.1.4] - 2025-03-23

- Fix gem load error by moving the entrypoint to the correct path.
- Support enabling/disabling all tasks in a namespace with a magic comment.
- Improve task search to allow more flexible and intuitive matching.
- Fix deprecation warning by avoiding direct access to `params` (Sidekiq 8 compatibility).

### [0.1.3] - 2025-03-22

- Change required Ruby version to 3.0.0.
- Add `DisableWithComment` rule to disable a specific task with a magic comment.

### [0.1.2] - 2025-03-22

- Update plugin registration for Sidekiq 7.3+ compatibility.

### [0.1.1] - 2025-02-25

- Add an environment confirmation input to the task enqueuing form.

### [0.1.0] - 2025-02-23

- Initial release.
