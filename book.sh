#!/bin/bash

source utils.sh

# Function to add a new book
add_book() {
    local title author

    whiptail --title " Add a New Book" --msgbox "Please enter the details of the new book." 10 60

    while true; do
        title=$(whiptail --inputbox "Enter Book Title:" 10 60 3>&1 1>&2 2>&3) || return
        if [ -z "$title" ]; then
            whiptail --msgbox "Title cannot be empty!" 8 40
        else
            break
        fi
    done

    while true; do
        author=$(whiptail --inputbox "Enter Author Name:" 10 60 3>&1 1>&2 2>&3) || return
        if [ -z "$author" ]; then
            whiptail --msgbox "Author name cannot be empty!" 8 40
        else
            break
        fi
    done

    book_id=$(generate_book_id)
    status="available"

    echo "$book_id|$title|$author|$status" >> books.txt
    log_action "Added Book: [$book_id] $title by $author"
    whiptail --msgbox "Book added successfully!\n\nID: $book_id" 10 60
}

# Function to view all books
view_books() {
    if [ ! -s books.txt ]; then
        whiptail --msgbox "No books available!" 8 40
        return
    fi

    books_list=$(awk -F '|' '{print "ID: " $1 "\nTitle: " $2 "\nAuthor: " $3 "\nStatus: " $4 "\n\n"}' books.txt)
    whiptail --title " All Books" --scrolltext --msgbox "$books_list" 20 60
}

# Function to delete a book
delete_book() {
    local book_id
    while true; do
        book_id=$(whiptail --inputbox "Enter Book ID to Delete:" 10 60 3>&1 1>&2 2>&3) || return
        if [ -z "$book_id" ]; then
            whiptail --msgbox "Book ID cannot be empty!" 8 40
        else
            break
        fi
    done

    if ! grep -q "^$book_id|" books.txt; then
        whiptail --msgbox "Book with ID $book_id not found!" 8 40
        return
    fi

    sed -i "/^$book_id|/d" books.txt
    log_action "Deleted Book: [$book_id]"
    whiptail --msgbox "Book deleted successfully!" 8 40
}

# Function to update a book's details
update_book() {
    local book_id title author status old_title old_author

    while true; do
        book_id=$(whiptail --inputbox "Enter Book ID to Update:" 10 60 3>&1 1>&2 2>&3) || return
        if [ -z "$book_id" ]; then
            whiptail --msgbox "Book ID cannot be empty!" 8 40
        else
            break
        fi
    done

    if ! grep -q "^$book_id|" books.txt; then
        whiptail --msgbox "Book with ID $book_id not found!" 8 40
        return
    fi

    old_title=$(awk -F '|' -v id="$book_id" '$1 == id {print $2}' books.txt)
    old_author=$(awk -F '|' -v id="$book_id" '$1 == id {print $3}' books.txt)

    while true; do
        title=$(whiptail --inputbox "Enter New Title (leave empty to keep: $old_title):" 10 60 "$old_title" 3>&1 1>&2 2>&3) || return
        if [ -z "$title" ]; then
            whiptail --msgbox "Title cannot be left empty!" 8 40
        else
            break
        fi
    done

    while true; do
        author=$(whiptail --inputbox "Enter New Author (leave empty to keep: $old_author):" 10 60 "$old_author" 3>&1 1>&2 2>&3) || return
        if [ -z "$author" ]; then
            whiptail --msgbox "Author cannot be left empty!" 8 40
        else
            break
        fi
    done

    status="available"

    sed -i "s/^$book_id|.*|.*|.*/$book_id|$title|$author|$status/" books.txt
    log_action "Updated Book: [$book_id] $title by $author"
    whiptail --msgbox "Book updated successfully!" 8 40
}

# Function to search for books
search_books() {
    local query
    while true; do
        query=$(whiptail --inputbox "Enter search query (title or author):" 10 60 3>&1 1>&2 2>&3) || return
        if [ -z "$query" ]; then
            whiptail --msgbox "Search query cannot be empty!" 8 40
        else
            break
        fi
    done

    results=$(grep -i "$query" books.txt)
    if [ -z "$results" ]; then
        whiptail --msgbox "No books found matching '$query'." 8 40
        return
    fi

    formatted_results=$(echo "$results" | awk -F '|' '{print "ID: " $1 "\nTitle: " $2 "\nAuthor: " $3 "\nStatus: " $4 "\n\n"}')
    whiptail --title " Search Results" --scrolltext --msgbox "$formatted_results" 20 60
}

# Function to sort books
sort_books() {
    choice=$(whiptail --title " Sort Books" --menu "Choose sorting criteria" 15 60 6 \
        "1" "Sort by Title" \
        "2" "Sort by Author" \
        "3" "Sort by ID" \
        "4" "Sort by Status" 3>&1 1>&2 2>&3)

    exitstatus=$?
    if [ $exitstatus -ne 0 ]; then return; fi

    case $choice in
        1) sorted_books=$(sort -t'|' -k2 books.txt) ;;
        2) sorted_books=$(sort -t'|' -k3 books.txt) ;;
        3) sorted_books=$(sort -t'|' -k1 books.txt) ;;
        4) sorted_books=$(sort -t'|' -k4 books.txt) ;;
    esac

    if [ -z "$sorted_books" ]; then
        whiptail --msgbox "No books available to sort!" 8 40
        return
    fi

    formatted_books=$(echo "$sorted_books" | awk -F '|' '{print "ID: " $1 "\nTitle: " $2 "\nAuthor: " $3 "\nStatus: " $4 "\n\n"}')
    whiptail --title " Sorted Books" --scrolltext --msgbox "$formatted_books" 20 60
}

