#!/bin/bash

# scan_nmap() {
#     # ip=$1
#     # nmap_output=$(rustscan -u 5000 -a "$ip")
#     # report_filename="nmap_report_$ip.txt"
#     # echo "$nmap_output" > "$report_filename"
#     # echo "Nmap report saved as: $report_filename"


    
# }
scan_nmap() {
    ip=$1
    rustscan_output=$(rustscan  -u 5000  -a "$ip")
    report_filename="rustscan_report_$ip.txt"
    echo "$rustscan_output" > "$report_filename"
    echo "RustScan report saved as: $report_filename"

    report_html="/var/www/html/rustscan_report_$ip.html"
    vulnerable_ports=$(echo "$rustscan_output" | grep -E 'Open.*(ssh|ftp)' | awk '{print $1}' FS="/" | tr '\n' ',' | sed 's/,$//')

    cat <<EOF > "$report_html"
<!DOCTYPE html>
<html>
<head>
<title>RustScan Report for $ip</title>
<style>
  body {
    font-family: Arial, sans-serif;
    margin: 20px;
  }
  h1 {
    color: #333;
  }
  table {
    border-collapse: collapse;
    width: 100%;
  }
  th, td {
    border: 1px solid #ddd;
    padding: 8px;
    text-align: left;
  }
  th {
    background-color: #f2f2f2;
  }
  .open {
    color: green;
    font-weight: bold;
  }
  .vulnerable {
    color: red;
    font-weight: bold;
  }
</style>
</head>
<body>
<h1>RustScan Report for $ip</h1>
<table>
  <tr>
    <th>Port</th>
    <th>Status</th>
    <th>Service</th>
  </tr>
EOF

    while IFS= read -r line; do
        port=$(echo "$line" | awk '{print $1}' FS="/")
        status=$(echo "$line" | awk '{print $2}')
        service=$(echo "$line" | awk '{print $3}')
        
        if [[ $vulnerable_ports == *"$port"* ]]; then
            echo "  <tr>" >> "$report_html"
            echo "    <td class=\"vulnerable\">$port</td>" >> "$report_html"
            echo "    <td class=\"vulnerable\">$status</td>" >> "$report_html"
            echo "    <td class=\"vulnerable\">$service</td>" >> "$report_html"
            echo "  </tr>" >> "$report_html"
        else
            echo "  <tr>" >> "$report_html"
            echo "    <td class=\"open\">$port</td>" >> "$report_html"
            echo "    <td class=\"open\">$status</td>" >> "$report_html"
            echo "    <td class=\"open\">$service</td>" >> "$report_html"
            echo "  </tr>" >> "$report_html"
        fi
    done < <(echo "$rustscan_output" | grep "/tcp")

    # End HTML report
    cat <<EOF >> "$report_html"
</table>
</body>
</html>
EOF

    echo "HTML report generated and saved as: $report_html"
}




scan_nikto() {
    website=$1
    nikto_output=$(nikto -h "$website")
    report_filename="nikto_report_$website.txt"
    echo "$nikto_output" > "$report_filename"
    echo "Nikto report saved as: $report_filename"
}

scan_clamav() {
    app_path=$1
    clamav_output=$(clamscan --log="/home/g0d/Work/clamav_report.txt" "$app_path")
    report_txt="/home/g0d/Work/clamav_report.txt"
    report_html="/var/www/html/clamav_report.html"

    mkdir -p "$(dirname "$report_html")"

    if [ ! -f "$report_html" ]; then
        cat <<EOF > "$report_html"
<!DOCTYPE html>
<html>
<head>
<title>ClamAV Scan Report</title>
<style>
  body {
    font-family: Arial, sans-serif;
    margin: 20px;
  }
  h1 {
    color: #333;
  }
  table {
    border-collapse: collapse;
    width: 100%;
  }
  th, td {
    border: 1px solid #ddd;
    padding: 8px;
    text-align: left;
  }
  th {
    background-color: #f2f2f2;
  }
  .infected {
    color: red;
    font-weight: bold;
  }
</style>
</head>
<body>
<h1>ClamAV Scan Report</h1>
<table>
  <tr>
    <th>File</th>
    <th>Status</th>
    <th>Time of Scan</th>
  </tr>
EOF
    else
        echo "" >> "$report_html"
    fi

    while IFS= read -r line; do
        if [[ $line == *"FOUND"* ]]; then
            file=$(echo "$line" | awk '{print $2}')
            echo "  <tr>" >> "$report_html"
            echo "    <td>$file</td>" >> "$report_html"
            echo "    <td class=\"infected\">Infected</td>" >> "$report_html"
            echo "  </tr>" >> "$report_html"
        fi
    done < "$report_txt"

    cat <<EOF >> "$report_html"
</table>
</body>
</html>
EOF

    mv "$report_html" /var/www/html/

    echo "HTML report generated and moved to /var/www/html/clamav_report.html"
}

echo "Welcome to the Security Scanner"

echo "Select a tool to use:"
echo "1. Nmap - Scan for open ports"
echo "2. Nikto - Scan a website for vulnerabilities"
echo "3. ClamAV - Scan an app for malware"

read -p "Enter your choice (1/2/3): " choice

case $choice in
    1)
        read -p "Enter the IP address to scan with Nmap: " ip
        scan_nmap "$ip"
        ;;
    2)
        read -p "Enter the website URL to scan with Nikto: " website
        scan_nikto "$website"
        ;;
    3)
        read -p "Enter the path to the app to scan with ClamAV: " app_path
        scan_clamav "$app_path"
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac
