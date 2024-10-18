#!/#!/bin/bash
#location: /usr/local/sbin/user_mngt

LOG_FILE="/var/log/user_mngt.log"

#Funktion för loggning
log_message() {
    local message="$1"
    echo "$message" | tee -a "$LOG_FILE"
}

#Kontrollera att ett filnamn anges och att filen existerar
if [[ "$#" -ne 1 || ! -f "$1" ]]; then
    echo "Error: Du måste ange en giltig CSV-fil som indata." >&2
    exit 1
fi

csv_file="$1"

#Läs CSV-filen rad för rad
while IFS=',' read -r first_name last_name password operation; do
    account_name="${first_name:0:3}${last_name:0:3}"

    if [[ "$operation" == "add" ]]; then
        # Kontrollera om användaren redan finns
        if id "$account_name" &>/dev/null; then
            echo "Error: Användaren $account_name finns redan." >&2
        else
            # Skapa användaren med hemkatalog
            useradd -m "$account_name" &>/dev/null
            if [[ $? -eq 0 ]]; then
                # Logga skapandet
                log_message "Add $account_name"

                # Sätta lösenord för användaren
                echo "$password" | passwd --stdin "$account_name" &>/dev/null
                if [[ $? -eq 0 ]]; then
                    # Logga och skriv ut meddelandet
                    log_message "Setting password for $account_name"
                    echo "Setting password for $account_name"
                else
                    echo "Error: Misslyckades med att sätta lösenord för $account_name." >&2
                fi
            else
                echo "Error: Misslyckades med att lägga till användaren $account_name." >&2
            fi
        fi

    elif [[ "$operation" == "remove" ]]; then
        # Kontrollera om användaren finns
        if id "$account_name" &>/dev/null; then
            # Ta bort användaren och hemkatalogen
            deluser --remove-home "$account_name" &>/dev/null
            if [[ $? -eq 0 ]]; then
                log_message "Remove $account_name"
            else
                echo "Error: Misslyckades med att ta bort användaren $account_name." >&2
            fi
        else
            echo "Error: Användaren $account_name finns inte." >&2
        fi
    else
        echo "Error: Ogiltig operation '$operation' för $account_name." >&2
    fi

done < "$csv_file"