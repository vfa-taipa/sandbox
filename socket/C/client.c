/*
** client.c -- a stream socket client demo
*/

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <netdb.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <sys/socket.h>

#include <arpa/inet.h>

#define PORT "8081" // the port client will be connecting to 

#define MAXDATASIZE 100 // max number of bytes we can get at once 

// get sockaddr, IPv4 or IPv6:
void *get_in_addr(struct sockaddr *sa)
{
    if (sa->sa_family == AF_INET) {
        return &(((struct sockaddr_in*)sa)->sin_addr);
    }

    return &(((struct sockaddr_in6*)sa)->sin6_addr);
}

int do_write(int fd)
{
    char send_buf[1024];
    fgets(send_buf, 1024, stdin);
    if (strcmp(send_buf , "quit\n") == 0) {
        exit(0);
    } else {
        send(fd, send_buf, 1024, 0);
        printf("Send : %s\n", send_buf);
    }
    return 0;
}

int do_read(int fd)
{
    char buf[1024];
    int i;
    int result;
    printf("Client : do_read\n");
    while (1) {
        result = recv(fd, buf, sizeof(buf), 0);
        printf("client: received '%s'\n",buf);
        if (result <= 0)
            break;
    }

    if (result == 0) {
        return 1;
    } else if (result < 0) {
        if (errno == EAGAIN)
            return 0;
        return -1;
    }

    printf("client: received '%s'\n",buf);

    return 0;
}

int main(int argc, char *argv[])
{
    int sockfd, numbytes;  
    struct timeval tv;
    char buf[MAXDATASIZE];
    struct addrinfo hints, *servinfo, *p;
    int rv;
    char s[INET6_ADDRSTRLEN];
    fd_set readset, writeset;

    if (argc != 2) {
        fprintf(stderr,"usage: client hostname\n");
        exit(1);
    }

    memset(&hints, 0, sizeof hints);
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;

    if ((rv = getaddrinfo(argv[1], PORT, &hints, &servinfo)) != 0) {
        fprintf(stderr, "getaddrinfo: %s\n", gai_strerror(rv));
        return 1;
    }

    // loop through all the results and connect to the first we can
    for(p = servinfo; p != NULL; p = p->ai_next) {
        if ((sockfd = socket(p->ai_family, p->ai_socktype,
                p->ai_protocol)) == -1) {
            perror("client: socket");
            continue;
        }

        if (connect(sockfd, p->ai_addr, p->ai_addrlen) == -1) {
            close(sockfd);
            perror("client: connect");
            continue;
        }

        break;
    }

    if (p == NULL) {
        fprintf(stderr, "client: failed to connect\n");
        return 2;
    }

    inet_ntop(p->ai_family, get_in_addr((struct sockaddr *)p->ai_addr), s, sizeof s);
    printf("client: connecting to %s\n", s);

    freeaddrinfo(servinfo); // all done with this structure

    if ((numbytes = recv(sockfd, buf, MAXDATASIZE-1, 0)) == -1) {
        perror("recv");
        exit(1);
    }

    buf[numbytes] = '\0';


    FD_ZERO(&readset);
    FD_ZERO(&writeset);

    tv.tv_sec = 2;
    tv.tv_usec = 500000;
    
    while (1) {
        FD_ZERO(&readset);
        FD_ZERO(&writeset);

        FD_SET(sockfd, &readset);
        FD_SET(0, &readset);
        FD_SET(sockfd, &writeset);
        if (select(sockfd+1, &readset, NULL, NULL, &tv) < 0) {
            perror("select");
            return 0;
        }

        printf("Read DONE\n");

        for(int i = 0; i <= sockfd; i++ ){
            if (FD_ISSET(i, &readset)) {
                if (i == 0)
                    do_write(sockfd);
                else
                    do_read(i);
            } else if (FD_ISSET(i, &writeset)){
                //Do_Write
                printf("Client : Do Write");
                do_write(i);
            }
        }
    }

    close(sockfd);

    return 0;
}