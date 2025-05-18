## What is netdump-devel?
netdump-devel package provides the header files needed to develop a custom dissector for the netdump CLI tool (repo: https://github.com/giorgiopapini/netdump).

⚠️ To compile your custom dissector correctly, the netdump CLI tool must be installed in your system.

## Makefile configuration
Check the default Makefile variable configuration using ```make show-config```.
If your system stores those files in different locations, you can run ```make install VARIABLE_NAME='/path/'``` to specify the right path.

Remember that these commands might need to be run with elevated privileges.

## Installation
netdump-devel can be installed manually using make, or installed by using a package manager (RPM on Fedora, CentOS and RHEL).
You can install netdump-devel in those ways:

1) Install the program using ```make install``` after cloning the repo.
2) Install the program using a package manager.

Remember that these commands might need to be run with elevated privileges.

## Compile a custom dissector (Linux)
This is specific to Linux, but the main process remains the same across all systems. Only the directories and shared library files may differ.
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
    if (!pkt || pkt_len < ((pkt[0] & 0x0f) * 4)) return NO_ENCAP_PROTO;

    SHOW_OUTPUT(pkt, pkt_len, fmt, print_ipv4, visualize_ipv4);
    return (protocol_info){ 
        .protocol = (pkt[9]),
        .offset = ((pkt[0] & 0x0f) * 4), 
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
#define NP_IP_HLEN(pkt)         (pkt[0] & 0x0f)
#define NP_IP_VERSION(pkt)      (pkt[0] >> 4)
#define NP_IP_TOS(pkt)          (pkt[1])
#define NP_IP_TOTLEN(pkt)       ((uint16_t)(pkt[2] << 8) | (uint16_t)pkt[3])
#define NP_IP_ID(pkt)           ((uint16_t)(pkt[4] << 8) | (uint16_t)pkt[5])
#define NP_IP_OFFSET(pkt)       ((uint16_t)(pkt[6] << 8) | (uint16_t)pkt[7])
#define NP_IP_MF                0x2000  /* 14th bit */
#define NP_IP_DF                0x4000  /* 15th bit */
#define NP_IP_RF                0x8000  /* 16th bit */
#define NP_IP_OFFSET_MASK       0x1fff  /* last 13 bits reserved for the offset field */
#define NP_IP_TTL(pkt)          (pkt[8])
#define NP_IP_PROTOCOL(pkt)     (pkt[9])
#define NP_IP_CHECKSUM(pkt)     ((uint16_t)(pkt[10] << 8) | (uint16_t)pkt[11])
#define NP_IP_SRC_ADDR(pkt)     ((uint32_t)(pkt[12] << 24) | (uint32_t)(pkt[13] << 16) | (uint32_t)(pkt[14] << 8) | (uint32_t)pkt[15])
#define NP_IP_DEST_ADDR(pkt)    ((uint32_t)(pkt[16] << 24) | (uint32_t)(pkt[17] << 16) | (uint32_t)(pkt[18] << 8) | (uint32_t)pkt[19])

```c
void print_ip_hdr(const uint8_t *pkt, size_t pkt_len) {
    char flags[9] = { 0 };  /* max: "DF, MF, \0" */
    int raw_offset = 0;
    size_t offset = 0;

    if (!pkt || pkt_len < ((pkt[0] & 0x0f) * 4)) return;

    /* ===================== printing src (IP) > dest (IP) ====================== */
    print_ipv4(NP_IP_SRC_ADDR(pkt));
    printf(" > ");
    print_ipv4(NP_IP_DEST_ADDR(pkt));
    /* ========================================================================== */

    printf(
        " tos: 0x%01x, ttl: %d, id: %d, offset: %d,", 
        NP_IP_TOS(pkt), 
        NP_IP_TTL(pkt), 
        NP_IP_ID(pkt),
        NP_IP_OFFSET(pkt) & NP_IP_OFFSET_MASK
    );

    /* ============================= printing flags ============================= */
    printf(" flags: [");
    if (NP_IP_OFFSET(pkt) & NP_IP_DF)
        raw_offset = snprintf(flags + offset, sizeof(flags) - offset, "DF, ");
    if (NP_IP_OFFSET(pkt) & NP_IP_MF)
        raw_offset = snprintf(flags + offset, sizeof(flags) - offset, "MF, ");
    if (0 <= raw_offset) offset = (size_t)raw_offset;
    if (2 <= offset) flags[offset - 2] = '\0';
    printf("%s],", flags);
    /* ========================================================================== */

    printf(" proto: %d", NP_IP_PROTOCOL(pkt));
    
    /*if (IP_HLEN(pkt) > 5) print_ip_options(pkt);*/
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
1) ```void start_printing(void)``` marks the beginning of the enclosure where fields are printed.
2) ```void end_printing(void)``` marks the end of the enclosure where fields are printed.
3) ```void print_field(const char *label, const char *content, int newline)``` used to print a specfic field in ascii art.
4) ```void print_additional_info(const char *info)``` used to print additional infos before printing the fields.

⚠️ ```ntohs```, ```ntohl``` or any other standard or non standard function should be included manually by the custom dissector developer.

The following code provides an example of a ```void visualize_proto_name()``` function, using IPv4 as a reference.
```c
void visualize_ip_hdr(const uint8_t *pkt, size_t pkt_len) {
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

    if (!pkt || pkt_len < ((pkt[0] & 0x0f) * 4)) return;
    
    snprintf(version, sizeof(version), "%u", NP_IP_VERSION(pkt));
    snprintf(ihl, sizeof(ihl), "%u", NP_IP_HLEN(pkt));
    snprintf(tos, sizeof(tos), "0x%02x", NP_IP_TOS(pkt));
    snprintf(totlen, sizeof(totlen), "%u", NP_IP_TOTLEN(pkt));
    snprintf(id, sizeof(id), "%u", NP_IP_ID(pkt));
    snprintf(rf, sizeof(rf), "%u", (NP_IP_OFFSET(pkt) & NP_IP_RF) ? 1 : 0);
    snprintf(df, sizeof(df), "%u", (NP_IP_OFFSET(pkt) & NP_IP_DF) ? 1 : 0);
    snprintf(mf, sizeof(mf), "%u", (NP_IP_OFFSET(pkt) & NP_IP_MF) ? 1 : 0);
    uint_to_bin_str(offset_frag, (NP_IP_OFFSET(pkt) & NP_IP_OFFSET_MASK), sizeof(offset_frag));
    snprintf(ttl, sizeof(ttl), "%u", NP_IP_TTL(pkt));
    snprintf(protocol, sizeof(protocol), "%u", NP_IP_PROTOCOL(pkt));
    
    snprintf(checksum, sizeof(checksum), "0x%04x", NP_IP_CHECKSUM(pkt));
    snprintf(src_addr, IP_ADDR_STR_LEN, IP_ADDR_FORMAT, IP_TO_STR(NP_IP_SRC_ADDR(pkt)));
    snprintf(dest_addr, IP_ADDR_STR_LEN, IP_ADDR_FORMAT, IP_TO_STR(NP_IP_DEST_ADDR(pkt)));

    start_printing();
    print_additional_info("Options fields not represented in ascii art");
    print_field(IP_VERSION_LABEL, version, 0);
    print_field(IP_IHL_LABEL, ihl, 0);
    print_field(IP_TOS_LABEL, tos, 0);
    print_field(IP_TOTLEN_LABEL, totlen, 0);
    print_field(IP_ID_LABEL, id, 0);
    print_field(IP_RF_LABEL, rf, 0);
    print_field(IP_DF_LABEL, df, 0);
    print_field(IP_MF_LABEL, mf, 0);
    print_field(IP_OFFSET_LABEL, offset_frag, 0);
    print_field(IP_TTL_LABEL, ttl, 0);
    print_field(IP_PROTOCOL_LABEL, protocol, 0);
    print_field(IP_CHECKSUM_LABEL, checksum, 0);
    print_field(IP_SRC_ADDR_LABEL, src_addr, 0);
    print_field(IP_DEST_ADDR_LABEL, dest_addr, 0);
    end_printing();
}
```
The output is (for example):
```
(IPv4)
(Options fields not represented in ascii art)
•───────────•───────•───────────────────•────────────────•──────────────────•
│  Version  │  IHL  │  Type of Service  │  Total Length  │  Identification  │
│     4     │   6   │       0xc0        │       32       │        0         │
•──────•──────•──────•───────────────────•────────────────•────────────•────•
│  RF  │  DF  │  MF  │  Fragment Offset  │  Time to Live  │  Protocol  │
│  0   │  1   │  0   │   0000000000000   │       1        │     2      │
•────────────•──────────────────•───────────────────────•─•────────────•
│  Checksum  │  Source Address  │  Destination Address  │
│   0x3236   │   192.168.1.63   │    239.255.255.250    │
•────────────•──────────────────•───────────────────────•
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
    if (!pkt || pkt_len < ((pkt[0] & 0x0f) * 4)) return NO_ENCAP_PROTO;
    
    SHOW_OUTPUT(pkt, pkt_len, fmt, print_ipv4, visualize_ipv4);
    return (protocol_info){ 
        .protocol = (pkt[9]),
        .offset = ((pkt[0] & 0x0f) * 4), 
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
