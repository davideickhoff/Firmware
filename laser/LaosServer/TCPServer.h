

#ifndef _TCPSERVER_H_
#define _TCPSERVER_H_

#include <stdio.h>
#include <ctype.h>
#include "mbed.h"
#include "laosfilesystem.h"
#include "TCPSocket.h"      // http://mbed.org/users/donatien/programs/EthernetNetIf
#include "LaosMotion.h"

#define TCP_PORT 54321
//#define TFTP_DEBUG(x) printf("%s\n\r", x);

enum TCPServerState { waitingForClient, waitingForCommand, tcpError, receivedCommand }; 

class TCPServer {

public:
    // create a new tcp server listening on port
    TCPServer(int myport = TCP_PORT);
    // destroy this instance of the tcp server
    void reset();
    // reset socket
    ~TCPServer();
    // get current tcp status
    TCPServerState State();
    // Temporarily disable incoming TFTP connections
    void suspend();
    // Resume after suspension
    void resume();


private:
    TCPSocket ListeningSock;
    TCPSocket* pConnectedSock; // for ConnectedSock
    Host client;
    TCPSocketErr err;
    LaosMotion *mot;

    // event driven routines to handle incoming packets
    void onListeningTCPSocketEvent(TCPSocketEvent e);
    void onConnectedTCPSocketEvent(TCPSocketEvent e);


    int port; // The TCP port
    TCPServerState state;      // current TCP server state
};

#endif
