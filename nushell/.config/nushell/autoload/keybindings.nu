# Extra line-editor keys. config.nu sets edit_mode = "vi"; reedline's vi insert mode already has
# ctrl+a/ctrl+e/ctrl+w and ctrl+left/right, but not ctrl+u. kitty maps cmd+delete to ctrl+u
# (see kitty.conf), so bind it here: delete from the cursor to the start of the line.

$env.config.keybindings ++= [
  {
    name: cut_to_line_start
    modifier: control
    keycode: char_u
    mode: [emacs vi_insert]
    event: { edit: CutFromLineStart }
  }
]
