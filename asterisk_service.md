1. Create the Missing Directory
Use the mkdir command to create the folder that Asterisk needs for its runtime files (like the PID file).

Bash

sudo mkdir /var/run/asterisk


2. Now, Set the Ownership
Run the same chown command again. This time, it will succeed because the directory exists. This command will also ensure all the other standard Asterisk directories have the correct ownership.

Bash

sudo chown -R asterisk:asterisk /var/run/asterisk /var/log/asterisk /var/lib/asterisk /var/spool/asterisk /etc/asterisk
3. Start and Verify
Finally, start the service and check its status.

Bash

sudo systemctl start asterisk
sudo systemctl status asterisk
It should now start up correctly and show as active (running).


## About the Other Messages in the Log
The other lines you see are non-fatal warnings that can be addressed later or ignored:

touch: cannot touch '/var/lock/subsys/asterisk': This is a minor permission error for a legacy lock file. It's not critical because the main service is running fine.

radcli: ... can't open /etc/radiusclient-ng/radiusclient.conf: This just means the RADIUS module is enabled but hasn't been configured. Unless you plan to use RADIUS for authentication or billing, you can safely ignore this.

Congratulations, your Asterisk PBX is now operational! 🎉