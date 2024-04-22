#! /bin/bash

# Eric's custom enumeration tool

# Colors to use

RED="\e[31m"
GREEN="\e[32m"
ORANGE="\e[38;5;208m"
ENDCOLOR="\e[0m"

# Introduction

echo -e "${RED}Welcome to CGA Red Team Recon!${ENDCOLOR}"
sleep 3

# Get subdomains from Subcat

echo -e "${ORANGE}Getting subdomains from Subcat...${ENDCOLOR}"
python3 ~/tools/subcat/subcat.py --silent -d $1 | tee -a subcat.txt
sleep 2
echo -e "${ORANGE}Subdomains acquired from Subcat!${ENDCOLOR}"
sleep 2

# Get subdomains from Assetfinder

echo -e "${ORANGE}Getting subdomains from Assetfinder${ENDCOLOR}"
assetfinder --subs-only $1 | tee assetfinder.txt
sleep 2
echo -e "${GREEN}Subdomains acquired from assetfinder!"
sleep 2

# Get subdomains from Subfinder

echo -e "${GREEN}Getting subdomains from Subfinder${ENDCOLOR}"
subfinder --all --silent  -d $1 -o subfinder.txt
sleep 2
echo -e "${GREEN}Subdomains acquired from Subfinder!"
sleep 2

# Get subdomains from Findomain

echo -e "${GREEN}Getting subdomains from Findomain${ENDCOLOR}"
findomain -q -t $1 -u findomain.txt
sleep 2
echo -e "${GREEN}Subdomains acquired from Findomain!${ENDCOLOR}"
sleep 2

# Getting subdomains from Amass

# echo -e "${GREEN}Getting subdomains from Amass${ENDCOLOR}"
# amass enum -d $1 | tee amass.txt
# sleep 2
# echo -e "${GREEN}Subdomains acquired from Amass!${ENDCOLOR}"  
# sleep 2

# Add all acquired subdomains to subdomains/initial

echo -e "${GREEN}Compiling acquired subdomains to subdomains-out.txt${ENDCOLOR}"
sleep 2
cat subcat.txt | anew subdomains-out.txt
sleep 1
cat findomain.txt | anew subdomains-out.txt
sleep 1
cat subfinder.txt | anew subdomains-out.txt
# sleep 1
# cat amass.txt | anew subdomains-out.txt
sleep 1
cat assetfinder.txt | anew subdomains-out.txt
sleep 1
echo -e "${GREEN}All subdomains are added to subdomains-out.txt${ENDCOLOR}"
sleep 2

# Check for live subdomains from initial.txt

echo -e "${GREEN}Checking for live subdomains...Grab some cofee.${ENDCOLOR}"
sleep 2
cat subdomains-out.txt | httpx -silent | sort -u | tee -a live_domains.txt  
sleep 2
echo -e "${GREEN}All live subdomains have been added to live_domains.txt.${ENDCOLOR}"
sleep 2

# Cleaning Up

echo -e "${RED}Cleaning up...please wait!${ENDCOLOR}"
sleep 2
rm findomain.txt subfinder.txt subcat.txt assetfinder.txt
sleep 2
echo -e "${GREEN}All done! Happy hacking, Eric!${ENDCOLOR}"
sleep 2

# Getting wayback urls with gauplus
echo -e "${GREEN}Getting waybackurls${ENDCOLOR}"
sleep 2
cat subdomains-out.txt | gauplus | tee gauplus-out.txt
sleep 2
echo -e "${GREEN}waybackurls completed successfully.${ENDCOLOR}"
sleep 2

# Getting URLs and JavaScript files with Hakrawler
echo -e "${GREEN}Getting URLs and JavaScript files with Hakrawler${ENDCOLOR}"
sleep 2
cat live_domains.txt | hakrawler | tee urls-js-out.txt
sleep 2
echo -e "${GREEN}Hakrawler completed successfully.${ENDCOLOR}"
sleep 2

# Getting WAFs for all subdomains
echo -e "${GREEN}Getting WAF information for all subdomains${ENDCOLOR}"
sleep 2
wafw00f -a -i live_domains.txt -o waf-out.txt
sleep 2
echo -e "${GREEN}WafW00f completed successfully.${ENDCOLOR}"
sleep 2

# Potential IDOR URLs
echo -e "${GREEN}Getting potential IDOR URLs with gf${ENDCOLOR}"
sleep 2
cat gauplus-out.txt | gf idor | tee potential_IDOR_urls.txt
sleep 2
echo -e "${GREEN}Potential IDOR URLs added.${ENDCOLOR}"
sleep 2

# Potential Open Redirect URLs
echo -e "${GREEN}Getting potential Open Redirect URLs with gf${ENDCOLOR}"
sleep 2
cat gauplus-out.txt | gf redirect | tee potential_openredirect_urls.txt
sleep 2
echo -e "${GREEN}Potential Open Redirect URLs added.${ENDCOLOR}"
sleep 2

# Check for hosts
echo -e "${GREEN}Getting hosts information${ENDCOLOR}"
sleep 2
cat live_domains.txt | xargs -I{} host {} | tee -a hosts-out.txt
sleep 2
echo -e "${GREEN}Hosts information added successfully.${ENDCOLOR}"
sleep 2

# Starting Nuclei
echo -e "${GREEN}Starting Nuclei against live subdomains...!${ENDCOLOR}"
sleep 2
nuclei -l live_domains.txt -es info -o nuclei.txt
sleep 2
echo -e "${GREEN}All enumeration has completed successfully! Happy Hacking!${ENDCOLOR}"

# Finding xss, sql, ssrf, open-redirect with Nuclei

echo -e "${GREEN}Finding xss, sql, ssrf, open-redirect with Nuclei...!${ENDCOLOR}"
sleep 2
cat gauplus-out.txt | grep "\?" | uro | httpx -silent > potentially_vulnerable_parameters.txt
sleep 2
nuclei -l potentially_vulnerable_parameters.txt -es info -o nuclei_potentially_vulnerable_parameters.txt
sleep 2
echo -e "${GREEN}Nuclei completed successfully!${ENDCOLOR}"

# Running sqlmap against gauplus
echo -e "${GREEN}Starting SQLMap against waybackurls...!${ENDCOLOR}"
sleep 2
cat gauplus-out.txt | gf sqli | tee potential_SQLi_URLs.txt 
sqlmap -m potential_SQLi_URLs.txt --dbs --batch --random-agent 
echo -e "${GREEN}Success!! Happy Hacking!${ENDCOLOR}"