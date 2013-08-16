
#include "TCPServer.h"
#include <string>
#include <sstream>
#include "planner.h"

extern void plan_get_current_position_xyz(float *x, float *y, float *z);

TCPServer::TCPServer(int myport) {

    mot = new LaosMotion();
      while ( !mot->isStart() );

    port = myport;
    state = waitingForClient;
    printf("TCPServer(): port=%d\n", myport);

    // Set the callbacks for Listening
    ListeningSock.setOnEvent(this, &TCPServer::onListeningTCPSocketEvent); 

    // bind and listen on TCP
    err=ListeningSock.bind(Host(IpAddr(), port));
    printf("TCPServer(): Binding..\r\n");
    if(err)
    {
        //Deal with that error...
        printf("TCPServer(): Binding Error\n");
    }
    err=ListeningSock.listen(); // Starts listening
    printf("TCPServer() Listening...\r\n");
    if(err)
    {
        printf("TCPServer(): Listening Error\r\n");
    }
    // ListenSock->setOnEvent(this, &TFTPServer::onListenUDPSocketEvent);
    // state = listen;
    // if (ListenSock->bind(Host(IpAddr(), port)))
    //     state = error;
    // //TFTPServerTimer.attach(this, &TFTPServer::cleanUp, 5000);
    // sprintf(workdir, "%s", dir);
    // filecnt = 0;
}

// destroy this instance of the tftp server
TCPServer::~TCPServer() {
    // ListenSock->resetOnEvent();
    // delete(ListenSock);
    // delete(remote);
    // state = deleted;
}

void TCPServer::reset() {
    // ListenSock->resetOnEvent();
    // delete(ListenSock);
    // delete(remote);
    // //TFTPServerTimer.detach();
    // ListenSock = new UDPSocket();
    // ListenSock->setOnEvent(this, &TFTPServer::onListenUDPSocketEvent);
    // state = listen;
    // if (ListenSock->bind(Host(IpAddr(), port)))
    //     state = error;
    // //TFTPServerTimer.attach(this, &TFTPServer::cleanUp, 5000);
    // sprintf(filename, "");
    // filecnt = 0;
}

// get current tftp status
TCPServerState TCPServer::State() {
    return state;
}

// Temporarily disable incoming TFTP connections
void TCPServer::suspend() {
    // state = suspended;
}

// Resume after suspension
void TCPServer::resume() {
    // if (state == suspended)
    //     state = listen;
}

// event driven routines to handle incoming packets
void TCPServer::onListeningTCPSocketEvent(TCPSocketEvent e) {

    // cleanUp();
    printf("onListeningTCPSocketEvent(): didListen..");
  switch(e)
    {
    case TCPSOCKET_ACCEPT:
     {   printf("Listening: TCP Socket Accepted\r\n");
        // Accepts connection from client and gets connected socket.   
        err=ListeningSock.accept(&client, &pConnectedSock);
        if (err) {
            printf("onListeningTcpSocketEvent : Could not accept connection.\r\n");
            return; //Error in accept, discard connection
        }
        // Setup the new socket events
        pConnectedSock->setOnEvent(this, &TCPServer::onConnectedTCPSocketEvent);
        // We can find out from where the connection is coming by looking at the
        // Host parameter of the accept() method
        IpAddr clientIp = client.getIp();
        printf("Listening: Incoming TCP connection from %d.%d.%d.%d\r\n", 
           clientIp[0], clientIp[1], clientIp[2], clientIp[3]);
        state = waitingForCommand;
       break;
   }
    // the following cases will not happen
    case TCPSOCKET_CONNECTED:
        printf("Listening: TCP Socket Connected\r\n");
        break;
    case TCPSOCKET_WRITEABLE:
        printf("Listening: TCP Socket Writable\r\n");
        break;
    case TCPSOCKET_READABLE:
        printf("Listening: TCP Socket Readable\r\n");
        break;
    case TCPSOCKET_CONTIMEOUT:
        printf("Listening: TCP Socket Timeout\r\n");
        break;
    case TCPSOCKET_CONRST:
        printf("Listening: TCP Socket CONRST\r\n");
        break;
    case TCPSOCKET_CONABRT:
        printf("Listening: TCP Socket CONABRT\r\n");
        break;
    case TCPSOCKET_ERROR:
        printf("Listening: TCP Socket Error\r\n");
        break;
    case TCPSOCKET_DISCONNECTED:
    //Close socket...
        printf("Listening: TCP Socket Disconnected\r\n");        
        ListeningSock.close();
        break;
    default:
        printf("DEFAULT\r\n"); 
     };


}

// event driven routines to handle incoming packets
void TCPServer::onConnectedTCPSocketEvent(TCPSocketEvent e) {

 switch(e)
    {
    case TCPSOCKET_CONNECTED:
        printf("TCP Socket Connected\r\n");
        break;
    case TCPSOCKET_WRITEABLE:
      //Can now write some data...
        printf("TCP Socket Writable\r\n");
        break;
    case TCPSOCKET_READABLE: {
      //Can now read dome data...
        printf("TCP Socket Readable\r\n");
          int x, y, z = 0;

       // Read in any available data into the buffer
       char buff[128];
       while ( int len = pConnectedSock->recv(buff, 128) ) {
           const char *ptr = strchr(buff, ';');
            if(ptr) {
               int index = ptr - buff;
               buff[index] = 0;
            } else {
               buff[len]=0; // make terminater                
            }
           printf("Received&Wrote:%s\r\n",buff);
           string command(buff);

           if(strcmp (buff,"getPosition") == 0) {
               // send position
               mot->getPosition(&x, &y, &z); // get position in microns

                std::stringstream sstm; 
                sstm << "p " << x << " " << y;
                string msg(sstm.str());

                printf("position: %i %i\n", x,y); 

                pConnectedSock->send(msg.c_str(), msg.size());



           } else {

                int i = 0;
                stringstream ssin(command);

                mot->reset();


                while (ssin.good() && i < 4){
                    string item;
                    ssin >> item;

                    while (!mot->ready() );
                    mot->write(atoi(item.c_str()));


                    ++i;
                }

                while (!mot->ready() );

                while (!plan_queue_empty()); // wait until done, so no queue is used at all

                string msg = string("DONE ") + command;

                pConnectedSock->send(msg.c_str(), msg.size());

                // x = atoi(arr[1].c_str());
                // y = atoi(arr[2].c_str());
                // printf("move to %i %i \n", x,y);
                // mot->moveTo(x, y, z);  // set position in microns          

        
           }
         }
        }
       break;
    case TCPSOCKET_CONTIMEOUT:
        printf("TCP Socket Timeout\r\n");
        break;
    case TCPSOCKET_CONRST:
        printf("TCP Socket CONRST\r\n");
        break;
    case TCPSOCKET_CONABRT:
        printf("TCP Socket CONABRT\r\n");
        break;
    case TCPSOCKET_ERROR:
        printf("TCP Socket Error\r\n");
        break;
    case TCPSOCKET_DISCONNECTED:
    //Close socket...
        printf("TCP Socket Disconnected\r\n");        
        pConnectedSock->close();
        state = waitingForClient;
        break;
    default:
        printf("DEFAULT\r\n"); 
      }

}




