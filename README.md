## What is netdump-devel?
netdump-devel package provides the header files needed to develop a custom dissector for the netdump CLI tool (repo: https://github.com/giorgiopapini/netdump).

⚠️ To compile your custom dissector correctly, the netdump CLI tool must be installed in your system.

## Installation
netdump-devel can be installed manually using make, or installed by using a package manager (RPM on Fedora, CentOS and RHEL).
You can install netdump-devel in those ways:

1) Install the program using ```sudo make install``` after cloning the repo.
2) Install the program using a package manager.

## Compile a custom dissector
To compile a custom dissector as a shared lib the ```libnetdump.so``` is required. This library is installed during the netdmup CLI tool installation process

⚠️ ```libnetdump.so``` must be located inside ```/usr/lib``` or ```/usr/lib64``` or ```usr/local/lib``` or ```usr/local/lib64```. If the shared library is inside ```usr/local/...```, you may need to configure your system to look for libraries inside ```usr/local/...``` directory. Otherwise during compilation with the ```-lnetdump``` flag on, the system may not find the ```libnetdump.so``` library.

To compile your custom dissectors as a shared lib ```(.so)``` follow these steps:

1) Navigate to the folder in which ```your_dissector.c``` file is stored.
2) Run ```gcc -fPIC -shared -o your_dissector.so your_dissector.c -lnetdump```.

Once ```your_dissector.so``` is compiled, run netdump CLI tool and execute ```dissectors -add "path-to-your-dissector"```.
Custom dissectors will be stored inside ```~.local/lib/netdump/custom_dissectors/``` directory.

Now your custom dissector is correctly loaded inside netdump and it is ready to use.

## Create your first custom dissector
Once you installed the netdump-devel package, you can start developing your custom dissector by creating a new ```.c``` file and including the ```<netdump.h>``` library.
```c
#include <netdump.h>
```
Any function can be named as the developer wishes, but ```protocol_handler_mapping **get_custom_protocols_mapping()``` must be named exactly this way. This is because it serves as the API that the netdump CLI tool executes.

The basic structure of a dissector is the following (example of a custom IPv4 dissector):
```c
#include <netdump.h>
#include <netdump/ethertypes.h>

void print_ipv4(const uint8_t *pkt, uint32_t len) {
    ...
}

void visualize_ipv4(const uint8_t *pkt, uint32_t len) {
    ...
}

protocol_info dissect_ipv4(const uint8_t *pkt, uint32_t pkt_len, output_format fmt) {
    SHOW_OUTPUT(pkt, pkt_len, fmt, print_ipv4, visualize_ipv4);
    return (protocol_info){ 
        .protocol = (*((uint8_t *)(pkt + 9))),
        .offset = ((*((uint8_t *)(pkt)) & 0x0f) * 4), 
        .proto_table_num = IP_PROTOS
    };
}

protocol_handler_mapping **get_custom_protocols_mapping() {
    protocol_handler_mapping **arr = create_mappings_arr();
    
    add_mapping(
        &arr,
        create_protocol_handler_mapping(
            create_protocol_handler(ETHERTYPE_IP, PROTOCOL_LAYER_NETWORK, dissect_ipv4, "IPv4"),
            ETHERTYPES
        )
    );
    /* You can add as many mappings as you want for a single protocol */ 

    return arr;
}
```
The code is mainly divided in 4 macro areas:
1) ```void print_ipv4(const uint8_t *pkt, uint32_t len)```
2) ```visualize_ipv4(const uint8_t *pkt, uint32_t len)```
3) ```protocol_info dissect_ipv4(const uint8_t *pkt, uint32_t pkt_len, output_format fmt)```
4) ```protocol_handler_mapping **get_custom_protocols_mapping()```
<br><br>
### ```void print_ipv4(const uint8_t *pkt, uint32_t len)```
Everything the developer wants to display, and how it should be shown when the ```-output std``` mode is selected, should be defined in this function.
The logic contained inside this function can range from simple, constant printf statements to more complex output handling.
The following code provides an example of a ```void print_proto_name()``` function, using IPv4 as a reference.

