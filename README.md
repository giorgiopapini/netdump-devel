## What is netdump-devel?
netdump-devel package provides the header files needed to develop a custom dissector for the netdump CLI tool (repo: https://github.com/giorgiopapini/netdump).

⚠️ To compile your custom dissector correctly, the netdump CLI tool must be installed in your system.

## Installation
netdump-devel can be installed manually using make, or installed by using a package manager (RPM on Fedora, CentOS and RHEL).
You can install netdump-devel in those ways:

1) Install the program using ```sudo make install``` after cloning the repo.
2) Install the program using a package manager.

## Compile a custom dissector
To compile a custom dissector as a shared lib the ```libnetdump.so``` shared lib is required. This library is installed during the netdmup CLI tool installation process

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
