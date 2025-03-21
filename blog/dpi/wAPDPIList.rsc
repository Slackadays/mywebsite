/ip firewall layer7-protocol
add name=Windows regexp="(evoke|tile|watson|telemetry|windows|smartscreen|maps\
    |activity|choice|download|update|diagnostics|feedback|spynet|telecommand|i\
    pv6|vortex).*(data|support|microsoft|windows|bing|update|live|msedge)"
add name=Apple regexp="(albert|captive|gs|humb|static.ips|sq-device|tbsc|push|\
    appldnld|configuration|gg|gnf|gs|ig|updates|ppq|serverstatus|appattest|dia\
    gassets|doh\\.dns|crl|oscp|valid|phobos).*(apple)"
/ip firewall address-list
add address=13.68.87.47 list=windows_update
add address=13.68.87.175 list=windows_update
add address=13.68.88.129 list=windows_update
add address=13.68.93.109 list=windows_update
add address=13.74.179.117 list=windows_update
add address=13.78.168.230 list=windows_update
add address=13.78.177.144 list=windows_update
add address=13.78.179.199 list=windows_update
add address=13.78.180.50 list=windows_update
add address=13.78.180.90 list=windows_update
add address=13.78.184.44 list=windows_update
add address=13.78.184.186 list=windows_update
add address=13.78.186.254 list=windows_update
add address=13.78.187.58 list=windows_update
add address=13.78.230.134 list=windows_update
add address=13.83.148.218 list=windows_update
add address=13.83.148.235 list=windows_update
add address=13.83.149.5 list=windows_update
add address=13.83.149.67 list=windows_update
add address=13.83.151.160 list=windows_update
add address=13.86.124.174 list=windows_update
add address=13.86.124.184 list=windows_update
add address=13.86.124.191 list=windows_update
add address=13.91.16.64 list=windows_update
add address=13.91.16.65 list=windows_update
add address=13.91.16.66 list=windows_update
add address=13.92.211.120 list=windows_update
add address=13.107.4.50 list=windows_update
add address=13.107.4.52 list=windows_update
add address=13.107.4.254 list=windows_update
add address=20.36.218.63 list=windows_update
add address=20.36.218.70 list=windows_update
add address=20.36.222.39 list=windows_update
add address=20.36.252.130 list=windows_update
add address=20.41.41.23 list=windows_update
add address=20.42.24.29 list=windows_update
add address=20.42.24.50 list=windows_update
add address=20.44.77.24 list=windows_update
add address=20.44.77.45 list=windows_update
add address=20.44.77.49 list=windows_update
add address=20.44.77.219 list=windows_update
add address=20.45.4.77 list=windows_update
add address=20.45.4.178 list=windows_update
add address=20.54.24.69 list=windows_update
add address=20.54.24.79 list=windows_update
add address=20.54.24.148 list=windows_update
add address=20.54.24.169 list=windows_update
add address=20.54.24.231 list=windows_update
add address=20.54.24.246 list=windows_update
add address=20.54.25.4 list=windows_update
add address=20.54.25.16 list=windows_update
add address=20.54.89.15 list=windows_update
add address=20.54.89.106 list=windows_update
add address=20.62.190.184 list=windows_update
add address=20.62.190.185 list=windows_update
add address=20.62.190.186 list=windows_update
add address=20.185.109.208 list=windows_update
add address=20.186.48.46 list=windows_update
add address=20.188.74.161 list=windows_update
add address=20.188.78.184 list=windows_update
add address=20.188.78.185 list=windows_update
add address=20.188.78.187 list=windows_update
add address=20.188.78.188 list=windows_update
add address=20.188.78.189 list=windows_update
add address=20.190.3.175 list=windows_update
add address=20.190.9.86 list=windows_update
add address=20.191.46.109 list=windows_update
add address=20.191.46.211 list=windows_update
add address=23.103.189.125 list=windows_update
add address=23.103.189.126 list=windows_update
add address=23.103.189.157 list=windows_update
add address=23.103.189.158 list=windows_update
add address=40.67.248.104 list=windows_update
add address=40.67.251.132 list=windows_update
add address=40.67.251.134 list=windows_update
add address=40.67.252.175 list=windows_update
add address=40.67.252.206 list=windows_update
add address=40.67.253.249 list=windows_update
add address=40.67.254.36 list=windows_update
add address=40.67.254.97 list=windows_update
add address=40.67.255.199 list=windows_update
add address=40.69.216.73 list=windows_update
add address=40.69.216.129 list=windows_update
add address=40.69.216.251 list=windows_update
add address=40.69.218.62 list=windows_update
add address=40.69.219.197 list=windows_update
add address=40.69.220.46 list=windows_update
add address=40.69.221.239 list=windows_update
add address=40.69.222.109 list=windows_update
add address=40.69.223.39 list=windows_update
add address=40.69.223.198 list=windows_update
add address=40.70.224.144 list=windows_update
add address=40.70.224.145 list=windows_update
add address=40.70.224.147 list=windows_update
add address=40.70.224.148 list=windows_update
add address=40.70.224.149 list=windows_update
add address=40.70.229.150 list=windows_update
add address=40.77.18.167 list=windows_update
add address=40.77.224.8 list=windows_update
add address=40.77.224.11 list=windows_update
add address=40.77.224.145 list=windows_update
add address=40.77.224.254 list=windows_update
add address=40.77.226.13 list=windows_update
add address=40.77.226.181 list=windows_update
add address=40.77.226.246 list=windows_update
add address=40.77.226.247 list=windows_update
add address=40.77.226.248 list=windows_update
add address=40.77.226.249 list=windows_update
add address=40.77.226.250 list=windows_update
add address=40.77.229.8 list=windows_update
add address=40.77.229.9 list=windows_update
add address=40.77.229.12 list=windows_update
add address=40.77.229.13 list=windows_update
add address=40.77.229.16 list=windows_update
add address=40.77.229.21 list=windows_update
add address=40.77.229.22 list=windows_update
add address=40.77.229.24 list=windows_update
add address=40.77.229.26 list=windows_update
add address=40.77.229.27 list=windows_update
add address=40.77.229.29 list=windows_update
add address=40.77.229.30 list=windows_update
add address=40.77.229.32 list=windows_update
add address=40.77.229.35 list=windows_update
add address=40.77.229.38 list=windows_update
add address=40.77.229.44 list=windows_update
add address=40.77.229.45 list=windows_update
add address=40.77.229.50 list=windows_update
add address=40.77.229.53 list=windows_update
add address=40.77.229.62 list=windows_update
add address=40.77.229.65 list=windows_update
add address=40.77.229.67 list=windows_update
add address=40.77.229.69 list=windows_update
add address=40.77.229.70 list=windows_update
add address=40.77.229.71 list=windows_update
add address=40.77.229.74 list=windows_update
add address=40.77.229.76 list=windows_update
add address=40.77.229.80 list=windows_update
add address=40.77.229.81 list=windows_update
add address=40.77.229.82 list=windows_update
add address=40.77.229.88 list=windows_update
add address=40.77.229.118 list=windows_update
add address=40.77.229.123 list=windows_update
add address=40.77.229.128 list=windows_update
add address=40.77.229.133 list=windows_update
add address=40.77.229.141 list=windows_update
add address=40.77.229.199 list=windows_update
add address=40.79.65.78 list=windows_update
add address=40.79.65.123 list=windows_update
add address=40.79.65.235 list=windows_update
add address=40.79.65.237 list=windows_update
add address=40.79.66.194 list=windows_update
add address=40.79.66.209 list=windows_update
add address=40.79.67.176 list=windows_update
add address=40.79.70.158 list=windows_update
add address=40.91.73.169 list=windows_update
add address=40.91.73.219 list=windows_update
add address=40.91.75.5 list=windows_update
add address=40.91.80.89 list=windows_update
add address=40.91.91.94 list=windows_update
add address=40.91.120.196 list=windows_update
add address=40.91.122.44 list=windows_update
add address=40.125.122.151 list=windows_update
add address=40.125.122.176 list=windows_update
add address=51.103.5.159 list=windows_update
add address=51.103.5.186 list=windows_update
add address=51.104.162.50 list=windows_update
add address=51.104.162.168 list=windows_update
add address=51.104.164.114 list=windows_update
add address=51.104.167.48 list=windows_update
add address=51.104.167.186 list=windows_update
add address=51.104.167.245 list=windows_update
add address=51.104.167.255 list=windows_update
add address=51.105.249.223 list=windows_update
add address=51.105.249.228 list=windows_update
add address=51.105.249.239 list=windows_update
add address=52.142.21.136 list=windows_update
add address=52.137.102.105 list=windows_update
add address=52.137.103.96 list=windows_update
add address=52.137.103.130 list=windows_update
add address=52.137.110.235 list=windows_update
add address=52.142.21.137 list=windows_update
add address=52.142.21.140 list=windows_update
add address=52.142.21.141 list=windows_update
add address=52.143.80.209 list=windows_update
add address=52.143.81.222 list=windows_update
add address=52.143.84.45 list=windows_update
add address=52.143.86.214 list=windows_update
add address=52.143.87.28 list=windows_update
add address=52.147.176.8 list=windows_update
add address=52.148.148.114 list=windows_update
add address=52.152.108.96 list=windows_update
add address=52.152.110.14 list=windows_update
add address=52.155.95.90 list=windows_update
add address=52.155.115.56 list=windows_update
add address=52.155.169.137 list=windows_update
add address=52.155.183.99 list=windows_update
add address=52.155.217.156 list=windows_update
add address=52.155.223.194 list=windows_update
add address=52.156.144.83 list=windows_update
add address=52.158.114.119 list=windows_update
add address=52.158.122.14 list=windows_update
add address=52.161.15.246 list=windows_update
add address=52.164.221.179 list=windows_update
add address=52.164.226.245 list=windows_update
add address=52.167.222.82 list=windows_update
add address=52.167.222.147 list=windows_update
add address=52.167.223.135 list=windows_update
add address=52.169.82.131 list=windows_update
add address=52.169.83.3 list=windows_update
add address=52.169.87.42 list=windows_update
add address=52.169.123.48 list=windows_update
add address=52.175.23.79 list=windows_update
add address=52.177.164.251 list=windows_update
add address=52.177.247.15 list=windows_update
add address=52.178.192.146 list=windows_update
add address=52.179.216.235 list=windows_update
add address=52.179.219.14 list=windows_update
add address=52.183.47.176 list=windows_update
add address=52.183.118.171 list=windows_update
add address=52.184.152.136 list=windows_update
add address=52.184.155.206 list=windows_update
add address=52.184.212.181 list=windows_update
add address=52.184.213.21 list=windows_update
add address=52.184.213.187 list=windows_update
add address=52.184.214.53 list=windows_update
add address=52.184.214.123 list=windows_update
add address=52.184.214.139 list=windows_update
add address=52.184.216.174 list=windows_update
add address=52.184.216.226 list=windows_update
add address=52.184.216.246 list=windows_update
add address=52.184.217.20 list=windows_update
add address=52.184.217.37 list=windows_update
add address=52.184.217.56 list=windows_update
add address=52.187.60.107 list=windows_update
add address=52.188.72.233 list=windows_update
add address=52.226.130.114 list=windows_update
add address=52.229.170.171 list=windows_update
add address=52.229.170.224 list=windows_update
add address=52.229.171.86 list=windows_update
add address=52.229.171.202 list=windows_update
add address=52.229.172.155 list=windows_update
add address=52.229.174.29 list=windows_update
add address=52.229.174.172 list=windows_update
add address=52.229.174.233 list=windows_update
add address=52.229.175.79 list=windows_update
add address=52.230.216.17 list=windows_update
add address=52.230.216.157 list=windows_update
add address=52.230.220.159 list=windows_update
add address=52.230.223.92 list=windows_update
add address=52.230.223.167 list=windows_update
add address=52.232.225.93 list=windows_update
add address=52.238.248.1 list=windows_update
add address=52.238.248.2 list=windows_update
add address=52.238.248.3 list=windows_update
add address=52.242.97.97 list=windows_update
add address=52.242.101.226 list=windows_update
add address=52.242.231.32 list=windows_update
add address=52.242.231.33 list=windows_update
add address=52.242.231.35 list=windows_update
add address=52.242.231.36 list=windows_update
add address=52.242.231.37 list=windows_update
add address=52.243.153.146 list=windows_update
add address=52.248.96.36 list=windows_update
add address=52.249.24.101 list=windows_update
add address=52.249.58.51 list=windows_update
add address=52.250.46.232 list=windows_update
add address=52.250.46.237 list=windows_update
add address=52.250.46.238 list=windows_update
add address=52.250.195.200 list=windows_update
add address=52.250.195.204 list=windows_update
add address=52.250.195.206 list=windows_update
add address=52.250.195.207 list=windows_update
add address=52.253.130.84 list=windows_update
add address=52.254.106.61 list=windows_update
add address=64.4.27.50 list=windows_update
add address=65.52.108.29 list=windows_update
add address=65.52.108.33 list=windows_update
add address=65.52.108.59 list=windows_update
add address=65.52.108.90 list=windows_update
add address=65.52.108.92 list=windows_update
add address=65.52.108.153 list=windows_update
add address=65.52.108.154 list=windows_update
add address=65.52.108.185 list=windows_update
add address=65.55.242.254 list=windows_update
add address=66.119.144.157 list=windows_update
add address=66.119.144.158 list=windows_update
add address=66.119.144.189 list=windows_update
add address=66.119.144.190 list=windows_update
add address=67.26.27.254 list=windows_update
add address=104.45.177.233 list=windows_update
add address=111.221.29.40 list=windows_update
add address=134.170.51.187 list=windows_update
add address=134.170.51.188 list=windows_update
add address=134.170.51.190 list=windows_update
add address=134.170.51.246 list=windows_update
add address=134.170.51.247 list=windows_update
add address=134.170.51.248 list=windows_update
add address=134.170.53.29 list=windows_update
add address=134.170.53.30 list=windows_update
add address=134.170.115.55 list=windows_update
add address=134.170.115.56 list=windows_update
add address=134.170.115.60 list=windows_update
add address=134.170.115.62 list=windows_update
add address=134.170.165.248 list=windows_update
add address=134.170.165.249 list=windows_update
add address=134.170.165.251 list=windows_update
add address=134.170.165.253 list=windows_update
add address=137.135.62.92 list=windows_update
add address=157.55.133.204 list=windows_update
add address=157.55.240.89 list=windows_update
add address=157.55.240.126 list=windows_update
add address=157.55.240.220 list=windows_update
add address=157.56.77.138 list=windows_update
add address=157.56.77.139 list=windows_update
add address=157.56.77.140 list=windows_update
add address=157.56.77.141 list=windows_update
add address=157.56.77.148 list=windows_update
add address=157.56.77.149 list=windows_update
add address=157.56.96.54 list=windows_update
add address=157.56.96.58 list=windows_update
add address=157.56.96.123 list=windows_update
add address=157.56.96.157 list=windows_update
add address=191.232.80.53 list=windows_update
add address=191.232.80.58 list=windows_update
add address=191.232.80.60 list=windows_update
add address=191.232.80.62 list=windows_update
add address=191.232.139.2 list=windows_update
add address=191.232.139.182 list=windows_update
add address=191.232.139.253 list=windows_update
add address=191.232.139.254 list=windows_update
add address=191.234.72.183 list=windows_update
add address=191.234.72.186 list=windows_update
add address=191.234.72.188 list=windows_update
add address=191.234.72.190 list=windows_update
add address=207.46.114.58 list=windows_update
add address=207.46.114.61 list=windows_update
add address=13.64.90.137 list=windows_telemetry
add address=13.68.31.193 list=windows_telemetry
add address=13.69.131.175 list=windows_telemetry
add address=13.66.56.243 list=windows_telemetry
add address=13.68.82.8 list=windows_telemetry
add address=13.68.92.143 list=windows_telemetry
add address=13.73.26.107 list=windows_telemetry
add address=13.74.169.109 list=windows_telemetry
add address=13.78.130.220 list=windows_telemetry
add address=13.78.232.226 list=windows_telemetry
add address=13.78.233.133 list=windows_telemetry
add address=13.88.21.125 list=windows_telemetry
add address=13.92.194.212 list=windows_telemetry
add address=13.104.215.69 list=windows_telemetry
add address=20.44.86.43 list=windows_telemetry
add address=20.49.150.241 list=windows_telemetry
add address=20.54.110.119 list=windows_telemetry
add address=20.60.20.4 list=windows_telemetry
add address=20.189.74.153 list=windows_telemetry
add address=23.99.49.121 list=windows_telemetry
add address=23.102.4.253 list=windows_telemetry
add address=23.102.5.5 list=windows_telemetry
add address=23.102.21.4 list=windows_telemetry
add address=23.103.182.126 list=windows_telemetry
add address=40.68.222.212 list=windows_telemetry
add address=40.69.153.67 list=windows_telemetry
add address=40.70.184.83 list=windows_telemetry
add address=40.70.220.248 list=windows_telemetry
add address=40.70.221.249 list=windows_telemetry
add address=40.77.228.47 list=windows_telemetry
add address=40.77.228.87 list=windows_telemetry
add address=40.77.228.92 list=windows_telemetry
add address=40.77.232.101 list=windows_telemetry
add address=40.78.128.150 list=windows_telemetry
add address=40.79.85.125 list=windows_telemetry
add address=40.88.32.150 list=windows_telemetry
add address=40.90.221.9 list=windows_telemetry
add address=40.112.209.200 list=windows_telemetry
add address=40.115.3.210 list=windows_telemetry
add address=40.115.119.185 list=windows_telemetry
add address=40.119.211.203 list=windows_telemetry
add address=40.119.249.228 list=windows_telemetry
add address=40.124.34.70 list=windows_telemetry
add address=40.127.240.158 list=windows_telemetry
add address=51.104.136.2 list=windows_telemetry
add address=51.124.78.146 list=windows_telemetry
add address=51.140.40.236 list=windows_telemetry
add address=51.140.157.153 list=windows_telemetry
add address=51.143.53.152 list=windows_telemetry
add address=51.143.111.7 list=windows_telemetry
add address=51.143.111.81 list=windows_telemetry
add address=51.144.227.73 list=windows_telemetry
add address=52.147.198.201 list=windows_telemetry
add address=52.138.204.217 list=windows_telemetry
add address=52.138.216.83 list=windows_telemetry
add address=52.155.94.78 list=windows_telemetry
add address=52.155.172.105 list=windows_telemetry
add address=52.157.234.37 list=windows_telemetry
add address=52.158.208.111 list=windows_telemetry
add address=52.164.241.205 list=windows_telemetry
add address=52.169.189.83 list=windows_telemetry
add address=52.170.83.19 list=windows_telemetry
add address=52.174.22.246 list=windows_telemetry
add address=52.178.147.240 list=windows_telemetry
add address=52.178.151.212 list=windows_telemetry
add address=52.178.178.16 list=windows_telemetry
add address=52.178.223.23 list=windows_telemetry
add address=52.183.114.173 list=windows_telemetry
add address=52.184.221.185 list=windows_telemetry
add address=52.229.39.152 list=windows_telemetry
add address=52.230.85.180 list=windows_telemetry
add address=52.230.222.68 list=windows_telemetry
add address=52.236.42.239 list=windows_telemetry
add address=52.236.43.202 list=windows_telemetry
add address=52.255.188.83 list=windows_telemetry
add address=65.52.100.7 list=windows_telemetry
add address=65.52.100.9 list=windows_telemetry
add address=65.52.100.11 list=windows_telemetry
add address=65.52.100.91 list=windows_telemetry
add address=65.52.100.92 list=windows_telemetry
add address=65.52.100.93 list=windows_telemetry
add address=65.52.100.94 list=windows_telemetry
add address=65.52.161.64 list=windows_telemetry
add address=65.55.29.238 list=windows_telemetry
add address=65.55.44.51 list=windows_telemetry
add address=65.55.44.54 list=windows_telemetry
add address=65.55.44.108 list=windows_telemetry
add address=65.55.44.109 list=windows_telemetry
add address=65.55.83.120 list=windows_telemetry
add address=65.55.113.11 list=windows_telemetry
add address=65.55.113.12 list=windows_telemetry
add address=65.55.113.13 list=windows_telemetry
add address=65.55.176.90 list=windows_telemetry
add address=65.55.252.43 list=windows_telemetry
add address=65.55.252.63 list=windows_telemetry
add address=65.55.252.70 list=windows_telemetry
add address=65.55.252.71 list=windows_telemetry
add address=65.55.252.72 list=windows_telemetry
add address=65.55.252.93 list=windows_telemetry
add address=65.55.252.190 list=windows_telemetry
add address=65.55.252.202 list=windows_telemetry
add address=66.119.147.131 list=windows_telemetry
add address=104.41.207.73 list=windows_telemetry
add address=104.42.151.234 list=windows_telemetry
add address=104.43.137.66 list=windows_telemetry
add address=104.43.139.21 list=windows_telemetry
add address=104.43.139.144 list=windows_telemetry
add address=104.43.140.223 list=windows_telemetry
add address=104.43.193.48 list=windows_telemetry
add address=104.43.228.53 list=windows_telemetry
add address=104.43.228.202 list=windows_telemetry
add address=104.43.237.169 list=windows_telemetry
add address=104.45.11.195 list=windows_telemetry
add address=104.45.214.112 list=windows_telemetry
add address=104.46.1.211 list=windows_telemetry
add address=104.46.38.64 list=windows_telemetry
add address=104.210.4.77 list=windows_telemetry
add address=104.210.40.87 list=windows_telemetry
add address=104.210.212.243 list=windows_telemetry
add address=104.214.35.244 list=windows_telemetry
add address=104.214.78.152 list=windows_telemetry
add address=131.253.6.87 list=windows_telemetry
add address=131.253.6.103 list=windows_telemetry
add address=131.253.34.230 list=windows_telemetry
add address=131.253.34.234 list=windows_telemetry
add address=131.253.34.237 list=windows_telemetry
add address=131.253.34.243 list=windows_telemetry
add address=131.253.34.246 list=windows_telemetry
add address=131.253.34.247 list=windows_telemetry
add address=131.253.34.249 list=windows_telemetry
add address=131.253.34.252 list=windows_telemetry
add address=131.253.34.255 list=windows_telemetry
add address=131.253.40.37 list=windows_telemetry
add address=134.170.30.202 list=windows_telemetry
add address=134.170.30.203 list=windows_telemetry
add address=134.170.30.204 list=windows_telemetry
add address=134.170.30.221 list=windows_telemetry
add address=134.170.52.151 list=windows_telemetry
add address=134.170.235.16 list=windows_telemetry
add address=157.56.74.250 list=windows_telemetry
add address=157.56.91.77 list=windows_telemetry
add address=157.56.106.184 list=windows_telemetry
add address=157.56.106.185 list=windows_telemetry
add address=157.56.106.189 list=windows_telemetry
add address=157.56.113.217 list=windows_telemetry
add address=157.56.121.89 list=windows_telemetry
add address=157.56.124.87 list=windows_telemetry
add address=157.56.149.250 list=windows_telemetry
add address=157.56.194.72 list=windows_telemetry
add address=157.56.194.73 list=windows_telemetry
add address=157.56.194.74 list=windows_telemetry
add address=168.61.24.141 list=windows_telemetry
add address=168.61.146.25 list=windows_telemetry
add address=168.61.149.17 list=windows_telemetry
add address=168.61.161.212 list=windows_telemetry
add address=168.61.172.71 list=windows_telemetry
add address=168.62.187.13 list=windows_telemetry
add address=168.63.100.61 list=windows_telemetry
add address=168.63.108.233 list=windows_telemetry
add address=191.236.155.80 list=windows_telemetry
add address=191.237.218.239 list=windows_telemetry
add address=191.239.50.18 list=windows_telemetry
add address=191.239.50.77 list=windows_telemetry
add address=191.239.52.100 list=windows_telemetry
add address=191.239.54.52 list=windows_telemetry
add address=207.68.166.254 list=windows_telemetry
add address=cdn.onenote.net list=windows_telemetry
add address=www.msftconnecttest.com list=windows_telemetry
add address=definitionupdates.microsoft.com list=windows_telemetry
add address=dlassets-ssl.xboxlive.com list=windows_telemetry
add address=www.xboxab.com list=windows_telemetry
add address=www.msftncsi.com list=windows_telemetry
/ip firewall filter
add action=reject chain=forward comment=\
    "reset tcp connections which have just been marked with tls" \
    connection-mark=tls_disconnect protocol=tcp reject-with=tcp-reset