⚠️ ```ntohs```, ```ntohl``` or any other standard or non standard function should be included manually by the custom dissector developer.
```c
#define IP_HLEN(pkt)            (*((uint8_t *)(pkt)) & 0x0f)
#define IP_VERSION(pkt)         (*((uint8_t *)(pkt)) >> 4)
#define IP_TOS(pkt)             (*((uint8_t *)(pkt + 1)))
#define IP_TOTLEN(pkt)          (*((uint16_t *)(pkt + 2)))     
#define IP_ID(pkt)              (*((uint16_t *)(pkt + 4)))
#define IP_OFFSET(pkt)          (*((uint16_t *)(pkt + 6)))
#define IP_MF                   0x2000  /* 14th bit */
#define IP_DF                   0x4000  /* 15th bit */
#define IP_RF                   0x8000  /* 16th bit */
#define IP_OFFSET_MASK          0x1fff  /* last 13 bits reserved for the offset field */
#define IP_TTL(pkt)             (*((uint8_t *)(pkt + 8)))
#define IP_PROTOCOL(pkt)        (*((uint8_t *)(pkt + 9)))
#define IP_CHECKSUM(pkt)        (*((uint16_t *)(pkt + 10)))
#define IP_SRC_ADDR(pkt)        (*((uint32_t *)(pkt + 12)))
#define IP_DEST_ADDR(pkt)       (*((uint32_t *)(pkt + 16)))

void print_ipv4(const uint8_t *pkt, uint32_t len) {
    char flags[9] = "";  /* max: "DF, MF, \0" */

    /* ===================== printing src (IP) > dest (IP) ====================== */
    print_ipv4(ntohl(IP_SRC_ADDR(pkt)));
    printf(" > ");
    print_ipv4(ntohl(IP_DEST_ADDR(pkt)));
    /* ========================================================================== */

    printf(
        " tos: 0x%01x, ttl: %d, id: %d, offset: %d,", 
        IP_TOS(pkt), 
        IP_TTL(pkt), 
        ntohs(IP_ID(pkt)),
        ntohs(IP_OFFSET(pkt)) & IP_OFFSET_MASK
    );

    /* ============================= printing flags ============================= */
    printf(" flags: [");
    if (ntohs(IP_OFFSET(pkt)) & IP_DF) strcat(flags, "DF, ");
    if (ntohs(IP_OFFSET(pkt)) & IP_MF) strcat(flags, "MF, ");
    flags[strlen(flags) - 2] = '\0';    /* remove last ", " chars */
    printf("%s],", flags);
    /* ========================================================================== */

    printf(" proto: %d", IP_PROTOCOL(pkt));
}
```
The output is (for example):
``` 192.168.1.20 > 239.255.255.250 tos: 0x0, ttl: 4, id: 50262, offset: 0, flags: [], proto: 17 ```
<br><br>
### ```void visualize_ipv4(const uint8_t *pkt, uint32_t len)```
Everything the developer wants to display, and how it should be shown when the ```-output art``` mode is selected, should be defined in this function.
To use the visualizer helper functions the developer must include the module mentioned below.
```c
#include <netdump/visualizer.h>
```
The module is composed by those functions:
1) ```void start_printing()``` marks the beginning of the enclosure where fields are printed.
2) ```void end_printing()``` marks the end of the enclosure where fields are printed.
3) ```void print_field(char *label, char *content, int newline)``` used to print a specfic field in ascii art.
4) ```void print_additional_info(char *info)``` used to print additional infos before printing the fields.

⚠️ ```ntohs```, ```ntohl``` or any other standard or non standard function should be included manually by the custom dissector developer.

