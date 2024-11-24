#!/bin/sh

options=("Ubuntu" "Debian(Unsupported)" "Kaili_linux" "CentOS")
selected=0

# Function to show header
show_gg() {
  echo "#######################################################################################"
  echo "#                                                                                     #"
  echo "#                                      Proot INSTALLER                                #"
  echo "#                                                                                     #"
  echo "#                                    Copyright (C) 2024                               #"
  echo "#                                                                                     #"
  echo "#                                                                                     #"
  echo "#######################################################################################"
}

# Hide cursor function
hide_cursor() {
    echo -ne "\033[?25l"
}

# Show cursor function
show_cursor() {
    echo -ne "\033[?25h"
}

# Print menu function
print_menu() {
    # Don't clear the screen here. Just print the menu and options.
    clear # Clear the screen before printing the menu
    show_gg # Show the header
    echo "Use UP/DOWN arrow keys to navigate and press ENTER to select."
    for i in "${!options[@]}"; do
        if [ $i -eq $selected ]; then
            echo -e "\033[1m> ${options[$i]}\033[0m" # Bold the selected option
        else
            echo "  ${options[$i]}"
        fi
    done
}

# Initial header display
show_gg
trap show_cursor EXIT 
hide_cursor

# Main loop for user interaction
while true; do
    print_menu
    read -rsn1 key # Read one key at a time
    case "$key" in
        $'\x1b') # If ESC is pressed (escape sequence)
            read -rsn2 -t 0.1 key # Read next two characters
            case "$key" in
                "[A") # Arrow up
                    ((selected--))
                    if [ $selected -lt 0 ]; then
                        selected=$((${#options[@]} - 1)) # Wrap around to last option
                    fi
                    ;;
                "[B") # Arrow down
                    ((selected++))
                    if [ $selected -ge ${#options[@]} ]; then
                        selected=0 # Wrap around to the first option
                    fi
                    ;;
            esac
            ;;
        "") # Enter key
            show_cursor
            echo "You selected: ${options[$selected]}"  
            # Run the corresponding script based on the selection
            case $selected in
                0)
                    bash Ubuntu.sh
                    ;;
                1)
                    bash Debian.sh
                    ;;
                2)
                    bash Kaili_linux.sh
                    ;;
                3)
                    bash CentOS.sh
                    ;;
            esac
            break
            ;;
    esac
done
clear
