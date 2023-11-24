# Keycloak_Compose

This prject is a sample project using Step-CA to initialise and install SSL certificates on containers running Keycloak and an ASP.NET Core 6 web application, to use Keycloak as access manager to the web application.

The process is as follows:

* The Smallstep CA container is booted. An initialisation script is included, which creates a root certificate.
* The root certificate is used by the Step-CLI container (certificate_generator) to generate SSL certificates for the Keycloak instance. This is because the KC image is secure (locaked down), which means we are unable to install the Step CLI client on the container to bootstrap the certificates. The generated certificates are made available to the KC container for use, which is configured through the command line: 

`
/opt/keycloak/bin/kc.sh start --log-level=warn --hostname-url=https://keycloak.example --https-certificate-file=/home/keycloak_certs/keycloak.crt --https-certificate-key-file=/home/keycloak_certs/keycloak.key --import-realm
`

-> does the KC container need to have the certificates added to the trust store? I don't think so - I think passing the certs to the command should do the necessary, otherwise what's the point of the parameters?

 The root certificate is also used by the webapp container to bootstrap itself to the Step CA and obtain a leaf certificate. This certificate is converted into .pkcs format and moved into a location on the container. The webapp expects the certificates to be at this (hardcoded) location and loads them accordingly.

 As the certificates are generated on each run, it is advised to use the `start.sh` script instead of `docker-compose up`, so that the certficates are re-generated accordingly.

 The `gostwire` and `edgeshark` images are part of the [Edgeshark project](https://edgeshark.siemens.io) and allow easy(ish) use of Wireshark within a Docker-compose network. As it stands, it allows easy image-based analysis of a Docker network setup. In order to capture packet traces, the host computer must install both [Wireshark](https://www.wireshark.org/) and the [csharg Extcap Plugin for Wireshark](https://github.com/siemens/cshargextcap/releases/tag/v0.9.8), which allows Wireshark to listen on the Docker interfaces. The Docker containers should then appear as an selectable interface in the Wireshark GUI.

 KC uses TLS 1.3 by default. In order to set up the .NET application correctly, we need to modify the startup options to force usage of TLS 1.2. In this project, we also specify which certificate to use on startup:

         public static IHostBuilder CreateHostBuilder(string[] args) =>
            Host.CreateDefaultBuilder(args)
            .ConfigureAppConfiguration((hostingContext, config) =>
            {
                config.AddJsonFile("appsettings.json").AddEnvironmentVariables();
            })
            .ConfigureWebHostDefaults(webBuilder =>
            {
                webBuilder.UseStartup<Startup>();
                webBuilder.ConfigureKestrel(serverOptions => {
                    serverOptions.ConfigureHttpsDefaults(co => {
                        co.SslProtocols = SslProtocols.Tls12;
                    });
                });
            })
            .ConfigureWebHost((host) => {
                var certificate = new X509Certificate2("/certs/aspnet_core.pfx", "hello");
                host.ConfigureKestrel((context, options) => {
                    options.ListenAnyIP(5001, ListenOptions => {
                        ListenOptions.UseHttps(new HttpsConnectionAdapterOptions
                        {
                            ServerCertificate = certificate
                        });
                    });
                });
            });


## MITM container

The MITM container is set up to try and sniff the network traffic between the Keycloak and ASP.NET containers to debug the SSL connections. This requires the container to be a privileged container, which means it has the access of the host computer:

>
The --privileged flag gives all capabilities to the container, and it also lifts all the limitations enforced by the device cgroup controller. In other words, the container can then do almost everything that the host can do. This flag exists to allow special use-cases, like running Docker within Docker. 



The network can be scanned from the mitm container using `nmap -sn 172.18.0.0/32`.
The traffic between the keycloak and ASP containers can be sniffed (one-way) by using the command: `ettercap -i eth0 -T -M arp:remote /172.18.0.6// /172.18.0.8//`. 
This provides a log that looks like:

<code>
    
ettercap 0.8.3 copyright 2001-2019 Ettercap Development Team

Listening on:
  eth0 -> 02:42:AC:12:00:07
          172.18.0.7/255.255.0.0


SSL dissection needs a valid 'redir_command_on' script in the etter.conf file
Privileges dropped to EUID 65534 EGID 65534...

  34 plugins
  42 protocol dissectors
  57 ports monitored
24609 mac vendor fingerprint
1766 tcp OS fingerprint
2182 known services
Lua: no scripts were specified, not starting up!

Scanning for merged targets (2 hosts)...

* |==================================================>| 100.00 %

2 hosts added to the hosts list...

ARP poisoning victims:

 GROUP 1 : 172.18.0.6 02:42:AC:12:00:06

 GROUP 2 : 172.18.0.8 02:42:AC:12:00:08
Starting Unified sniffing...


Text only Interface activated...
Hit 'h' for inline help



Fri Nov 24 15:52:25 2023 [681232]
UDP  172.18.0.6:41276 --> 239.6.7.8:46655 |  (86)
(...........}2.Y.?l.._bG......8......}2.Y.?l.._bG...9.<..ISPN..
......}2.Y.?l.._bG....

Fri Nov 24 15:52:30 2023 [471751]
UDP  172.18.0.6:41276 --> 239.6.7.8:46655 |  (86)
(...........}2.Y.?l.._bG......8......}2.Y.?l.._bG...9.<..ISPN..
......}2.Y.?l.._bG....

</code>

SSLstrip can then be used to strip the SSL encryption, and then re-encrypt using the certificates in the mounted volume.