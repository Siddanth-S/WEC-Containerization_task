# Project Documentation: Dockerizing a Rails Application with Nginx and MySQL

Hello, this is Siddanth, pursuing Civil Engg. (2nd year) ! I'm going to guide you how I was able to setup Rails application in a Docker environment, step by step. This setup includes running our app with a separate MySQL database container, using Nginx as a reverse proxy, adding persistence, managing containers with Docker Compose, and implementing rate limiting with Nginx.

## Flow of the application 


![Screenshot 2024-10-11 at 10 04 37 PM](https://github.com/user-attachments/assets/533f82d4-1f54-4525-89fd-41963bff3fe2)





## 1. Dockerizing the Rails Application

Firstly, I had to encapsulate our application within a Docker container. This process involved creating a *Dockerfile* that specifies how the Rails environment is set up, including installing necessary dependencies and copying the application code into the container. The goal was to create an isolated environment that mimics our production setup, ensuring consistency across development, testing, and production. 

Here's the DockerFile : [DockerFile](https://github.com/Siddanth-S/WEC-Containerization_task/blob/main/Dockerfile)
which basically describes installation of all the dependencies, copies the application code into the image and set the entry point. 

Build the image with the DockerFile:

```
docker build -t my-rails-app .
```

<img width="781" alt="Screenshot 2024-10-11 at 6 42 54 PM" src="https://github.com/user-attachments/assets/a568cad9-4d3d-48b2-829f-6b2fe3663152">

But in this it's not necessary to run this command as running docker-compose.yml is sufficient to run DockerFile and create the application image. 


## 2. Launching the Application with a Database Container

I introduced a MySQL container to act as database. Pulled the mysql:latest image from the Docker Hub. Then configured the mysql environmental variables as below inside the [docker-compose.yml](https://github.com/Siddanth-S/WEC-Containerization_task/blob/main/docker-compose.yml). By leveraging Docker Compose, I orchestrated the simultaneous launch of the application and database container. A significant consideration was ensuring the database port was not exposed externally, mitigating potential security risks. This setup also allowed us to expose our application on port 8080, enabling access from "localhost:8080".

 ```
docker-compose up  #to launch the containers simultaneously
```

<img width="960" alt="Screenshot 2024-10-11 at 9 19 16 PM" src="https://github.com/user-attachments/assets/402706ae-2080-4200-971c-c1133302b762">



*Connection Successful !!*


<img width="1200" alt="Screenshot 2024-10-11 at 6 56 19 PM" src="https://github.com/user-attachments/assets/c1ee408f-c0a7-4ec5-bc53-4243dbd3b34f">


## 3. Introducing Nginx as a Reverse Proxy

I integrated an Nginx container to serve as a reverse proxy for the application's accessibility and security. This setup directed incoming traffic through Nginx before reaching the Rails application, providing an additional layer of abstraction and security. Configuring Nginx for reverse proxying also allowed us to hide the inner workings of our application network. Is exposed to port 8080. No direct request to application instance can be made. It has to pass through the procy server.

Here's the Nginx config : [Nginx Conf](https://github.com/Siddanth-S/WEC-Containerization_task/blob/main/nginx/nginx.conf)


## 4.  Scaling with Multiple Application Containers

I setup to include two additional Rails containers, ensuring our application could handle increased traffic gracefully. This scaling was facilitated by Nginx's load balancing feature, which distributed incoming requests evenly across the three containers. This approach improved application's availability. 

<img width="1418" alt="Screenshot 2024-10-11 at 6 58 46 PM" src="https://github.com/user-attachments/assets/d60549b2-8ad9-48b3-88f9-c9fdbdfe5a49">



## 5.  Persisting Data and Configurations

Through Docker volumes, achieved persistence by mapping specific directories from our containers to the host machine. This ensured that vital data and configurations remained intact even if the containers were restarted or removed, providing a reliable and consistent experience.
Here's the implemtation : [Volume data persistance](https://github.com/Siddanth-S/WEC-Containerization_task/blob/main/docker-compose.yml#L73)

## 6. Simplifying Deployment with Docker Compose

To streamline the deployment process and ensure all components of the application ecosystem could be launched with a single command, utilized Docker Compose. This tool allowed me to define and manage multi-container Docker applications, simplifying complex deployments into manageable configurations.

Here's the compose file : [docker-compose.yml](https://github.com/Siddanth-S/WEC-Containerization_task/blob/main/docker-compose.yml)


## 7. Implementing Rate Limiting with Nginx

Implementing rate limiting through Nginx is a strategy to prevent potential denial-of-service (DoS) attacks caused by an overwhelming number of requests. By setting thresholds for the number of allowed requests per second ,  ensured the application remained available to legitimate users.
```
limit_req_zone $binary_remote_addr zone=mylimit:10m rate=5r/s;
```
Defines a zone named mylimit and allocates 10 megabytes of memory to store the states of clients' addresses. rate=5r/s: Specifies the allowed request rate, which is 5 requests per second in this case.
Tested it out with **Apache Bench** (ab)  :  ab -n 100 -c 10 http://localhost:8080/ 
Here's the result : 

```
Benchmarking localhost (be patient).....done


Server Software:        nginx/1.25.4
Server Hostname:        localhost
Server Port:            8080

Document Path:          /
Document Length:        3730 bytes

Concurrency Level:      10
Time taken for tests:   7.695 seconds
Complete requests:      100
Failed requests:        98
   (Connect: 0, Receive: 0, Length: 98, Exceptions: 0)
Non-2xx responses:      67
Total transferred:      211247 bytes
HTML transferred:       140699 bytes
Requests per second:    13.00 [#/sec] (mean)
Time per request:       769.484 [ms] (mean)
Time per request:       76.948 [ms] (mean, across all concurrent requests)
Transfer rate:          26.81 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    0   0.1      0       0
Processing:     1  498 1032.0      5    4145
Waiting:        1  498 1031.4      5    4144
Total:          1  499 1032.0      5    4145

Percentage of the requests served within a certain time (ms)
  50%      5
  66%     20
  75%    268
  80%    848
  90%   2277
  95%   2911
  98%   4089
  99%   4145
 100%   4145 (longest request)

 ```
Observations from Benchmark
Non-2xx Responses: You observed 67 non-2xx responses out of 100 total requests, which indicates that some requests were either queued (delayed) or rejected due to exceeding the rate limit.
Failed Requests: The presence of failed requests due to content length mismatches likely reflects varied responses, such as HTTP 503 Service Temporarily Unavailable status codes, which are served when requests exceed your configured rate limit and burst capacity.


Indications of Active Rate Limiting
The direct cause-and-effect relationship where the rate of requests (as generated by your benchmarking tool) exceeds the configured limit (5r/s) and results in a notable number of non-2xx responses and request failures due to Nginx enforcing these limits.
The variability in response times and the existence of requests that took significantly longer to process (max time of 4145 ms) can also be indicative of rate limiting in action, as requests that exceed the limit might be queued, contributing to longer processing times.


These observations collectively indicate that the rate limiting setup is active and effectively limiting the rate at which individual clients can make requests to  server, as per the configuration you've established.


## Result 

All the tasks(except Bonus) are completed and the application is perfectly running in the local(development) environment. 


![WhatsApp Image 2024-03-18 at 12 51 03 AM](https://github.com/Siddanth-S/iris-project/assets/158839826/99dbe5e6-f64a-4a47-a7d7-304f663b8bf9)


<img width="1062" alt="Screenshot 2024-10-11 at 7 02 39 PM" src="https://github.com/user-attachments/assets/82a7d3a5-c85b-45b1-b07c-85933fff5d78">
