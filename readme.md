# Flask Application with MongoDB on Kubernetes

This guide provides detailed steps to deploy a Flask application with a MongoDB backend on a Kubernetes cluster using Minikube. It also includes explanations of DNS resolution and resource management in Kubernetes.

## Prerequisites

- Minikube installed and running
- kubectl installed and configured to interact with your Minikube cluster
- Docker installed (if you plan to build Docker images locally)

## Deployment Steps

### 1. Start Minikube

Start Minikube with sufficient resources to handle the deployment:

```bash
minikube start --cpus=4 --memory=8192
```
### 2. Build and Push Docker Images

If you haven't already built and pushed your Flask application Docker image, do so now:


```bash
# Navigate to your project directory
cd /path/to/your/project

# Build the Docker image
docker build -t your_dockerhub_username/flask-mongo-app:latest .

# Push the image to Docker Hub
docker push your_dockerhub_username/flask-mongo-app:latest
```

### 3. Deploy MongoDB

Apply the statefulset-mongo.yaml to deploy MongoDB:


```bash
kubectl apply -f statefulset-mongo.yaml

```

### 4. Deploy Flask Application

Apply the deployment-flask.yaml to deploy the Flask application:


```bash
kubectl apply -f deployment-flask.yaml

```
This YAML file creates a deployment with 2 replicas, a service to expose the application, and necessary environment variables for MongoDB connection.

### 6. Set Up Horizontal Pod Autoscaler

To access the Flask application, use Minikube’s service command to get the URL:


```bash
minikube service flask-service --url
```

### 7. Access the Flask Application

You can use curl commands to test the endpoints:


```bash
# GET request to the root endpoint:
curl http://<minikube_url>/


# POST request to /data endpoint:
curl -X POST -H "Content-Type: application/json" -d '{"sampleKey":"sampleValue"}' http://<minikube_url>/data


# GET request to /data endpoint:
curl http://<minikube_url>/data

```
Replace <minikube_url> with the URL provided by the minikube service command.

# DNS Resolution in Kubernetes

In Kubernetes, DNS resolution is used for service discovery and communication between pods. Kubernetes provides a DNS service that automatically assigns DNS names to services. Pods can communicate with services using these DNS names, which resolve to the IP address of the service.

For example, in our deployment:

### 1. The Flask application connects to MongoDB using the service name mongo. 
### 2. This allows the Flask application to communicate with MongoDB seamlessly within the Kubernetes cluster.

# Resource Requests and Limits in Kubernetes
Kubernetes allows you to specify resource requests and limits for containers in a pod:

## Resource Requests


```bash
requests:
  memory: "250Mi"
  cpu: "200m"
```

```bash
limits:
  memory: "500Mi"
  cpu: "500m"

```

# Flask and MongoDB on Kubernetes

This repository provides a guide to deploying a Python Flask application with MongoDB on a Kubernetes cluster using Minikube. The deployment is designed to be scalable, resilient, and efficient, leveraging Kubernetes' powerful features like Deployments, StatefulSets, and Horizontal Pod Autoscaling (HPA).

## Table of Contents

