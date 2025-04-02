#ifndef NETDUMP_LIB_VISUALIZER_H
#define NETDUMP_LIB_VISUALIZER_H

void start_printing();
void end_printing();
void print_field(char *label, char *content, int newline);
void print_additional_info(char *info);

#endif