/ip firewall mangle
add action=mark-connection chain=prerouting comment="redirect Windows ports" \
    connection-state=new dst-port=\
    445,987,1311,1503,1512,1688,3074,3389,3702,5000,5355,5357,5358,5481,5905 \
    new-connection-mark=vpn passthrough=yes protocol=tcp
add action=mark-connection chain=prerouting connection-state=new dst-port=\
    445,987,1311,1503,1512,1688,3074,3389,3702,5000,5355,5357,5358,5481,5905 \
    new-connection-mark=vpn passthrough=yes protocol=udp
add action=mark-connection chain=prerouting connection-state=new dst-port=\
    5985,5986,6516,6571,6602,6891-6901,7680,7777,8530,8531,8642,9080 \
    new-connection-mark=vpn passthrough=yes protocol=tcp
add action=mark-connection chain=prerouting connection-state=new dst-port=\
    5985,5986,6516,6571,6602,6891-6901,7680,7777,8530,8531,8642,9080 \
    new-connection-mark=vpn passthrough=yes protocol=udp
add action=mark-connection chain=prerouting comment="redirect Apple ports" \
    connection-state=new dst-port=2197,5223 new-connection-mark=vpn \
    passthrough=yes protocol=tcp
add action=mark-routing chain=prerouting comment="apply connection marks" \
    connection-mark=vpn new-routing-mark=vpn passthrough=no
