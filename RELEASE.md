Polkadot Release Process
------------------------

### Branches
* release-candidate branch: The branch used for staging of the next release.
  Named like `release-v0.8.26`
* substrate + grandpa-bridge-gadget release branches: These branches are
  targetted by the release-candidate branch. They are created in the first
  stage of the release process.
  .Named like `polkadot-v0.8.26`.

### Notes
* The release-candidate branch *must* be made in the paritytech/polkadot repo in
order for release automation to work correctly
* Any new pushes/merges to the release-candidate branch after the initial `rc-1`
  (for example, refs/heads/release-v0.8.26) will result in the rc index being
  bumped (e.g., v0.8.26-rc1 to v0.8.26-rc2) and new wasms built.

### Release workflow

Below are the steps of the release workflow. Steps prefixed with NOACTION are
automated and require no human action.

1. To initiate the release process, run the `start-release-process.sh` script located in `/scripts`: `./scripts/start-release-process.sh v0.8.26`. This will:
    - Prepare branches in polkadot, substrate + grandpa-bridge-gadget repositories for the release.
    - A new Github issue is created containing a checklist of manual steps to be completed before we are confident with the release. This will be linked in matrix.
2. NOACTION: The current HEAD of the release-candidate branch is tagged `v0.8.26-rc1`
3. NOACTION: A draft release and runtime WASMs are created for this
  release-candidate automatically. A link to the draft release will be linked in
  the internal polkadot matrix channel.
5. Complete the steps in the issue created in step 1, signing them off as
  completed
6. (optional) If a fix is required to the release-candidate:
  1. Merge the fix with `master` first
  2. Cherry-pick the commit from `master` to `release-v0.8.26`, fixing any
  merge conflicts. Try to avoid unnecessarily bumping crates. If the fix is required in substrate, cherry-pick the fix to its `polkadot-v0.8.26` branch.
  3. Push the release-candidate branch to Github - this is now the new release-
  candidate
  4. Depending on the cherry-picked changes, it may be necessary to perform some
  or all of the manual tests again.
7. Once happy with the release-candidate, tag the head of the release-candidate
  branch: `git tag -s -m 'v0.8.26' v0.8.26; git push --tags`. This will create
  a draft release much like the release-candidates.
  TODO: Add cleanroom explanation here

### Security releases

Occasionally there may be changes that need to be made to the most recently
released version of Polkadot, without taking *every* change to `master` since
the last release. For example, in the event of a security vulnerability being
found, where releasing a fixed version is a matter of some expediency. In cases
like this, the fix should first be merged with master, cherry-picked to a branch
forked from `release`, tested, and then finally merged with `release`. A
sensible versioning scheme for changes like this is `vX.Y.Z-1`.
