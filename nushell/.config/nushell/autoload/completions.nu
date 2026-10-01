# Tab completion for external commands (git branches/flags, gh, docker, brew, adb, npm, ...).
# Nushell only completes its own commands, paths and custom defs; everything else goes through
# this external completer, backed by carapace (brew "carapace"). Commands carapace has no spec
# for borrow zsh/fish/bash completions through its bridges.

$env.CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense'

let carapace_completer = {|spans: list<string>|
  # Aliases (gco = git checkout): complete against the whole expansion, so `gco <TAB>` offers
  # branches, not git subcommands.
  let expansion = scope aliases | where name == $spans.0 | get -o 0.expansion
  let spans = if $expansion != null {
    $spans | skip 1 | prepend ($expansion | split row ' ' | where $it != '')
  } else { $spans }

  carapace $spans.0 nushell ...$spans
  | from json
  # carapace answers an unknown flag with an "...ERR" entry: fall back to nushell's own (files)
  | if ($in | default [] | where value =~ '^-.*ERR$' | is-empty) { $in } else { null }
}

if (which carapace | is-not-empty) {
  $env.config.completions.external.enable = true
  $env.config.completions.external.max_results = 200
  $env.config.completions.external.completer = $carapace_completer
}
