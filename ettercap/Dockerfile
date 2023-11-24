# Dockerfile container ettercap, sslsplit and tcpdump for network analysis
FROM ubuntu:20.04

# Set environment variables
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update
RUN apt install -y ettercap-common
# Install SSLsplit
RUN apt-get install -y sslsplit

# Install tcpdump
RUN apt-get install -y tcpdump

# Install nmap
RUN apt-get install -y nmap

# Clean up
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /ettercap

# Set the entry point to start a shell
CMD ["/bin/bash"]
