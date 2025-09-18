#!/bin/bash

# =============================================================================
# ROFI ADVANCED CLIPBOARD MANAGER (v8.0 - The Correct Approach)
#
# DATE: 2025-09-18
#
# This version implements the correct, intended workflow by using cliphist's
# native `copy` command, fully aligning with the user's insight. Rofi acts
# purely as a UI to select an item, and `cliphist` handles the entire
# copy/paste/delete lifecycle internally. This eliminates all issues with
# long text truncation and complex parsing.
#
# This is the simplest and most robust version.
# =============================================================================

# --- CONFIGURATION ---
readonly KEY_DELETE="Alt+d"
readonly KEY_CLEAR="Alt+c"


# --- MAIN LOGIC ---

main() {
    # The while loop allows for item deletion and immediate refresh of the list.
    while true; do
        # 1. ROFI AS A SIMPLE SELECTOR
        # Pipe the list directly to Rofi. Rofi's job is ONLY to return the
        # single line that the user chose.
        local selected_line
        selected_line=$(cliphist list | rofi -dmenu -i -p "Clipboard: " \
            -theme ~/.config/rofi/themes/clipboard-manager.rasi \
            -mesg "Enter: Paste | ${KEY_DELETE}: Remove | ${KEY_CLEAR}: Clear All" \
            -kb-custom-1 "${KEY_DELETE}" \
            -kb-custom-2 "${KEY_CLEAR}")
        local rofi_exit="$?"

        # 2. ACTION HANDLING
        case "$rofi_exit" in
            0)  # User pressed Enter: PASTE
                # --- THE CORRECT WAY ---
                # We pipe the selected line directly to `cliphist copy`.
                # `cliphist` itself handles extracting the ID, finding the
                # original full content, and copying it to the clipboard.
                # No parsing, no awk, no wl-copy needed here. It's atomic.
                echo "$selected_line" | cliphist copy

                # Action complete, exit the loop.
                break
                ;;

            1)  # User pressed Esc: CANCEL
                # Exit the loop.
                break
                ;;

            10) # User pressed custom key 1 (KEY_DELETE): DELETE ITEM
                # This logic has always been correct: pipe the selected
                # line to `cliphist delete`.
                echo "$selected_line" | cliphist delete

                # Do not break; loop again to show the updated list.
                ;;

            11) # User pressed custom key 2 (KEY_CLEAR): CLEAR ALL
                cliphist wipe

                # Do not break; loop again.
                ;;

            *)  # Any other exit code: UNEXPECTED
                # Exit as a safeguard.
                break
                ;;
        esac
    done
}

# --- SCRIPT ENTRY POINT ---
main "$@"