issue_book() {
    # Prompt for user ID and book ID
    user_id=$(whiptail --title "Issue Book" --inputbox "Enter User ID:" 10 60 3>&1 1>&2 2>&3)

    # Check if the user exists
    if ! grep -q "^$user_id|" users.txt; then
        whiptail --title "Error" --msgbox "User ID $user_id not found." 10 60
        return
    fi

    book_id=$(whiptail --title "Issue Book" --inputbox "Enter Book ID to Issue:" 10 60 3>&1 1>&2 2>&3)

    # Check if the book exists
    book_entry=$(grep "^$book_id|" books.txt)
    if [[ -z "$book_entry" ]]; then
        whiptail --title "Error" --msgbox "Book ID not found." 10 60
        return
    fi

    # Get the availability status of the book
    availability=$(echo "$book_entry" | cut -d'|' -f4)

    # Check if the book is already issued
    if [[ "$availability" == "issued" ]]; then
        # Check if the book has been issued to the current user
        if grep -q "$user_id|$book_id" issued_books.txt; then
            whiptail --title "Error" --msgbox "Book $book_id is already issued to this user." 10 60
            return
        fi
        whiptail --title "Error" --msgbox "The book is already issued to another user." 10 60
        return
    fi

    # Update the book availability to "issued"
    sed -i "s/^$book_id|.*/$book_id|$(echo "$book_entry" | cut -d'|' -f2-3)|issued/" books.txt

    # Record the book issue for the user
    echo "$user_id|$book_id" >> issued_books.txt

    # Notify the user
    whiptail --title "Book Issued" --msgbox "Book $book_id has been issued to User $user_id." 10 60
}


return_book() {
    # Prompt for user ID and book ID
    user_id=$(whiptail --title "Return Book" --inputbox "Enter User ID:" 10 60 3>&1 1>&2 2>&3)
    book_id=$(whiptail --title "Return Book" --inputbox "Enter Book ID to Return:" 10 60 3>&1 1>&2 2>&3)

    # Check if the user exists
    user_exists=$(grep "^$user_id|" users.txt)
    if [[ -z "$user_exists" ]]; then
        whiptail --title "Error" --msgbox "User ID not found." 10 60
        return
    fi

    # Check if the book exists
    book_entry=$(grep "^$book_id|" books.txt)
    if [[ -z "$book_entry" ]]; then
        whiptail --title "Error" --msgbox "Book ID not found." 10 60
        return
    fi

    # Check if the book is actually issued to this user
    issued_entry=$(grep "^$user_id|$book_id$" issued_books.txt)
    if [[ -z "$issued_entry" ]]; then
        whiptail --title "Error" --msgbox "This book was not issued to the specified user." 10 60
        return
    fi

    # Update the book availability to "available"
    sed -i "s/^$book_id|.*/$book_id|$(echo "$book_entry" | cut -d'|' -f2-3)|available/" books.txt

    # Remove the user and book entry from issued_books
    sed -i "/^$user_id|$book_id$/d" issued_books.txt

    # Notify the user
    whiptail --title "Book Returned" --msgbox "Book $book_id has been returned by User $user_id." 10 60
}


view_issued_books() {
    if [ ! -s issued_books.txt ]; then
        whiptail --title "Issued Books" --scrolltext --msgbox "No books are currently issued." 10 60
        return
    fi

    display=""

    while IFS='|' read -r user_id book_id; do
        user_line=$(grep "^$user_id|" users.txt)
        book_line=$(grep "^$book_id|" books.txt)

        if [ -n "$user_line" ] && [ -n "$book_line" ]; then
            user_name=$(echo "$user_line" | cut -d'|' -f2)
            book_title=$(echo "$book_line" | cut -d'|' -f2)
            book_author=$(echo "$book_line" | cut -d'|' -f3)

            display+="User: $user_name (ID: $user_id)\n  -> Book: $book_title by $book_author (ID: $book_id)\n\n"
        fi
    done < issued_books.txt

    whiptail --title "📚 Issued Books with Users" --msgbox "$display" 25 70
}



# Book Management Menu
while true; do
    choice=$(whiptail --title "📘 Book Management" --menu "Choose an option:" 20 60 10 \
        "1" " Add Book" \
        "2" " View All Books" \
        "3" " Delete Book" \
        "4" " Update Book" \
        "5" " Search Books" \
        "6" " Sort Books" \
        "7" " Issue Book" \
        "8" " Return Book" \
        "9" " View Issued Books" \
        "10" " Back to Main Menu" 3>&1 1>&2 2>&3)

    exitstatus=$?
    if [ $exitstatus -ne 0 ]; then break; fi

    case $choice in
        1) add_book ;;
        2) view_books ;;
        3) delete_book ;;
        4) update_book ;;
        5) search_books ;;
        6) sort_books ;;
        7) issue_book ;;
        8) return_book ;;
        9) view_issued_books ;;
        10) break ;;
    esac
done

