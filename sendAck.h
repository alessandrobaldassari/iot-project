#ifndef SENDACK_H
#define SENDACK_H

// pan coordinator id
#define PAN_COORD 1

// maximum number of nodes connected to the pan coordinator + pan coordinator
#define MAX_NODES 8
#define DELTA 2
#define ID_AND_TOPICS 4

// message type
#define CONNECT 1
#define SUBSCRIBE 2
#define PUBLISH 3

// node status
#define DISCONNECTED 0
#define CONNECTED 1
#define SUBSCRIBED 2
#define PUBLISHING 3

// topic
#define TEMPERATURE 0
#define HUMIDITY 1
#define LUMINOSITY 2

typedef nx_struct conn_msg{
	nx_uint8_t msg_type;
	nx_uint16_t msg_id;
} conn_msg_t;

typedef nx_struct sub_msg{
	nx_uint8_t msg_type;
	nx_uint16_t msg_id;
    nx_uint8_t dev_id;
    nx_uint8_t temp, temp_qos;
    nx_uint8_t hum, hum_qos;
    nx_uint8_t lum, lum_qos;
} sub_msg_t;

enum{ AM_MY_MSG = 6 };

#endif