The following code provides an example of a ```void visualize_proto_name()``` function, using IPv4 as a reference.
```c
void visualize_ipv4(const uint8_t *pkt, uint32_t len) {
    char version[4];
    char ihl[4];
    char tos[5];  /* 0x00'\0' are 5 chars */
    char totlen[6];  /* 16 bit ==> max = 65536 (5 chars + '\0') */
    char id[6];
    char rf[2];
    char df[2];
    char mf[2];
    char offset_frag[14];
    char ttl[4];
    char protocol[4];  /* xxx'\0' */
    char checksum[7];  /* 0x0000'\0' are 7 chars */
    char src_addr[IP_ADDR_STR_LEN];
    char dest_addr[IP_ADDR_STR_LEN];

    snprintf(version, sizeof(version), "%u", IP_VERSION(pkt));
    snprintf(ihl, sizeof(ihl), "%u", IP_HLEN(pkt));
    snprintf(tos, sizeof(tos), "0x%02x", IP_TOS(pkt));
    snprintf(totlen, sizeof(totlen), "%u", ntohs(IP_TOTLEN(pkt)));
    snprintf(id, sizeof(id), "%u", ntohs(IP_ID(pkt)));
    snprintf(rf, sizeof(rf), "%u", (ntohs(IP_OFFSET(pkt)) & IP_RF) ? 1 : 0);
    snprintf(df, sizeof(df), "%u", (ntohs(IP_OFFSET(pkt)) & IP_DF) ? 1 : 0);
    snprintf(mf, sizeof(mf), "%u", (ntohs(IP_OFFSET(pkt)) & IP_MF) ? 1 : 0);
    uint_to_bin_str(offset_frag, (ntohs(IP_OFFSET(pkt)) & IP_OFFSET_MASK), sizeof(offset_frag));
    snprintf(ttl, sizeof(ttl), "%u", IP_TTL(pkt));
    snprintf(protocol, sizeof(protocol), "%u", IP_PROTOCOL(pkt));
    
    snprintf(checksum, sizeof(checksum), "0x%04x", ntohs(IP_CHECKSUM(pkt)));
    snprintf(src_addr, IP_ADDR_STR_LEN, IP_ADDR_FORMAT, IP_TO_STR(ntohl(IP_SRC_ADDR(pkt))));
    snprintf(dest_addr, IP_ADDR_STR_LEN, IP_ADDR_FORMAT, IP_TO_STR(ntohl(IP_DEST_ADDR(pkt))));

    start_printing();
    print_additional_info("Options fields not represented in ascii art");
    print_field("Version", version, 0);
    print_field("IHL", ihl, 0);
    print_field("Type of Service", tos, 0);
    print_field("Total Length", totlen, 0);
    print_field("Identification", id, 0);
    print_field("RF", rf, 0);
    print_field("DF", df, 0);
    print_field("MF", mf, 0);
    print_field("Fragment Offset", offset_frag, 0);
    print_field("Time to Live", ttl, 0);
    print_field("Protocol", protocol, 0);
    print_field("Checksum", checksum, 0);
    print_field("Source Address", src_addr, 0);
    print_field("Destination Address", dest_addr, 0);
    end_printing();
}
```
The output is (for example):
```
(IPv4) 
(Options fields not represented in ascii art)
*-----------*-------*-------------------*----------------*------------------*
|  Version  |  IHL  |  Type of Service  |  Total Length  |  Identification  |
|     4     |   5   |       0x00        |      480       |      62838       |
*------*------*------*-------------------*----------------*------------*----*
|  RF  |  DF  |  MF  |  Fragment Offset  |  Time to Live  |  Protocol  |
|  0   |  0   |  0   |   0000000000000   |       4        |     17     |
*------------*------------------*-----------------------*-*------------*
|  Checksum  |  Source Address  |  Destination Address  |
|   0x0ded   |   192.168.1.7    |    239.255.255.250    |
*------------*------------------*-----------------------*
```
<br><br>
### ```protocol_info dissect_ipv4(const uint8_t *pkt, uint32_t pkt_len, output_format fmt)```
This function will be called by netdump when it determines that a specific byte string must be dissected using the custom dissector (based on the mapping process explained in the next section).
The macro ```SHOW_OUTPUT(...)``` is used to execute the appropriate formatting function, previously defined by the dissector developer, based on the output format.
```c
SHOW_OUTPUT(pkt, pkt_len, fmt, print_ipv4, visualize_ipv4);
```
The following code provides an example of a ```protocol_info dissect_ipv4(const uint8_t *pkt, uint32_t pkt_len, output_format fmt)``` function, using IPv4 as a reference.
```c
protocol_info dissect_ipv4(const uint8_t *pkt, uint32_t pkt_len, output_format fmt) {
    SHOW_OUTPUT(pkt, pkt_len, fmt, print_ipv4, visualize_ipv4);
    return (protocol_info){ 
        .protocol = (*((uint8_t *)(pkt + 9))),
        .offset = ((*((uint8_t *)(pkt)) & 0x0f) * 4), 
        .proto_table_num = IP_PROTOS
    };
}
```
The function returns a ```(protocol_info)``` object that represents the encapsulated protocol, including its value, the starting byte, and the protocol table ID where netdump should look for the ```dissect_encap_proto_name(...)``` function.
(e.g. an IPv4 packet may encapsulate a TCP packet. The data needed to execute netdump recursevly on that encapsulated packet are: The protocol value contained inside the IPv4 protocol field, the encapsulated packet starting byte and the table ID in which netdump should search for dissect_tcp function).

