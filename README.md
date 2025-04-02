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

1) Navigate to the folder in which is stored ```your_dissector.c``` file.
2) Run ```gcc -fPIC -shared -o your_dissector.so your_dissector.c -lnetdump```.

Once ```your_dissector.so``` is compiled, run netdump CLI tool and execute ```dissectors -add "path-to-your-dissector"```.
Now your custom dissector is correctly loaded inside netdump and it is ready to use.

## Create your first custom dissector
Once you installed the netdump-devel package, you can start developing your custom dissector by creating a new ```.c``` file and including the ```<netdump.h>``` library.
```c
#include <netdump.h>
```
Any function can be named as the developer wishes, but ```protocol_handler_mapping **get_custom_protocols_mapping()``` must be named exactly this way. This is because it serves as the API that the Netdump CLI tool executes, netdump specifically looks for this function by name.

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
