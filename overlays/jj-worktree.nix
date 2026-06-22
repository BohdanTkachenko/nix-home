{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "jj-worktree";
  version = "0.2.4";

  src = fetchFromGitHub {
    owner = "kawaz";
    repo = "jj-worktree";
    rev = "v${version}";
    hash = "sha256-gnezQ9P6syy5FXfLVuUS4ZmjnKojPYz8PFxw8XrRgSo=";
  };

  cargoHash = "sha256-rPmCpIZ3bm45ZNdPtpgTxQJQlV7fTlbvyXjORGaO1Ds=";

  # Integration tests drive real jj/git working copies, which the hermetic
  # build sandbox can't provide; the unit tests pass.
  doCheck = false;

  # Deliberately unwrapped: the shim shells out to `jj` and `git`, and we want
  # it to use whatever jj/git are on the caller's PATH (your configured ones),
  # not a version pinned here — it writes jj workspace metadata into your repo.
  # Consumers that strip PATH (e.g. the claude-code wrapper) pin the real git
  # via JJ_WORKTREE_REAL_GIT instead.

  meta = {
    description = "git-worktree → jj-workspace shim, so tools like Claude Code can use worktree isolation in a jj repo";
    homepage = "https://github.com/kawaz/jj-worktree";
    license = lib.licenses.mit;
    mainProgram = "jj-worktree";
    platforms = lib.platforms.unix;
  };
}
