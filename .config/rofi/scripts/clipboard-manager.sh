#!/bin/bash

killall -SIGTERM rofi &> /dev/null

# =============================================================================
# ROFI ADVANCED CLIPBOARD MANAGER
#
# DATE: 2025-09-22
#
# This version implements the canonical, officially endorsed workflow by using
# `cliphist decode` piped to `wl-copy`. This approach correctly separates
# the decoding of a history item from the action of placing it onto the
# live clipboard, resolving all observed inconsistencies.
# =============================================================================

# --- CONFIGURATION ---
readonly KEY_DELETE="Alt+d"
readonly KEY_CLEAR="Alt+c"


# --- MAIN LOGIC ---

main() {
    # The while loop allows for item deletion and immediate refresh of the list.
    while true; do
        # 1. ROFI AS A SIMPLE SELECTOR
        # Add '-no-ellipsize' to ensure rofi always returns the full line,
        # preventing truncation issues with long entries.
        local selected_line
        selected_line=$(cliphist list | rofi -dmenu -i -p "Clipboard: " \
            -theme ~/.config/rofi/themes/clipboard-manager.rasi \
            -no-ellipsize \
            -mesg "Enter: Paste | ${KEY_DELETE}: Remove | ${KEY_CLEAR}: Clear All" \
            -kb-custom-1 "${KEY_DELETE}" \
            -kb-custom-2 "${KEY_CLEAR}")
        local rofi_exit="$?"

        # 2. ACTION HANDLING
        case "$rofi_exit" in
            0)  # User pressed Enter: PASTE
                if [[ -z "$selected_line" ]]; then
                    break
                fi

                # --- THE CANONICAL WAY ---
                # 1. Pipe the selected line to `cliphist decode`.
                #    `decode` correctly parses the "ID<TAB>Content" format,
                #    retrieves the full original entry, and prints it to stdout.
                # 2. Pipe the raw content from `decode` to `wl-copy`.
                #    `wl-copy` takes this raw content and places it on the clipboard.
                printf "%s" "$selected_line" | cliphist decode | wl-copy

                # Action complete, exit the loop.
                break
                ;;

            1)  # User pressed Esc: CANCEL
                break
                ;;

            10) # User pressed custom key 1 (KEY_DELETE): DELETE ITEM
                # The delete command works as expected with the full line.
                if [[ -n "$selected_line" ]]; then
                    printf "%s" "$selected_line" | cliphist delete
                fi
                # Do not break; loop again to show the updated list.
                ;;

            11) # User pressed custom key 2 (KEY_CLEAR): CLEAR ALL
                cliphist wipe
                # Do not break; loop again.
                ;;

            *)  # Any other exit code: UNEXPECTED
                break
                ;;
        esac
    done
}

# --- SCRIPT ENTRY POINT ---
main "$@"