The currently supported protocol tables ID are defined in ```<netdump/protocol.h>``` (the actual tables are defined inside netdump CLI tool and loaded at runtime):
``` c
#define DLT_PROTOS          1  /* protocols that are encapsulated in the datalink frame */ 
#define ETHERTYPES          2  /* It maps ethertypes to protocols identified by an ethertype (e.g. ETHERTYPE_IP maps to dissect_ipv4 function) */
#define IP_PROTOS           3  /* It maps the values contained in the IP 'protocol' field to protocols identified by those values (e.g. IPPROTO_TCP maps to dissect_tcp function) */
#define NET_PORTS           4  /* It maps the network ports to the desired or known service (e.g. PORT_HTTP maps to dissect_http function) */
#define NLPID_PROTOS        5  /* It maps nlpid values to the corresponding encap protocol (e.g. NLPID_PPP maps to dissectp_ppp function) */
#define PPP_PROTOS          6  /* It maps ppp values to the corresponding encap protocol (e.g. PPP_IP maps to dissect_ip function)*/
```

⚠️ A ```dissect_proto()``` function can be mapped to multiple tables simultaneously (e.g. dissect_ipv4 is linked to ETHERTYPES table by the ETHERTYPE_IP value but also linked to NLPID_PROTOS by the NLPID_IP value)
<br><br>
### ```protocol_handler_mapping **get_custom_protocols_mapping()```
This function acts as the entry point to your custom dissector, netdump will use this function to collect information, process the mapping, and load the custom dissector into memory.

⚠️ *DO NOT* change the name to this function, otherwise netdump will not be able to access the shared library correctly.

1) ```protocol_handler_mapping **create_mappings_arr()``` used to initialize a mappings array
2) ```void add_mapping(protocol_handler_mapping ***arr_ptr, protocol_handler_mapping *new_mapping)``` used to add a mapping to the mappings array
3) ```protocol_handler_mapping *create_protocol_handler_mapping(protocol_handler *handler, int proto_table_num)``` used to initialize and populate a mapping
4) ```protocol_handler *create_protocol_handler(int proto, protocol_layer layer, protocol_info (*dissect_proto)(const uint8_t *pkt, uint32_t pkt_len, output_format fmt), const char *protocol_name)``` used to initialize and populate the custom dissector

The following code provides an example of a ```protocol_handler_mapping **get_custom_protocols_mapping()``` function, using IPv4 as a reference.
```c
protocol_handler_mapping **get_custom_protocols_mapping() {
    protocol_handler_mapping **arr = create_mappings_arr();
    
    add_mapping(
        &arr,
        create_protocol_handler_mapping(
            create_protocol_handler(ETHERTYPE_IP, PROTOCOL_LAYER_NETWORK, dissect_ipv4, "IPv4"),
            ETHERTYPES
        )
    );

    return arr;
}
```
Basically, the custom dissector developer should create the custom dissector (protocol_handler) containing all the necessary information about the protocol to be dissected. Then, he establishes a mapping between the custom dissector and the protocol table ID in which it should be placed. Finally, the mapping is added to the array of mappings and returned to netdump. (netdump will dissect a packet, identify the encapsulated protocol value, search for it in the appropriate protocol table, and if the value matches a custom dissector, it will execute the ```dissect_protocol()``` function defined by the developer).

The dissector developer can include libraries such as ```<netdump/ethertypes.h>``` or ```<netdump/ip_protos.h>``` to access labels related to protocols present inside the corresponding protocol table (in netdump). Other headers are available inside the netdump folder in ```/usr/include```. (e.g. ETHERTYPE_IP is defined inside ```<netdump/ethertypes.h>```, so the developer must include it).

⚠️ The ```protocol_layer``` inside ```create_protocol_handler()``` is used for filtering purposes. For example, if a dissector is flagged with PROTOCOL_LAYER_NETWORK, its output will not be printed in netdump unless explicitly specified using the ```-a``` flag ("a" for "application layer").
