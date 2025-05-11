#!/bin/bash

source utils.sh

# Function to add a new user
add_user() {
    local name email
    name=$(whiptail --inputbox "Enter User Name:" 10 60 3>&1 1>&2 2>&3) || return
    [ -z "$name" ] && whiptail --msgbox "Name cannot be empty!" 8 40 && return

    email=$(whiptail --inputbox "Enter User Email:" 10 60 3>&1 1>&2 2>&3) || return
    [ -z "$email" ] && whiptail --msgbox "Email cannot be empty!" 8 40 && return

    user_id=$(generate_user_id)

    echo "$user_id|$name|$email" >> users.txt
    log_action "Added User: [$user_id] $name"

    whiptail --msgbox "User added successfully!\n\nID: $user_id" 10 60
}

# Function to view all users
view_users() {
    if [ ! -s users.txt ]; then
        whiptail --msgbox "No users found!" 8 40
        return
    fi

    user_list=$(awk -F '|' '{print "ID: " $1 "\nName: " $2 "\nEmail: " $3 "\n\n"}' users.txt)
    whiptail --title "📋 All Users" --scrolltext --msgbox "$user_list" 20 60
}

# Function to delete a user
delete_user() {
    local user_id
    user_id=$(whiptail --inputbox "Enter User ID to Delete:" 10 60 3>&1 1>&2 2>&3) || return
    [ -z "$user_id" ] && whiptail --msgbox "User ID cannot be empty!" 8 40 && return

    if ! grep -q "^$user_id|" users.txt; then
        whiptail --msgbox "User with ID $user_id not found!" 8 40
        return
    fi

    sed -i "/^$user_id|/d" users.txt
    log_action "Deleted User: [$user_id]"

    whiptail --msgbox "User deleted successfully!" 8 40
}

# Function to update a user's details
update_user() {
    local user_id name email old_name old_email

    user_id=$(whiptail --inputbox "Enter User ID to Update:" 10 60 3>&1 1>&2 2>&3) || return
    [ -z "$user_id" ] && whiptail --msgbox "User ID cannot be empty!" 8 40 && return

    if ! grep -q "^$user_id|" users.txt; then
        whiptail --msgbox "User with ID $user_id not found!" 8 40
        return
    fi

    old_name=$(awk -F '|' -v id="$user_id" '$1 == id {print $2}' users.txt)
    old_email=$(awk -F '|' -v id="$user_id" '$1 == id {print $3}' users.txt)

    name=$(whiptail --inputbox "Enter New Name (leave empty to keep: $old_name):" 10 60 "$old_name" 3>&1 1>&2 2>&3) || return
    [ -z "$name" ] && name="$old_name"

    email=$(whiptail --inputbox "Enter New Email (leave empty to keep: $old_email):" 10 60 "$old_email" 3>&1 1>&2 2>&3) || return
    [ -z "$email" ] && email="$old_email"

    sed -i "s/^$user_id|.*|.*/$user_id|$name|$email/" users.txt
    log_action "Updated User: [$user_id] $name"

    whiptail --msgbox "User updated successfully!" 8 40
}

# Function to search users
search_users() {
    local query
    query=$(whiptail --inputbox "Enter search query (name or email):" 10 60 3>&1 1>&2 2>&3) || return
    [ -z "$query" ] && whiptail --msgbox "Search query cannot be empty!" 8 40 && return

    results=$(grep -i "$query" users.txt)
    if [ -z "$results" ]; then
        whiptail --msgbox "No users found matching '$query'." 8 40
        return
    fi

    formatted_results=$(echo "$results" | awk -F '|' '{print "ID: " $1 "\nName: " $2 "\nEmail: " $3 "\n\n"}')
    whiptail --title "🔍 Search Results" --scrolltext --msgbox "$formatted_results" 20 60
}

# Function to sort users
sort_users() {
    if [ ! -s users.txt ]; then
        whiptail --msgbox "No users found to sort!" 8 40
        return
    fi

    sort_choice=$(whiptail --title "🔃 Sort Users" --menu "Sort users by:" 15 50 4 \
        "1" "ID (Ascending)" \
        "2" "Name (Alphabetical)" 3>&1 1>&2 2>&3)

    case $sort_choice in
        1)
            sorted=$(sort -t '|' -k1n users.txt)
            ;;
        2)
            sorted=$(sort -t '|' -k2,2 users.txt)
            ;;
        *)
            return
            ;;
    esac

    formatted=$(echo "$sorted" | awk -F '|' '{print "ID: " $1 "\nName: " $2 "\nEmail: " $3 "\n\n"}')
    whiptail --title "📊 Sorted Users" --scrolltext --msgbox "$formatted" 20 60
}

# User Management Menu
while true; do
    choice=$(whiptail --title "👥 User Management" --menu "Choose an option" 20 60 10 \
        "1" " Add User" \
        "2" " View All Users" \
        "3" " Delete User" \
        "4" " Update User" \
        "5" " Search Users" \
        "6" " Sort Users" \
        "7" " Back to Main Menu" 3>&1 1>&2 2>&3)

    exitstatus=$?
    if [ $exitstatus -ne 0 ]; then break; fi

    case $choice in
        1) add_user ;;
        2) view_users ;;
        3) delete_user ;;
        4) update_user ;;
        5) search_users ;;
        6) sort_users ;;
        7) break ;;
    esac
done

