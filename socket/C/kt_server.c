#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
        
#define PORT 8080
#define BUFSIZE 1024
struct data{
	int id;
	int process;
	int friendList[8];
	char body[1][BUFSIZE];
};
void send_to_all(int j, int i, int sockfd, int nbytes_recvd, char *recv_buf, fd_set *master, int process)
{
        if (FD_ISSET(j, master)){
                if (j != sockfd && j != i) {
                		struct data message;
						message.id = i;
						message.process = process;
						strcpy(message.body[0], recv_buf);
						message.friendList[0] = j;
                        if (send(j, &message, BUFSIZE, 0) == -1) {
                                perror("send");
                        }
                }
        }
}
                
void send_recv(int i, fd_set *master, int sockfd, int fdmax)
{
        int nbytes_recvd, j, x;
        char recv_buf[BUFSIZE], buf[BUFSIZE];
        memset(recv_buf, 0, BUFSIZE);
        struct data recive;
        if ((nbytes_recvd = recv(i, &recive, BUFSIZE, 0)) <= 0) {
        	printf("nbytes_recvd : %i\n", nbytes_recvd);
                if (nbytes_recvd == 0) {
                        printf("socket %d hung up\n", i);
                }else {
                        perror("recv");
                }
                close(i);
                FD_CLR(i, master);
        }else {
                for(j = 0; j <= fdmax; j++){
                	for(x = 0; x <= 8; x++){
                		if(j == recive.friendList[x])
                        send_to_all(j, i, sockfd, nbytes_recvd, recive.body[0], master, recive.process);
					}
                }
        }       
}
                
void connection_accept(fd_set *master, int *fdmax, int sockfd, struct sockaddr_in *client_addr)
{
        socklen_t addrlen;
        int newsockfd;
        char *message;
        
        addrlen = sizeof(struct sockaddr_in);
        if((newsockfd = accept(sockfd, (struct sockaddr *)client_addr, &addrlen)) == -1) {
                perror("accept");
                exit(1);
        }else {
                FD_SET(newsockfd, master);
                if(newsockfd > *fdmax){
                        *fdmax = newsockfd;
                }
		char* pPath;
		pPath = getenv ("PATH");
		printf("Client : %s", pPath);
                printf("new connection from %s on port %d \n",inet_ntoa(client_addr->sin_addr), ntohs(client_addr->sin_port));
                //if (FD_ISSET(newsockfd, master)){
                message = "You have connect to server : ";
                char buf[5];
                sprintf(buf, "%d", newsockfd);
                //strcat(message, newsockfd);
                //strcat(message, buf);
                //printf("sss : %s", buf);
                struct data message;
                message.id = newsockfd;
                message.process = 1;
                message.friendList[0] = 1;
                message.friendList[1] = 2;
            
                //char sendData[100] = {'1', 'x'};
					send(newsockfd, &message, BUFSIZE, 0);
				//}
        }
}
        
void connect_request(int *sockfd, struct sockaddr_in *my_addr)
{
        int yes = 1;
                
        if ((*sockfd = socket(AF_INET, SOCK_STREAM, 0)) == -1) {
                perror("Socket");
                exit(1);
        }
                
        my_addr->sin_family = AF_INET;
        my_addr->sin_port = htons(8080);
        my_addr->sin_addr.s_addr = INADDR_ANY;
        memset(my_addr->sin_zero, '\0', sizeof my_addr->sin_zero);
                
        if (setsockopt(*sockfd, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof(int)) == -1) {
                perror("setsockopt");
                exit(1);
        }
                
        if (bind(*sockfd, (struct sockaddr *)my_addr, sizeof(struct sockaddr)) == -1) {
                perror("Unable to bind");
                exit(1);
        }
        if (listen(*sockfd, 10) == -1) {
                perror("listen");
                exit(1);
        }
        printf("\nTCPServer Waiting for client on port 8080\n");
        fflush(stdout);
}
int main()
{
        fd_set master;
        fd_set read_fds;
        int fdmax, i;
        int sockfd= 0;
        struct sockaddr_in my_addr, client_addr;
        
        FD_ZERO(&master);
        FD_ZERO(&read_fds);
        connect_request(&sockfd, &my_addr);
        printf("debug: %i", sockfd);
        FD_SET(sockfd, &master);
        
        fdmax = sockfd;
        while(1){
                read_fds = master;
                if(select(fdmax+1, &read_fds, NULL, NULL, NULL) == -1){
                        perror("select");
                        exit(4);
                }
                for (i = 0; i <= fdmax; i++){
                        if (FD_ISSET(i, &read_fds)){
                                if (i == sockfd){
                                        connection_accept(&master, &fdmax, sockfd, &client_addr);
                                }else{
                                        send_recv(i, &master, sockfd, fdmax);
                                }
                        }
                }
        }
        return 0;
}
