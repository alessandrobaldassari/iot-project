#ifndef SENDACK_H
#define SENDACK_H

// pan coordinator ID
#define PAN_COORD 1

// pan coordinator support constants
#define MAX_NODES 8
#define MAX_TOPICS 3
#define ID_TOPICS_QOS 7
#define OFFSET 3
#define ID 0

// message type
#define CONNECT 1
#define SUBSCRIBE 2
#define PUBLISH 3

// QoS
#define QOS 1
#define NO_QOS 0

// node status
#define DISCONNECTED 0
#define CONNECTED 1
#define SUBSCRIBED 2

// topic
#define TEMPERATURE 1
#define HUMIDITY 2
#define LUMINOSITY 3

//timer
#define NODE_TIMER 56789
#define PAN_TIMER 450

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

typedef nx_struct pub_msg{
	nx_uint8_t msg_type;
	nx_uint16_t msg_id;
    nx_uint8_t topic;
    nx_uint16_t value;
    nx_uint8_t qos;
} pub_msg_t;

enum{
    AM_MY_MSG = 6
};

#endif
