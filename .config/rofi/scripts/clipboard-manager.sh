#!/usr/bin/env bash

# =============================================================================
# ROFI ADVANCED CLIPBOARD MANAGER
# Supports text and image clipboard history.
# =============================================================================

# --- CONFIGURATION ---

readonly KEY_DELETE="Alt+d"
readonly KEY_CLEAR="Alt+c"

readonly ROFI_THEME="$HOME/.config/rofi/themes/clipboard-manager.rasi"

# --- INITIALIZATION ---

# Close existing rofi instance.
pkill -x rofi 2>/dev/null || true


# --- RESTORE CLIPBOARD ---

restore_clipboard() {
    local selected="$1"
    local id
    local mime

    # Extract cliphist ID from the selected line.
    id="${selected%%$'\t'*}"

    [[ "$id" =~ ^[0-9]+$ ]] || return 1

    # Detect MIME from the decoded data.
    mime=$(cliphist decode "$id" | file --mime-type -b -)

    # Restore the clipboard with an appropriate MIME type.
    case "$mime" in
        image/png|image/jpeg|image/webp|image/gif|image/bmp|image/tiff)
            cliphist decode "$id" |
                wl-copy --type "$mime"
            ;;

        *)
            cliphist decode "$id" |
                wl-copy --type text/plain;charset=utf-8
            ;;
    esac
}


# --- MAIN LOOP ---

main() {
    local selected_line
    local rofi_exit

    while true; do

        selected_line=$(
            cliphist list |
                rofi \
                    -dmenu \
                    -i \
                    -p "Clipboard: " \
                    -theme "$ROFI_THEME" \
                    -no-ellipsize \
                    -mesg "Enter: Paste | ${KEY_DELETE}: Remove | ${KEY_CLEAR}: Clear All" \
                    -kb-custom-1 "$KEY_DELETE" \
                    -kb-custom-2 "$KEY_CLEAR"
        )

        rofi_exit=$?

        case "$rofi_exit" in

            0)
                [[ -z "$selected_line" ]] && break

                restore_clipboard "$selected_line"
                break
                ;;

            1)
                break
                ;;

            10)
                if [[ -n "$selected_line" ]]; then
                    printf '%s' "$selected_line" |
                        cliphist delete
                fi
                ;;

            11)
                cliphist wipe
                ;;

            *)
                break
                ;;
        esac

    done
}

main "$@"
