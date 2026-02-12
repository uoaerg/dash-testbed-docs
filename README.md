# ERG DASH testbed overview and how-tos
## Testbed picture
![IMG_3650](https://github.com/user-attachments/assets/dbf73375-3ff2-4ca1-a368-761e4e9decb7)

- All <span style="color:red">RED</span> cables connect interfaces in the network 137.50.17.0/24 (the public "Internet" network)
- All <span style="color:blue">BLUE</span> cables connect interfaces in the networks 192.168.99.0/24 and 192.168.100.0/24 (the private "local" networks)
- There is one <span style="color:yellow">YELLOW</span> cable indicating a "mirror" interface, which mirrors traffic intended for the quic/dash server (coming from both internet and local paths)  to the pcap-store.

## Testbed components
- QUIC/DASH server (dash): A machine running Debian 13. It serves a DASH video over TCP using the web server Apache 2, and over QUIC using Cloudflare's Quiche library. The server is available over the Internet at https://dash.erg.abdn.ac.uk. To access it locally, its address on the local network is 192.168.100.100.
- Delay Emulator (delay-em-1): A machine running FreeBSD 13. It allows setting up a Bandwidth and Delay to emulate various wireless links. Its address on the local network is 192.168.99.1 (it also acts as a router and will hand out IP addresses in the range 192.168.99.152 to 192.168.99.200).
- Client switch (client-sw): An 8 port Netgear switch; Plugging into any of the first 4 ports will allow you to connect to any of the testbed components on their local interfaces, set up emulation and run experiments on the local network.
- Copy Switch (copy-sw): An HP 24-port switch. This is required to mirror the traffic intended for the quic/dash server (coming from both internet and local paths) to the pcap-store. The researcher will not need to plug into this switch, but it may be useful to know ports 1-8 are configured for the local network, 9-16 on the Internet network, and port 20 is the mirror interface.
- PCAP Store (pcap-store): An APU4 board running Debian 13. The researcher can connect to it on its local IP address, 192.168.99.151. It receives mirror traffic on interface enp3s0.
  
## HOW TOs
### SSH into the DASH/QUIC server
- connect using one of the provided blue ethernet cables from your laptop to ports 1-4 of client-sw
- using putty or a terminal, ssh using the username and password provided to 192.168.100.100 (e.g. ssh your-user@192.168.100.100). You should be able to run any command on the server using sudo.
### Change the video shown on the DASH/QUIC server
- SSH into the DASH/QUIC server
- Download the required video in /var/www/html (the example below assumes it is named input.mp4)
- Run the ffmpeg command to transform it into DASH chunks:
```
ffmpeg -i input.mp4 \
  -map 0:v -map 0:v -map 0:a \
  -c:v libx264 -profile:v main -preset veryfast -crf 20 \  # uses Constant Rate Factor rather than Constant Bitrate
  -s:v:0 1920x1080 -b:v:0 5000k -maxrate:v:0 5350k -bufsize:v:0 7500k \ # a 1080p quality profile, caps bitrate at 5Mbps
  -s:v:1 1280x720  -b:v:1 2800k -maxrate:v:1 3000k -bufsize:v:1 4200k \ # another 420p quality profile, caps bitrate at 2.8Mbps
  -c:a aac -b:a 128k -ac 2 \
  -f dash \
  -seg_duration 4 \   # THIS IS THE DEFINED SEGMENT DURATION - 4 seconds here
  -use_timeline 1 \
  -use_template 1 \
  -init_seg_name 'init-$RepresentationID$.mp4' \
  -media_seg_name 'chunk-$RepresentationID$-$Number%05d$.m4s' \
  -adaptation_sets 'id=0,streams=v id=1,streams=a' \
  manifest.mpd
```

Once finished the new video will be available at https://dash.erg.abdn.ac.uk.

For CBR encoding, the script 2pass\_encode\_test.sh can be used. The bitrate ladder is specified at the top using the resolutions and their respective bitrates. For each resolution the script completes a first pass, generating a log file which is then passed for the second pass which generates an .mp4 file. After this is done for each resolution/bitrate, all mp4 files are then segmented into .m4s segments for DASH encoding. The audio track is generated during only the first resolution/bitrate's encoding. Finally, the script moves source files that have been used to the folder done/. All encoded files (.mp4, .m4s, .mpd) are stored in the encoded/ folder. The script can also be used to batch process multiple videos, though they should be carefully grouped as they are all encoded to the same resolutions/bitrates.

The 2 pass structure follows the recommended method according to the ffmpeg wiki for CBR encoding to target file size more accurately: https://trac.ffmpeg.org/wiki/Encode/H.264. The encoded files can then be moved as required for the directory structure.

### SSH into the delay emulator server
- connect using one of the provided blue ethernet cables from your laptop to ports 1-4 of client-sw
- using putty or a terminal, ssh using the username and password provided to 192.168.99.1 (e.g. ```ssh your-user@192.168.99.1```). You should be able to run any command on the server, some commands might require the password again.
  
### Change the latency of the delay emulator server
- SSH into the delay emulator server
- once logged in, run command sudo python3 config_pipes.py desired-bandwidth-in-mbps desired-delay-in-ms (e.g. ```sudo python3 config_pipes.py 25 600``` will configure the delay to be 600 ms and the BW to be 25 Mbps)
- check this has worked by pinging the QUIC/DASH server from your laptop (```ping 192.168.100.100```). You should see the latency you configured.

### Running experiments with emulated delay
- connect using one of the provided blue ethernet cables from your laptop to ports 1-4 of client-sw, and turn off other networks like WiFi
- change the latency of the delay emulator server to the desired one for experimentation
- go to https://dash.erg.abdn.ac.uk

### Running experiments over the satellite link
- connect using one of the provided green ethernet cable from your laptop to ports FN3/2/041 on the wall to the left of the testbed. This will give you an connection over the satellite network.
- check this has worked by pinging from your laptop (```ping 8.8.8.8```). You should see a latency of around 640ms.
- Go to https://dash.erg.abdn.ac.uk

### Very simple waterfall diagrams
- in Firefox, open the developer tools using F12, and navigate to the network tab.
- after watching the desired length of any DASH video, click the settings button and select 'Export as HAR' file. A similar procedure is available in the Developer tools for Google Chrome.
- the HAR files can be visualised here: http://www.softwareishard.com/har/viewer/

## Testbed diagram
<img width="1957" height="1857" alt="testbed-oct-25" src="https://github.com/user-attachments/assets/f326c4d2-3291-4107-a233-7ba431da72a9" />

Download the diagram: [testbed-oct-25.pdf](https://github.com/user-attachments/files/25049991/testbed-oct-25.pdf)

## Current host server directory structure
```
var/
└─ www/
    └─ html/
        ├─ index.html
        ├─ vid1/
        │   └─ vid1.mpd
        └─ vid2/
            └─ vid2.mpd

```
