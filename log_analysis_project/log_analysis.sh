#!/bin/bash

LOG_FILE="access.log"

# Basic counts
total_requests=$(wc -l < "$LOG_FILE")
get_requests=$(grep '"GET' "$LOG_FILE" | wc -l)
post_requests=$(grep '"POST' "$LOG_FILE" | wc -l)
put_requests=$(grep '"PUT' "$LOG_FILE" | wc -l)
delete_requests=$(grep '"DELETE' "$LOG_FILE" | wc -l)

# Unique IPs and analysis
unique_ips=$(awk '{print $1}' "$LOG_FILE" | sort | uniq | wc -l)
top_ip=$(awk '{ips[$1]++} END {for (ip in ips) print ips[ip], ip}' "$LOG_FILE" | sort -nr | head -1 | awk '{print $2}')
top_10_ips=$(awk '{print $1}' "$LOG_FILE" | sort | uniq -c | sort -nr | head -10)

# Status codes
failed_requests=$(awk '$9 ~ /^[45]/ {count++} END {print count}' "$LOG_FILE")
failed_percent=$(awk -v f="$failed_requests" -v t="$total_requests" 'BEGIN {printf "%.2f", (f/t)*100}')
most_common_status=$(awk '{print $9}' "$LOG_FILE" | sort | uniq -c | sort -nr | head -1)

# Time-based
total_days=$(awk '{print $4}' "$LOG_FILE" | cut -d: -f1 | sort | uniq | wc -l)
daily_avg=$(awk -v total="$total_requests" -v days="$total_days" 'BEGIN {printf "%.2f", total/days}')
busiest_hour=$(awk '{split($4, t, ":"); hour=t[2]; gsub("\[", "", t[1]); h[hour]++} END {for (i in h) print h[i], i}' "$LOG_FILE" | sort -nr | head -1)

# Final Summary
echo -e "\n==================== FINAL SUMMARY ====================="
echo "📌 Total Requests: $total_requests"
echo "🌐 GET Requests: $get_requests"
echo "📤 POST Requests: $post_requests"
echo "🛠️ PUT Requests: $put_requests"
echo "❌ DELETE Requests: $delete_requests"
echo "🔐 Unique IP Addresses: $unique_ips"
echo "🏆 Most Active IP: $top_ip"
echo "💥 Failed Requests (4xx & 5xx): $failed_requests"
echo "📉 Failure Rate: $failed_percent%"
echo "📆 Total Days in Log: $total_days"
echo "📊 Daily Average Requests: $daily_avg"
echo "⏰ Busiest Hour: $busiest_hour"
echo "📈 Most Common HTTP Status: $most_common_status"
echo "👥 Top 10 Active IPs:"
echo "$top_10_ips"
echo "=========================================================="

# GET and POST per IP
echo -e "\n🔍 GET and POST requests per IP:"
awk '{
    ip=$1;
    method=$6;
    gsub(/"/, "", method);
    if (method == "GET") get[ip]++;
    else if (method == "POST") post[ip]++;
}
END {
    printf "%-20s %-10s %-10s\n", "IP Address", "GET", "POST";
    for (ip in get) printf "%-20s %-10d %-10d\n", ip, get[ip], post[ip]+0;
    for (ip in post) if (!(ip in get)) printf "%-20s %-10d %-10d\n", ip, 0, post[ip];
}' "$LOG_FILE"

# Requests by hour
echo -e "\n🕒 Number of requests by hour:"
awk '{split($4, t, ":"); hour=t[2]; gsub("\[", "", t[1]); requests[hour]++} END {for (h in requests) print h, requests[h]}' "$LOG_FILE" | sort -n

# Failed requests by hour
echo -e "\n⚠️ Failed requests by hour:"
awk '$9 ~ /^[45]/ {split($4, t, ":"); hour=t[2]; fails[hour]++} END {for (h in fails) print h, fails[h]}' "$LOG_FILE" | sort -n

# Failed requests by day
echo -e "\n📅 Days with highest number of failed requests:"
awk '$9 ~ /^[45]/ {split($4, dt, ":"); gsub("\[", "", dt[1]); fails[dt[1]]++} END {for (d in fails) print fails[d], d}' "$LOG_FILE" | sort -nr | head -5

# Status codes breakdown
echo -e "\n📊 HTTP Status Code Breakdown:"
awk '{codes[$9]++} END {for (code in codes) print code, codes[code]}' "$LOG_FILE" | sort -n

# Top GET and POST IPs
echo -e "\n📈 Most active IP (GET method):"
grep '"GET' "$LOG_FILE" | awk '{print $1}' | sort | uniq -c | sort -nr | head -1

echo -e "\n📈 Most active IP (POST method):"
grep '"POST' "$LOG_FILE" | awk '{print $1}' | sort | uniq -c | sort -nr | head -1
