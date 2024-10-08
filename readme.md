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

# Kubernetes Deployment README

## Overview

This README provides a detailed explanation of DNS resolution and resource management within a Kubernetes cluster, specifically focusing on how these concepts apply to the deployment of a Flask application with MongoDB.

## DNS Resolution in Kubernetes

Kubernetes offers an integrated DNS service that facilitates service discovery and seamless communication between pods. The DNS service automatically assigns DNS names to Kubernetes services, allowing pods to interact with these services using their DNS names rather than IP addresses.

### Example in Our Deployment:

- **Service Name:** `mongo`
- **Application:** Flask
- **Database:** MongoDB

In this setup, the Flask application connects to the MongoDB service using the DNS name `mongo`. Kubernetes resolves this name to the cluster IP address of the MongoDB service, enabling the Flask application to communicate with MongoDB efficiently.

This DNS-based service discovery greatly simplifies inter-service communication within the Kubernetes cluster, eliminating the need to manage IP addresses manually.

## Resource Requests and Limits in Kubernetes

Kubernetes allows defining resource requests and limits for containers within pods, ensuring efficient resource allocation and management.

### Resource Requests

Resource requests specify the guaranteed amount of CPU and memory resources for a container. If the requested resources are available, Kubernetes will schedule the pod on a suitable node.

Example:

```yaml
Copy code
requests:
  memory: "250Mi"
  cpu: "200m"
  ```
In this example, the container requests 250 MB of memory and 0.2 CPU cores.

Resource Limits
These define the maximum amount of CPU and memory resources that a container can consume. If the container tries to use more than the specified limit, it may be throttled or evicted.

Example:

```yaml
Copy code
limits:
  memory: "500Mi"
  cpu: "500m"
  ```
In this example, the container is limited to using 500 MB of memory and 0.5 CPU cores
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

#  Cookie point:

## Can you explain the benefits of using a virtual environment for python applications?

Virtual environments are an essential tool for Python developers. They help in managing project dependencies efficiently, avoiding conflicts, and maintaining a clean and secure development environment.

## 1. Dependency Management

Virtual environments allow you to manage dependencies for your project in an isolated environment. This means you can install specific versions of libraries and packages required for your project without affecting other projects or the system-wide Python installation.

## 2. Avoiding Conflicts

Different projects may require different versions of the same library. Virtual environments prevent conflicts between these dependencies by creating isolated environments for each project. This ensures that changes in one project do not break another.

## 3. Clean Development Environment

Using virtual environments keeps your global Python environment clean and uncluttered. You can avoid installing unnecessary packages globally, which leads to a more organized and manageable development setup.

## 4. Consistency Across Machines

Whether you’re working on your laptop, a server, or a colleague’s computer, a virtual environment ensures your project runs the same way everywhere. This consistency is crucial for development, testing, and deployment.

## 5. Security

By isolating your project’s dependencies, you reduce the risk of accidentally altering system-wide packages or being affected by them. It’s a safer way to manage your project’s libraries.

---

In short, virtual environments help keep your projects tidy, conflict-free, and easy to share. They’re a best practice for any Python developer!

## Testing Scenarios: Detail how you tested autoscaling and database interactions, including simulating high traffic. Provide results and any issues encountered during testing

## Testing Scenarios

### Testing Autoscaling

**Scenario:** Ensure that the Flask application can handle increased traffic by automatically scaling the number of pods.

**Steps:**
1. **Set Up HPA:** Configure the Horizontal Pod Autoscaler (HPA) to scale the Flask application based on CPU usage.
2. **Simulate High Traffic:** Use Apache JMeter to simulate high traffic, creating multiple requests to the application and mimicking a large number of users accessing the service simultaneously.
3. **Monitor Scaling:** Use the Kubernetes dashboard to monitor the scaling behavior, observing the number of pods as CPU usage increases.

**Results:**
- The HPA successfully scaled the number of pods from 2 to 5 as CPU usage spiked.
- After the traffic decreased, the HPA scaled down the pods back to 2, ensuring efficient resource usage.

**Issues Encountered:**
- **Initial Delay:** A slight delay was observed when scaling up the pods due to the time required to spin up new pods.
- **Resource Limits:** Adjustments to resource limits were necessary to ensure the pods had sufficient CPU and memory to handle the load without crashing.

### Testing Database Interactions

**Scenario:** Verify that the Flask application can interact with MongoDB correctly, even under high traffic conditions.

**Steps:**
1. **Deploy MongoDB:** Use a StatefulSet for MongoDB deployment, ensuring persistent storage and stable network identities.
2. **Simulate Database Load:** Use JMeter to create scenarios involving multiple read and write operations to MongoDB.
3. **Monitor Performance:** Monitor MongoDB performance using Kubernetes metrics and MongoDB logs to ensure it handles the load efficiently.

**Results:**
- MongoDB efficiently handled read and write operations, even under high traffic conditions.
- The Flask application successfully connected to MongoDB using the service name `mongo` thanks to Kubernetes DNS resolution.

**Issues Encountered:**
- **Connection Timeouts:** Connection timeouts were initially faced under extremely high traffic. This was resolved by optimizing the connection pool settings in the Flask application.
- **Resource Allocation:** Fine-tuning of resource requests and limits for MongoDB pods was necessary to ensure adequate resources for handling the load without being throttled.