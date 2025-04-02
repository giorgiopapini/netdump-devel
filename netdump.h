#ifndef NETDUMP_LIB_H
#define NETDUMP_LIB_H

#include "netdump/protocol.h"

#define PRINT_FUNC_NAME(name)           print_##name
#define VISUALIZE_FUNC_NAME(name)       visualize_##name

#define PRINT_PROTO(name) \
        void PRINT_FUNC_NAME(name)(const uint8_t *pkt, uint32_t len)

#define VISUALIZE_PROTO(name) \
        void VISUALIZE_FUNC_NAME(name)(const uint8_t *pkt, uint32_t len)


protocol_handler_mapping **get_custom_protocols_mapping();

#endif