add action=jump chain=prerouting comment=\
    "redirect specific traffic marked by tls - *.apple.com" jump-target=tls \
    protocol=tcp tls-host=*.apple.com
add action=jump chain=prerouting comment=*xbox*.com jump-target=tls protocol=\
    tcp tls-host=*xbox*.com
add action=jump chain=prerouting comment=*a-msedge.net jump-target=tls \
    protocol=tcp tls-host=*a-msedge.net
add action=return chain=tls comment=\
    "return packets if the hosts are already added" dst-address-list=\
    tls_dst_host
add action=add-dst-to-address-list address-list=tls_dst_host \
    address-list-timeout=2h chain=tls
add action=mark-connection chain=tls new-connection-mark=tls_disconnect \
    passthrough=yes
add action=return chain=tls
add action=mark-connection chain=prerouting dst-address-list=tls_dst_host \
    new-connection-mark=vpn passthrough=yes
add action=mark-connection chain=prerouting comment=\
    "redirect known Windows update/telemetry servers" connection-state=new \
    dst-address-list=windows_telemetry new-connection-mark=vpn passthrough=\
    yes
add action=mark-connection chain=prerouting connection-state=new \
    dst-address-list=windows_update new-connection-mark=vpn passthrough=yes
add action=mark-connection chain=prerouting comment="redirect devices which ma\
    ke unencrypted requests for Apple/Windows hosts" dst-address=\
    !192.168.0.0/16 layer7-protocol=Windows new-connection-mark=vpn \
    passthrough=yes protocol=tcp
add action=mark-connection chain=prerouting dst-address=!192.168.0.0/16 \
    layer7-protocol=Apple new-connection-mark=vpn passthrough=yes protocol=\
    tcp
add action=add-src-to-address-list address-list=redirected_hosts \
    address-list-timeout=15m chain=prerouting comment=\
    "mark hosts that make dns connections to Apple/Windows hosts" dst-port=53 \
    layer7-protocol=Apple protocol=udp
add action=add-src-to-address-list address-list=redirected_hosts \
    address-list-timeout=15m chain=prerouting dst-port=53 layer7-protocol=\
    Windows protocol=udp
add action=mark-connection chain=prerouting dst-address-list=!undirected_dst \
    new-connection-mark=vpn passthrough=yes src-address-list=redirected_hosts
add action=mark-routing chain=prerouting comment="apply connection marks" \
    connection-mark=vpn new-routing-mark=vpn passthrough=no
add action=add-dst-to-address-list address-list=undirected_dst \
    address-list-timeout=1d chain=prerouting comment=\
    "add \"trusted\" hosts to a trusted list" connection-state=new dst-port=\
    80,443 protocol=tcp src-address-list=!redirected_hosts
