#include "sendAck.h"
#include "Timer.h"

module sendAckC{
	uses{
		interface Boot;
		interface AMPacket;
		interface Packet;
		interface PacketAcknowledgements;
		interface AMSend;
		interface SplitControl;
		interface Receive;
		interface Timer<TMilli> as MilliTimer;
	}
} 
implementation{
	uint8_t msg_counter=0;
	uint8_t rec_id;
	uint8_t node_status;
	message_t packet;
	
	task void sendConnectionRequest();
	
	// Task send connection request 
	task void sendConnectionRequest(){
		conn_msg_t* mess=(conn_msg_t*)(call Packet.getPayload(&packet,sizeof(conn_msg_t)));
		mess->msg_type = CONNECTION;
		mess->msg_id = msg_counter++;
	
		dbg("radio_send", "Try to send a CONNECTION request to PAN COORDINATOR at time %s \n", sim_time_string());
	
		call PacketAcknowledgements.requestAck(&packet);
	
		if(call AMSend.send(PAN_COORD,&packet,sizeof(conn_msg_t)) == SUCCESS){
			dbg("radio_send", "Packet passed to lower layer successfully!\n");
			dbg("radio_pack",">>>Pack\n \t Payload length %hhu \n", call Packet.payloadLength(&packet));
			dbg_clear("radio_pack","\t Source: %hhu \n ", call AMPacket.source(&packet));
			dbg_clear("radio_pack","\t Destination: %hhu \n ", call AMPacket.destination(&packet));
			dbg_clear("radio_pack","\t AM Type: %hhu \n ", call AMPacket.type(&packet));
			dbg_clear("radio_pack","\t\t Payload \n");
			dbg_clear("radio_pack", "\t\t msg_type: %hhu \n ", mess->msg_type);
			dbg_clear("radio_pack", "\t\t msg_id: %hhu \n", mess->msg_id);
			dbg_clear("radio_send", "\n ");
			dbg_clear("radio_pack", "\n");
		}
	}
	
	// MilliTimer interface  
	event void MilliTimer.fired(){
		post sendConnectionRequest();
	}
	
	// SplitControl interface
	event void SplitControl.startDone(error_t err){
		if(err == SUCCESS){	
			dbg("radio","Radio on!\n");
			if (TOS_NODE_ID != PAN_COORD){
				dbg("role","I'm node %hhu: start sending periodical CONNECTION request\n", TOS_NODE_ID);
				node_status = DISCONNECTED;
				dbg("role","Node status: %hhu (DISCONNECTED)\n", node_status);
				call MilliTimer.startPeriodic(800);
			}
			else if (TOS_NODE_ID == PAN_COORD){
				dbg("role","I'm node %hhu, the PAN COORDINATOR\n", TOS_NODE_ID);
			}
		}
		else{
			call SplitControl.start();
		}	
	}
	
	event void SplitControl.stopDone(error_t err){}
	
	// Boot interface 
	event void Boot.booted(){
		dbg("boot","Application booted.\n");
		call SplitControl.start();
	}
	// AMSend interface 
	event void AMSend.sendDone(message_t* buf,error_t err){
		if(&packet == buf && err == SUCCESS){
			dbg("radio_send", "Packet sent...");
			if (call PacketAcknowledgements.wasAcked(buf)){			
				dbg_clear("radio_ack", "and ack received\n");
				if(TOS_NODE_ID != PAN_COORD){
					if(node_status == DISCONNECTED){
						node_status = CONNECTED;
						dbg("radio_ack","Node status: %hhu (CONNECTED)\n", node_status);
					}
				}
				else if (TOS_NODE_ID == PAN_COORD){

				}			
				call MilliTimer.stop();
			} 
			else{
				dbg_clear("radio_ack", "but ack was not received");
				post sendConnectionRequest();
			}
			dbg_clear("radio_send", " at time %s \n", sim_time_string());
		}
	}
	
	// Receive interface 
	event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len){
		conn_msg_t* mess=(conn_msg_t*)payload;
		rec_id = mess->msg_id;
		
		if (TOS_NODE_ID == PAN_COORD){
			switch(mess->msg_type){
				case(CONNECTION):
					dbg("radio_rec","Message received at time %s \n", sim_time_string());
					dbg("radio_pack",">>>Pack \n \t Payload length %hhu \n", call Packet.payloadLength(buf));
					dbg_clear("radio_pack","\t Source: %hhu \n", call AMPacket.source(buf));
					dbg_clear("radio_pack","\t Destination: %hhu \n", call AMPacket.destination(buf));
					dbg_clear("radio_pack","\t AM Type: %hhu \n", call AMPacket.type(buf));
					dbg_clear("radio_pack","\t\t Payload \n");
					dbg_clear("radio_pack", "\t\t msg_type: %hhu \n", mess->msg_type);
					dbg_clear("radio_pack", "\t\t msg_id: %hhu \n", mess->msg_id);
					dbg_clear("radio_rec", "\n ");
					dbg_clear("radio_pack","\n");
					break;
				case(SUBSCRIBE):
					break;
				case(PUBLISH):
					break;
				default:
					dbg("radio_rec","Unknown message type: %hhu \n", mess->msg_type);
			}
		}
		
		return buf;
	}
}        
	
	
	
	
	
	
	
	
	
	
	



