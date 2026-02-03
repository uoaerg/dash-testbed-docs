# ERG DASH testbed overview and how-tos
## Testbed diagram
![testbed-oct-25](https://github.com/user-attachments/assets/09e859fd-bf65-4b87-a9b2-5fa144b1f91b)

Download the diagram: [testbed-oct-25.pdf](https://github.com/user-attachments/files/25049991/testbed-oct-25.pdf)
## Testbed picture
![IMG_3650](https://github.com/user-attachments/assets/dbf73375-3ff2-4ca1-a368-761e4e9decb7)

- All <span style="color:red">RED</span> cables connect interfaces in the network 137.50.17.0/24 (the public "Internet" network)
- All <span style="color:blue">BLUE</span> cables connect interfaces in the network 192.168.99.0/24 (the private "local" network)
- There is one <span style="color:yellow">YELLOW</span> cable indicating a "mirror" interface, which mirrors traffic intended for the quic/dash server (coming from both internet and local paths)  to the pcap-store.
