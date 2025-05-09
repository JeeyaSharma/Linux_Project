#!/bin/bash

# Ensure required data and log files exist
touch books.txt users.txt logs.txt

# Source utilities
source utils.sh

# Main loop
while true; do
    CHOICE=$(whiptail --title "📚 Library Management System" --menu "Choose an option" 20 60 10 \
    "1" "📘 Book Management" \
    "2" "👤 User Management" \
    "3" "🚪 Exit" 3>&1 1>&2 2>&3)

    exitstatus=$?
    if [ $exitstatus -ne 0 ]; then
        clear
        echo "Exiting Library Management System..."
        break
    fi

    case $CHOICE in
        1) bash book.sh ;;
        2) bash user.sh ;;
        3) clear; echo "Goodbye!"; break ;;
    esac
done

