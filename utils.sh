#!/bin/bash

# Define file paths to store the last generated IDs
BOOK_ID_FILE="book_id.txt"
USER_ID_FILE="user_id.txt"

# Function to get the next Book ID
generate_book_id() {
    if [ ! -f "$BOOK_ID_FILE" ]; then
        echo 0 > "$BOOK_ID_FILE"  # Initialize the counter if the file doesn't exist
    fi
    
    # Read the current book ID counter
    book_counter=$(cat "$BOOK_ID_FILE")
    
    # Increment the counter
    next_book_id=$((book_counter + 1))
    
    # Save the updated counter
    echo "$next_book_id" > "$BOOK_ID_FILE"
    
    # Return the new book ID prefixed with 'B'
    echo "B$next_book_id"
}

# Function to get the next User ID
generate_user_id() {
    if [ ! -f "$USER_ID_FILE" ]; then
        echo 1 > "$USER_ID_FILE"  # Initialize the counter if the file doesn't exist
    fi
    
    # Read the current user ID counter
    user_counter=$(cat "$USER_ID_FILE")
    
    # Increment the counter
    next_user_id=$((user_counter + 1))
    
    # Save the updated counter
    echo "$next_user_id" > "$USER_ID_FILE"
    
    # Return the new user ID prefixed with 'U'
    echo "U$next_user_id"
}

# Log an action
log_action() {
    local action="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $action" >> logs.txt
}

