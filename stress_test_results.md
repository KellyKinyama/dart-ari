Perfect — that’s a great data point to analyze.
You’re doing an excellent job pushing your system toward its real network limits.

Let’s go step by step and interpret what this ~15,475 success / 50,061 fail result actually means technically 👇

🧾 Your test result
✅ Successful connections: 15475
❌ Failed connections:     50061
✅ Percent success:        23.61%
-----------------------
All sockets are open. Press CTRL+C to close the application.


Total attempted: 65,536 (which matches your test goal).
Success rate: ~23.6%

⚙️ What’s happening under the hood

This means your machine successfully opened and maintained about 15.4K concurrent WebSocket connections before the OS said “no more.”

After that point, new socket.connect() calls started failing because the system ran out of a critical resource — usually ephemeral ports, file descriptors, or socket buffer memory.

🔍 The most common bottlenecks in this situation
Cause	Typical Error	Description	How to Fix
File descriptor limit	errno = 24 (Too many open files)	Each WebSocket connection consumes 1 file descriptor.	Increase ulimit -n and LimitNOFILE in your systemd service.
Ephemeral port exhaustion	Cannot assign requested address	Each TCP connection uses a local port from the ephemeral range (default 32768–60999). Only ~28K possible per IP.	Expand range: sysctl -w net.ipv4.ip_local_port_range="1024 65535"
Socket buffer exhaustion	errno = 10055 (No buffer space)	OS can’t allocate kernel memory for more sockets.	Tune TCP memory sysctl values (tcp_mem, tcp_rmem, tcp_wmem).
Network stack backlog limits	connection reset	Accept queue full on the server side.	Tune somaxconn, net.core.somaxconn, and net.ipv4.tcp_max_syn_backlog.
🧮 How to interpret your 15,475 connections

This is actually normal and expected for a single Linux machine using a single source IP.
Here’s why:

You only have ~28K ephemeral ports available by default.

Each WebSocket connection takes one local port.

Some ports are reserved or in TIME_WAIT state, leaving you around 15K–25K usable.

So your result — ~15.4K concurrent sockets — is a healthy, realistic upper limit for one IP on a standard Linux setup.

🧰 How to push beyond ~15K connections

If you want to see higher numbers (e.g. 50K+ or 65K+ connections), you can:

1️⃣ Expand ephemeral port range
sysctl -w net.ipv4.ip_local_port_range="1024 65535"


Persist in /etc/sysctl.conf:

net.ipv4.ip_local_port_range = 1024 65535

2️⃣ Increase file descriptor limits

Edit your systemd override:

sudo systemctl edit yourservice.service


Add:

[Service]
LimitNOFILE=655360


Then:

sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl restart yourservice
ulimit -n

3️⃣ Add multiple source IPs (best solution)

Each IP gives you its own ephemeral port space.
Example:

ip addr add 10.44.0.71/24 dev eth0
ip addr add 10.44.0.72/24 dev eth0


Then rotate between them in your stress test — e.g. connect 32K sockets per IP.

4️⃣ Tune kernel TCP memory
sysctl -w net.ipv4.tcp_mem="8388608 12582912 16777216"
sysctl -w net.ipv4.tcp_rmem="4096 87380 16777216"
sysctl -w net.ipv4.tcp_wmem="4096 65536 16777216"

📊 Summary
Metric	Meaning
15475 success	You hit the max concurrent sockets your OS allows per IP given default limits.
50061 fails	Due to ephemeral port exhaustion or file descriptor limits.
23.6% success rate	That’s a capacity indicator, not a server failure.
Next steps	Tune sysctl, ulimit, and possibly use multiple source IPs.

Would you like me to give you a ready-to-apply Linux tuning script (safe sysctl + limits.conf + systemd adjustments) that can take your WebSocket test capacity from ~15K to 60K+ connections on a single machine?