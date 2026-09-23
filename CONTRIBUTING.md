# Contributing to NetHUD

Thanks for your interest! NetHUD is a small app with a deliberately tiny scope,
so before opening a PR for a new feature, please open an issue first to discuss it.

## Branching

Development happens on the **`dev`** branch — it should always build and run.
`main` receives merges from `dev` and is where release tags are cut. PRs
target `dev`.

## Development setup

```bash
git clone https://github.com/HamzaSamirAmmar/nethud.git
cd nethud
xcodegen generate          # regenerates NetHUD.xcodeproj (requires: brew install xcodegen)
open NetHUD.xcodeproj      # then Cmd+R
```

Requirements: macOS 13+, Xcode 14+.

## Guidelines

- Keep the app small and dependency-free — no third-party packages.
- Match the existing Swift style; no formatting pipeline is configured.
- Bug fixes and small improvements: just open a PR describing the change.
- If you bump `MARKETING_VERSION` in `project.yml`, add a `CHANGELOG.md` entry.

## Releasing (maintainers)

> `main` is protected — it only accepts changes via pull request. `dev` allows
> direct pushes from the maintainer but no force-pushes or deletions.

1. Open a PR from `dev` into `main` (or via CLI):
   `gh pr create --base main --head dev --fill`
2. Merge it (CI runs on the PR; no approvals required for solo merges)
3. On `main`: update `MARKETING_VERSION` + `CHANGELOG.md` via a small PR
   (or bump the version on `dev` before step 1)
4. Tag the release: `git tag vX.Y.Z && git push origin vX.Y.Z` — tags are not
   blocked by branch protection; CI builds and publishes the Release
5. Update the Homebrew cask with the new version + SHA256
