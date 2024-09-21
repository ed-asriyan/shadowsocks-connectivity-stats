#!/bin/bash
# usage: ./test.sh <SIP008 url> > ./result.csv

# references:
# https://chatgpt.com/share/86471f15-8c35-45e2-9f29-d5be350f21fa
# https://gist.github.com/fortuna/41848697f0be93b2c2e222cd83096fcb


SS_CONFIG_URL=$1

# Download JSON data from the URL
json_data=$(curl -s $SS_CONFIG_URL)

# List of URLs
schemas=(
    'https'
    'http'
)
URL="www.google.com"

# List of transport suffixes. read more https://www.reddit.com/r/outlinevpn/wiki/index/prefixing
transport_suffixes=(
    ''
    '?prefix=HTTP%2F1.1%20'
    '?prefix=%05%C3%9C_%C3%A0%01%20'
    '?prefix=%16%03%01%00%C2%A8%01%01'
    '?prefix=%13%03%03%3F'
    '?prefix=%16%03%03%40%00%02'
    '?prefix=SSH-2.0%0D%0A'
    '?prefix=RKN%20'
)

get_location_and_isp() {
    local target=$1
    local location
    local isp

    if [ -z "$target" ]; then
        location=$(curl -s ipinfo.io/city)
        isp=$(curl -s ipinfo.io/org)
    else
        if [[ $target =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            # If target is an IP address
            location=$(curl -s ipinfo.io/$target/city)
            isp=$(curl -s ipinfo.io/$target/org)
        else
            # If target is a domain name, resolve to IP first
            ip=$(dig +short $target | tail -n1)
            if [ -n "$ip" ]; then
                location=$(curl -s ipinfo.io/$ip/city)
                isp=$(curl -s ipinfo.io/$ip/org)
            else
                echo "Error: Unable to resolve domain to IP."
                return 1
            fi
        fi
    fi

    if [ $? -eq 0 ]; then
        echo "\"$location\",\"$isp\""
        return 0
    else
        return 1
    fi
}

get_average_ping() {
    local domain=$1
    local ping_count=10

    # Check if a domain name was provided
    if [ -z "$domain" ]; then
        echo "Error: No domain name provided."
        return 1
    fi

    # Perform the ping command and calculate average RTT
    local avg_ping
    avg_ping=$(ping -c "$ping_count" "$domain" | awk -F'/' '/^rtt/ {print $5}')

    # Check if avg_ping is empty, indicating a problem with the ping command
    if [ -z "$avg_ping" ]; then
        echo "Error: Unable to calculate average ping."
        return 1
    fi

    # Return the average ping value
    echo "$avg_ping"
}

test_ss_connectivity() {
    local method=$1
    local password=$2
    local server=$3
    local server_port=$4
    local transport_suffix=$5
    local url=$6

    sleep 1
    output="$(go run github.com/Jigsaw-Code/outline-sdk/x/examples/fetch@latest -transport ss://$method:$password@$server:$server_port$transport_suffix $url 2>&1 1>/dev/null)"
    exit_status=$?
    echo "$(echo $output | tr '\n' ' ')"
    return $exit_status
}

# Prepare the CSV header
echo "date,user-name,user-location,user-isp,hoster-name,hoster-ip,hoster-location,hoster-isp,ping,port,ss-query,schema,url,status,message"
today=$(date '+%Y-%m-%d')
my_location_and_isp=$(get_location_and_isp)


# Iterate over each server in the JSON
for server_info in $(echo "$json_data" | jq -r '.servers[] | @base64'); do
    _jq() {
        echo ${server_info} | base64 --decode | jq -r ${1}
    }

    method=$(_jq '.method')
    password=$(_jq '.password')
    server=$(_jq '.server')
    server_port=$(_jq '.server_port')

    ping=$(get_average_ping $server)

    server_location_and_isp=$(get_location_and_isp $server)

    # Iterate over each transport suffix
    for transport_suffix in "${transport_suffixes[@]}"; do
        # Iterate over each URL
        for schema in "${schemas[@]}"; do
            attempts=3
            ss_exit_status=1
            for ((i=1; i<=attempts; i++)); do
                ss_output="$(test_ss_connectivity $method $password $server $server_port "$transport_suffix" $schema://$URL)"
                ss_exit_status=$?
                if [ $ss_exit_status -eq 0 ]; then
                    break
                fi
            done

            if [ $ss_exit_status -ne 0 ]; then
                status="error"
            else
                status="ok"
            fi

            #    "date,user-name,user-location,user-isp,hoster-name,hoster-ip,hoster-location,hoster-isp,ping,port,ss-query,schema,url,status,message"
            echo "$today,,$my_location_and_isp,,$server,$server_location_and_isp,$ping,$server_port,$transport_suffix,$schema,$URL,$status,$ss_output"
        done
    done
done
