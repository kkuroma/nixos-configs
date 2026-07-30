# One file per configured program (enable + config; self-installs).
# Install-only packages live in home/packages.nix, not here.
{ imports = import ../../lib/import-dir.nix ./.; }
