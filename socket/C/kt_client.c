#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <errno.h>
        
#define BUFSIZE 1024
struct data{
	int id;
	int process;
	int friendList[8];
	char body[1][1024];
};
int myId;
void send_recv(int i, int sockfd)
{
        char send_buf[BUFSIZE];
        char recv_buf[10][BUFSIZE];
        int nbyte_recvd;
        /*
        struct message{
			int id;
			//char process[50];
			char friend[8][10];
		};
        */
        
        if (i == 0){
                fgets(send_buf, BUFSIZE, stdin);
                if (strcmp(send_buf , "quit\n") == 0) {
                        exit(0);
                }else{
                		struct data message;
						message.id = myId;
						message.process = 2;
						strcpy(message.body[0], send_buf);
						message.friendList[0] = 4;
						message.friendList[1] = 6;
                        send(sockfd, &message, BUFSIZE, 0);
                }
        }else {
        	struct data message;
                nbyte_recvd = recv(sockfd, &message, 1024, 0);
                //recv_buf[nbyte_recvd] = '\0';
                myId = message.id;
                printf("ID : %i\n" , message.id);
                printf("Process : %i\n" , message.process);
                if(message.process == 2){
                	printf("Message : %s", message.body[0]);
                }
                printf("Friend : %i\n" , message.friendList[0]);
                fflush(stdout);
        }
}
                
                
void connect_request(int *sockfd, struct sockaddr_in *server_addr)
{
        if ((*sockfd = socket(AF_INET, SOCK_STREAM, 0)) == -1) {
                perror("Socket");
                exit(1);
        }
        server_addr->sin_family = AF_INET;
        server_addr->sin_port = htons(8080);
        server_addr->sin_addr.s_addr = inet_addr("127.0.0.1");
        memset(server_addr->sin_zero, '\0', sizeof server_addr->sin_zero);
        
        if(connect(*sockfd, (struct sockaddr *)server_addr, sizeof(struct sockaddr)) == -1) {
                perror("connect");
                exit(1);
        }
}
        
int main()
{
        int sockfd, fdmax, i;
        struct sockaddr_in server_addr;
        fd_set master;
        fd_set read_fds;
        
        connect_request(&sockfd, &server_addr);
        FD_ZERO(&master);
        FD_ZERO(&read_fds);
        FD_SET(0, &master);
        FD_SET(sockfd, &master);
        fdmax = sockfd;
        
        while(1){
                read_fds = master;
                if(select(fdmax+1, &read_fds, NULL, NULL, NULL) == -1){
                        perror("select");
                        exit(4);
                }
                
                for(i=0; i <= fdmax; i++ )
                        if(FD_ISSET(i, &read_fds))
                                send_recv(i, sockfd);
        }
        printf("client-quited\n");
        close(sockfd);
        return 0;
}
