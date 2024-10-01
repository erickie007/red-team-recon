#!/bin/bash

# Eric's custom enumeration tool

# Colors to use

RED="\e[31m"
GREEN="\e[32m"
ORANGE="\e[38;5;208m"
ENDCOLOR="\e[0m"

# Introduction

# Function to display ANSI art
display_art() {
    # Set text color to green (ANSI escape code for green is \e[32m)
    echo -e "\e[32m"

    # Display ASCII art
    cat << "EOF"
 ____          _   _____                      ____                      
|  _ \ ___  __| | |_   _|__  __ _ _ __ ___   |  _ \ ___  ___ ___  _ __  
| |_) / _ \/ _` |   | |/ _ \/ _` | '_ ` _ \  | |_) / _ \/ __/ _ \| '_ \ 
|  _ <  __/ (_| |   | |  __/ (_| | | | | | | |  _ <  __/ (_| (_) | | | |
|_| \_\___|\__,_|   |_|\___|\__,_|_| |_| |_| |_| \_\___|\___\___/|_| |_|    

EOF
    # Reset text color
    echo -e "\e[0m"
}
# Call the function to display the art
display_art
sleep 3

# Get subdomains from Subcat
echo -e "${ORANGE}Getting subdomains from Subcat...${ENDCOLOR}"
python3 ~/tools/subcat/subcat.py --silent -d $1 | tee -a subcat.txt
sleep 2
echo -e "${GREEN}Subdomains acquired from Subcat!${ENDCOLOR}"
sleep 2

# Get subdomains from ctfr
echo -e "${ORANGE}Getting subdomains from ctfr...${ENDCOLOR}"
python3 ~/tools/ctfr/ctfr.py -d $1 -o ctfr.txt
sleep 2
echo -e "${GREEN}Subdomains acquired from ctfr!${ENDCOLOR}"
sleep 2

# Get subdomains from Assetfinder

echo -e "${ORANGE}Getting subdomains from Assetfinder${ENDCOLOR}"
assetfinder --subs-only $1 | tee assetfinder.txt
sleep 2
echo -e "${GREEN}Subdomains acquired from assetfinder!"
sleep 2

# Get subdomains from Subfinder

echo -e "${ORANGE}Getting subdomains from Subfinder${ENDCOLOR}"
subfinder --all --silent  -d $1 -o subfinder.txt
sleep 2
echo -e "${GREEN}Subdomains acquired from Subfinder!"
sleep 2

# Get subdomains from Findomain

echo -e "${ORANGE}Getting subdomains from Findomain${ENDCOLOR}"
findomain -q -t $1 -u findomain.txt
sleep 2
echo -e "${GREEN}Subdomains acquired from Findomain!${ENDCOLOR}"
sleep 5

# Add all acquired subdomains to subdomains/initial

echo -e "${ORANGE}Compiling acquired subdomains to subdomains-out.txt${ENDCOLOR}"
sleep 2
cat subcat.txt | anew subdomains.txt
sleep 1
cat ctfr.txt | anew subdomains.txt
sleep 1
cat findomain.txt | anew subdomains.txt
sleep 1
cat subfinder.txt | anew subdomains.txt
sleep 1
cat assetfinder.txt | anew subdomains.txt
sleep 1
echo -e "${GREEN}All subdomains are added to subdomains.txt${ENDCOLOR}"
sleep 5

# Check for live subdomains from initial.txt

echo -e "${ORANGE}Checking for live subdomains...Grab some coffee.${ENDCOLOR}"
sleep 2
cat subdomains.txt | httpx -silent | sort -u | tee -a live_domains.txt  
sleep 2
echo -e "${GREEN}All live subdomains have been added to live_domains.txt.${ENDCOLOR}"
sleep 2

# Cleaning Up

echo -e "${ORANGE}Cleaning up...please wait!${ENDCOLOR}"
sleep 2
rm findomain.txt subfinder.txt subcat.txt assetfinder.txt ctfr.txt
sleep 2
echo -e "${GREEN}All done! Happy hacking!${ENDCOLOR}"
sleep 2

# Getting wayback urls
echo -e "${ORANGE}Getting waybackurls${ENDCOLOR}"
sleep 2
cat subdomains.txt | waybackurls | tee waybackurls.txt
sleep 2
echo -e "${GREEN}waybackurls completed successfully.${ENDCOLOR}"
sleep 2

# Cleaning up waybackuls
echo -e "${ORANGE}Cleaning up waybackurls${ENDCOLOR}"
sleep 2
input_file="waybackurls.txt"
output_file="filtered_waybackurls.txt"
# Ensure the input file exists
if [ ! -f "$input_file" ]; then
    echo "Input file $input_file not found."
    exit 1
fi
# Remove URLs ending with common image file extensions
grep -Ev "\.(jpg|jpeg|png|gif|bmp|tif|tiff|ico|svg|webp)$" "$input_file" > "$output_file"
echo -e "${GREEN}filtered waybackurls saved successfully.${ENDCOLOR}"
sleep 2

# Filter waybackurl parameters
echo -e "${ORANGE}Filtering waybackurls parameters!${ENDCOLOR}"
sleep 2
cat waybackurls.txt | grep "\?" | uro | httpx -silent > filtered_parameters.txt
cat filtered_waybackurls.txt | uro | anew filtered_parameters.txt
sleep 2
echo -e "${GREEN}Filtered URLs saved successfully!${ENDCOLOR}"
sleep 2

# Crawl urls with Katana
echo -e "${ORANGE}Crawling URLs with Katana...${ENDCOLOR}"
sleep 2
katana -u live_domains.txt -d 5 -ps -pss waybackarchive,commoncrawl,alienvault -kf -jc -fx -ef woff,css,png,svg,jpg,woff2,jpeg,gif,svg -o allurls.txt
cat allurls.txt | anew filtered_parameters.txt
sleep 2
echo -e "${GREEN}URL crawling completed successfully.${ENDCOLOR}"
sleep 2

# Js File enumeration
echo -e "${ORANGE}Enumerating Js files!${ENDCOLOR}"
sleep 2
cat filtered_parameters.txt | grep ".js$" | tee js-files.txt
cat live_domains.txt | hakrawler | grep ".js$" | anew  js-files.txt
sleep 2
echo -e "${GREEN}Js enumeration completed successfully.${ENDCOLOR}"
sleep 2

# Getting WAFs for all subdomains
echo -e "${ORANGE}Getting WAF information for all subdomains${ENDCOLOR}"
sleep 2
wafw00f -a -i live_domains.txt -o waf.txt
sleep 2
echo -e "${GREEN}WafW00f completed successfully.${ENDCOLOR}"
sleep 2

# Get exposed .git files
echo -e "${ORANGE}Getting exposed .git files${ENDCOLOR}"
cat subdomains.txt | subgit | tee git-exposed-urls.txt
cat live_domains.txt | subgit | anew git-exposed-urls.txt
echo -e "${GREEN}Scan completed.${ENDCOLOR}"

# Crawl with Photon
echo -e "${ORANGE}Crawling with Photon${ENDCOLOR}"
python3 ~/tools/Photon/photon.py -u $1 --wayback
echo -e "${GREEN}Crawl completed.${ENDCOLOR}"

# Potential IDOR URLs
echo -e "${ORANGE}Getting potential IDOR URLs with gf${ENDCOLOR}"
sleep 2
cat waybackurls.txt | ~/go/bin/gf idor | tee potential_IDOR_urls.txt
sleep 2
echo -e "${GREEN}Potential IDOR URLs added.${ENDCOLOR}"
sleep 2

# Potential Open Redirect URLs
echo -e "${ORANGE}Getting potential Open Redirect URLs with gf${ENDCOLOR}"
sleep 2
cat waybackurls.txt | ~/go/bin/gf redirect | tee potential_openredirect_urls.txt
sleep 2
echo -e "${GREEN}Potential Open Redirect URLs added.${ENDCOLOR}"
sleep 2

# Check for hosts
echo -e "${ORANGE}Getting hosts information${ENDCOLOR}"
sleep 2
cat live_domains.txt | xargs -I{} host {} | tee -a hosts.txt
sleep 2
echo -e "${GREEN}Hosts information added successfully.${ENDCOLOR}"
sleep 2

# Check for subdomain takeover
echo -e "${ORANGE}Checking for subdomain takeover...${ENDCOLOR}"
sleep 2
subzy run --targets subdomains.txt --concurrency 100 --hide_fails --verify_ssl --output subdomains-takeover.txt
sleep 2
echo -e "${GREEN}Subdomains takeover scan completed successfully.${ENDCOLOR}"
sleep 2

# Extract IPs from subdomains
echo -e "${ORANGE}Extracting IPs from subdomains${ENDCOLOR}"
sleep 2
cat subdomains.txt | nslookup | grep 'Address:' | awk '{print $2}' | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | sort | uniq | tee ip-addresses.txt
sleep 2
echo -e "${GREEN}IPs extracted and saved.${ENDCOLOR}"
sleep 2

# Scanning for open ports
echo -e "${ORANGE}Scanning for open ports with nmap${ENDCOLOR}"
sleep 2
sudo nmap -sS -sC -sV -T4 -iL ip-addresses.txt --script vuln -oN nmap.txt
sleep 2
echo -e "${GREEN}Scan completed.${ENDCOLOR}"
sleep 2

# Starting Nuclei
echo -e "${ORANGE}Starting Nuclei against live and filtered subdomains...!${ENDCOLOR}"
sleep 2
cat live_domains.txt | anew nuclei-urls.txt
cat filtered_parameters.txt | anew nuclei-urls.txt
nuclei -ut -up
nuclei -l nuclei-urls.txt -es info -o nuclei.txt
sleep 2
echo -e "${GREEN}All enumeration has completed successfully! Happy Hacking!${ENDCOLOR}"

# Running sqlmap against waybackurls
echo -e "${ORANGE}Starting SQLMap against waybackurls...!${ENDCOLOR}"
sleep 2
cat waybackurls.txt | ~/go/bin/gf sqli | tee potential_SQLi_URLs.txt 
cat filtered_parameters.txt | ~/go/bin/gf sqli | anew potential_SQLi_URLs.txt
sqlmap -m potential_SQLi_URLs.txt --dbs --batch --random-agent 
echo -e "${GREEN}Scan completed.${ENDCOLOR}"
sleep 5

# Cleanup
echo -e "${ORANGE}Cleaning up...!${ENDCOLOR}"
rm filtered_waybackurls.txt allurls.txt 
sleep 2
echo -e "${RED}Done. Happy Hacking!!${ENDCOLOR}"