function fish_greeting
    set -l img_dir "$HOME/.config/fish/greeting-imgs"
    if test -d "$img_dir"
        set -l img (ls $img_dir | shuf -n 1)
        fastfetch --logo "$img_dir/$img" --logo-type kitty --logo-width 35 --logo-height 15 --config "$HOME/.config/fish/fastfetch-greeting.jsonc"
    else
        fastfetch --config "$HOME/.config/fish/fastfetch-greeting.jsonc"
    end
end


if status is-interactive
    # Commands to run in interactive sessions can go here
end

set -U fish_key_bindings fish_default_key_bindings

# Uncomment the following lines to enable nvm and bun in fish
# nvm use latest > /dev/null
# set --export BUN_INSTALL "$HOME/.bun"
# set --export PATH $BUN_INSTALL/bin $PATH
