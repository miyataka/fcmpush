# GitHub Actions dependency lockfile

Existing workflows and the lockfile verification workflow are covered by
`.github/workflows/actions.lock`. The lockfile records exact commits and
source repository identities, including transitive action dependencies.

After adding a workflow or changing an action reference, regenerate with:

```sh
gh extension install github/gh-actions-lock --pin v0.4.0
gh actions-lock --no-narrow
gh actions-lock --verify
```

Review changed commits and repository identities before committing the
workflows and lockfile together. Existing action version references are kept
as written. GitHub Actions Dependabot updates run weekly as one group and
maintain lockfile entries for onboarded workflows.

A moved branch or major tag does not automatically update the locked commit.
Review the upstream change, then use `gh actions-lock --relock --no-narrow`.
Do not use `--accept-moved` in automation or edit the lockfile by hand.

This covers action code, not service/container images, runner images,
packages installed by scripts, or external reusable workflow calls. The latter
require explicit SHA pins and a lockfile in their source repository.
Local `./` actions use the checked-out workspace and are not locked.

The verification job checks consistency and provenance with read-only
repository permissions. It does not prove the locked actions are safe and
does not execute application tests or deployment scripts.

Docs: https://docs.github.com/en/actions/concepts/security/workflow-dependency-lockfiles