1. [Design Choices](#design-choices)
   - Minikube for Local Development
   - Deployment and StatefulSet for Flask and MongoDB
   - Persistent Volume (PV) and Persistent Volume Claim (PVC)
   - Horizontal Pod Autoscaler (HPA)
   - Resource Requests and Limits
2. [Testing Scenarios](#testing-scenarios)
   - Autoscaling Testing
   - Database Interaction Testing

## Design Choices

### 1. Minikube for Local Development

- **Choice:** Minikube was selected as the local Kubernetes environment.
- **Reasoning:** Minikube is lightweight, easy to set up, and widely used for local Kubernetes development. It allows you to develop and test Kubernetes configurations on a local machine without needing a cloud environment.
- **Alternatives Considered:**
  - **Docker Desktop Kubernetes:** Considered for its simplicity but offers less flexibility than Minikube in configuring resources and simulating a production-like environment.
  - **Kind (Kubernetes in Docker):** Considered but not chosen due to its slightly more complex setup and less extensive community support.

### 2. Deployment and StatefulSet for Flask and MongoDB

- **Choice:** The Flask application is deployed using a Deployment, while MongoDB is deployed using a StatefulSet.
- **Reasoning:**
  - **Deployment:** Ideal for stateless applications like Flask. It handles rolling updates, ensures the desired number of replicas, and is straightforward to manage.
  - **StatefulSet:** Perfect for stateful applications like MongoDB, providing stable network identities and persistent storage.
- **Alternatives Considered:**
  - **DaemonSet for MongoDB:** Considered but discarded because DaemonSets are more suited for applications that need to run on every node in a cluster, not for stateful services requiring persistent storage.

### 3. Persistent Volume (PV) and Persistent Volume Claim (PVC)

- **Choice:** PV and PVC are used to provide persistent storage for MongoDB.
- **Reasoning:** Persistent storage ensures that data is not lost when MongoDB pods are rescheduled or restarted. PVC abstracts the storage layer, making it easier to manage and scale.
- **Alternatives Considered:**
  - **HostPath Volume:** Considered but rejected because it ties the data to a specific node, making it less flexible and reliable in a dynamic Kubernetes environment.
  - **EmptyDir:** Rejected because it only provides ephemeral storage, which does not persist if the pod is deleted or rescheduled.

### 4. Horizontal Pod Autoscaler (HPA)

- **Choice:** HPA is configured to scale the Flask application based on CPU usage.
- **Reasoning:** Autoscaling based on CPU utilization is a standard approach for handling varying loads, ensuring the application scales efficiently to maintain performance under high traffic.
- **Alternatives Considered:**
  - **Manual Scaling:** Considered but rejected in favor of automated scaling, which is more responsive and reduces the need for manual intervention.
  - **Scaling based on custom metrics:** Considered but found to be more complex to implement and unnecessary for the current application's needs.

### 5. Resource Requests and Limits

- **Choice:** Specific CPU and memory requests and limits were set for both the Flask and MongoDB containers.
- **Reasoning:** Setting requests and limits ensures that each pod gets the resources it needs while preventing any single pod from consuming too much of the cluster's resources. This helps maintain stability and performance across the cluster.
- **Alternatives Considered:**
  - **No Limits:** Considered but rejected because it could lead to resource contention and potentially destabilize the cluster.

## Testing Scenarios

### 1. Autoscaling Testing

- **Scenario:** Simulate high traffic to test the autoscaling behavior of the Flask application.
- **Method:**
  - **Load Generation:** A tool like Apache JMeter or ab (Apache Benchmark) was used to generate a high number of requests to the Flask application.
  - **Monitoring:** Kubernetes metrics and logs were monitored to observe how the HPA responded to increased CPU usage by scaling the number of replicas.
- **Results:**
  - The HPA successfully scaled the Flask application from the initial 2 replicas to the maximum configured 5 replicas as CPU utilization exceeded 70%.
  - Once the load decreased, the HPA scaled down the replicas, demonstrating effective autoscaling.
- **Issues Encountered:**
  - **Delay in Scaling:** There was a slight delay in scaling up, which is expected due to the time it takes to launch new pods.
  - **Resource Contention:** During peak loads, other pods in the cluster experienced slight resource contention, highlighting the importance of carefully setting resource limits.

### 2. Database Interaction Testing

- **Scenario:** Test the Flask application’s interaction with MongoDB under normal and high load conditions.
- **Method:**
  - **Normal Load:** Basic CRUD operations (Create, Read) were tested using curl and Postman to ensure that the Flask application could correctly insert and retrieve data from MongoDB.
  - **High Load:** A large volume of concurrent requests was sent to the `/data` endpoint to simulate heavy traffic.
- **Results:**
  - **Normal Load:** The application performed as expected, with data being correctly inserted into and retrieved from MongoDB.
  - **High Load:** MongoDB handled the increased load effectively, though response times increased slightly due to the higher number of simultaneous connections.
- **Issues Encountered:**
  - **Connection Timeouts:** A few timeouts were observed during peak load testing, indicating that MongoDB could benefit from further optimization or scaling in a real-world scenario.

## Conclusion

These design choices and testing scenarios were selected to ensure a robust, scalable, and efficient deployment of the Flask application with MongoDB on Kubernetes. They also highlight the importance of resource management and autoscaling in maintaining application performance and stability under varying loads.

##  Can you explain the benefits of using a virtual environment for python applications?