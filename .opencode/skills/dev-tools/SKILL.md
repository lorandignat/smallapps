---
name: Tools And Installs
description: Rules for installing SDKs, CLIs and dependencies as this user inside the project, logging every change in the local environment log, and keeping the environment reproducible. Use before any download, install or version bump.
---

# Tools and installs

The host is shared and you have no root. Everything must land in this folder, as
this user, and be documented.

## Allowed

- Project dependencies via the stack's own manager, in the project directory:
  `npm install <pkg>`, `flutter pub add`, `swift package add`.
- A user-local SDK or CLI unpacked into `.tooling/<name>/` (tarball, binary
  release, or a package manager with an explicit prefix).
- Read-only network access: documentation, package registries, release notes.

## Not allowed

- `sudo`, `su`, `apt-get install`, system package managers, anything in `/etc`,
  `/usr`, `/var`.
- Global installs: `npm -g`, `pip install` outside a venv, `brew`, `npx` for
  anything that writes to the home directory.
- Anything that runs a service, daemon, or opens a port.
- Browsers, editors, fonts, or utilities that no task asked for.
- Downloading a model, dataset, or binary larger than ~500 MB without saying so in
  the report first.

## Procedure for a new tool

1. Confirm a task actually needs it. If not, report "For the BA" and do not
   install.
2. Pin an exact version. No `latest`.
3. Install into `.tooling/<name>` or the project's dependency directory.
4. Verify it runs: `<tool> --version`.
5. Make it reachable without polluting the host: either use the absolute path
   from scripts, or, if a wrapper is unavoidable, keep it to one small file and
   say so.
6. Append to the local environment log (not published): date, name, exact
   version, how it was installed, where it lives, why, and how to undo it. No
   entry, no install.
7. If `.gitignore` does not already exclude it, fix that in the same task.

## Reproducibility

- Commit lockfiles.
- Record the install command in the environment-log entry so a fresh machine
  could repeat it.
- Prefer the smallest tool that does the job. If one package solves it, do not add
  a framework.
- If an install fails twice, stop and report `BLOCKED` with the exact error. Do
  not keep churning — the host may simply not allow it.
