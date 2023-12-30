#!/bin/bash

### Script to generate wireguard config

directory="your_directory_path"

# Function to generate a user
generate_user() {
    read -p "Enter username: " user_var

    if [ -d "$directory/$user_var" ]; then
        echo -e "\033[0;31mUser already exists.\033[0m"
        echo -e "\033[0;31mNote: You may need to configure additional settings for the existing user.\033[0m\n"
        return
    fi

    read -p "Enter Client VPN IP: " address
    read -p "Enter DNS: " dns
    read -p "Peer Public Key: " peer_public_key
    read -p "Endpoint IP with Port: " endpoint 

    mkdir -p "$directory/$user_var"
    touch "$directory/$user_var/$user_var.keys"
    chmod 700 "$directory/$user_var/$user_var.keys"

    {
        echo 'Private Key'
        private_key=$(wg genkey)
        echo "$private_key"
        echo -e '\nPublic Key'
        public_key=$(echo "$private_key" | wg pubkey)
        echo "$public_key"
    } > "$directory/$user_var/$user_var.keys"

    allowed_ips="0.0.0.0/0"
    persistent_keepalive="10"
    config_file="$directory/$user_var/$user_var.conf"

    cat <<EOL > "$config_file"
[Interface]
PrivateKey = $private_key
Address = $address
DNS = $dns

[Peer]
PublicKey = $peer_public_key
AllowedIPs = $allowed_ips
Endpoint = $endpoint
PersistentKeepalive = $persistent_keepalive
EOL

    echo -e "\033[0;32mWireGuard configuration file created.\033[0m"
    echo -e "\033[0;32mGenerating QR code.\033[0m"
    qrencode -o "$directory/$user_var/$user_var.png" < "$config_file" && display "$directory/$user_var/$user_var.png" &
    echo -e "\n++-----------------------++\n"
}

# Function to remove a user
remove_user() {
    read -p "Enter username: " user_dir

    if [ -d "$directory/$user_dir/" ]; then
        rm -rf "$directory/$user_dir/"
        echo -e "\033[0;32mUser removed from the list.\033[0m"
        echo -e "\033[0;31mNote: You need to delete the user from the firewall.\033[0m\n"
    else
        echo -e "\033[0;34mUser does not exist.\033[0m\n"
    fi
}

# Function to search for a user
search_user() {
    read -p "Enter username: " user_name

    if [ -d "$directory/$user_name/" ]; then
        echo -e "\033[0;32mUser exists.\033[0m\n"
    else
        echo -e "\033[0;31mUser does not exist.\033[0m\n"
    fi
}

# Function to show QR code for a user
showqr_user() {
    read -p "Enter username: " qr_name

    if [ -d "$directory/$qr_name/" ]; then
        qrencode -o "$directory/$qr_name/$qr_name.png" < "$directory/$qr_name/$qr_name.conf" && display "$directory/$qr_name/$qr_name.png" &
	echo 
    else
        echo -e "\033[0;31mUser does not exist.\033[0m\n"
    fi
}

# Main function
main() {
    while true; do
        echo "Wireguard Config Generator"
        echo "++----------------------++"
        echo "What would you like to create"
        echo 
        echo "1: New User"
        echo "2: Delete User"
        echo "3: Search User"
        echo "4: Show QR"
        echo "5: Exit"
        echo 
        echo -n "Please choose an option: "
        read user_input

        case $user_input in
            1)
                generate_user
                ;;
            2)
                remove_user
                ;;
            3)
                search_user
                ;;
            4)
                showqr_user
                ;;
            5)
                echo "Exiting"
                exit 0
                ;;
            *)
                echo "Unrecognized option '$user_input'. Exiting..."
                exit 1
                ;;
        esac
    done
}

main "$@"

