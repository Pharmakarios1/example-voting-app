# Voting App DevOps Capstone

A containerized voting application deployed to Amazon EKS using Terraform, Docker, GitHub Actions, Trivy, and Helm.

## Project Overview

This project demonstrates how to build, secure, deploy, and manage a containerized application using DevOps practices.

The application allows users to vote, processes votes in the background, stores the results in PostgreSQL, and displays live voting results.

## Application Architecture

The application consists of five main services:

- **Vote:** Web interface for submitting votes.
- **Redis:** Queue for temporarily storing submitted votes.
- **Worker:** Processes votes from Redis and saves them to PostgreSQL.
- **PostgreSQL:** Persistent database for storing votes.
- **Result:** Web interface for displaying voting results.

### Request Flow

1. A user submits a vote through the Vote application.
2. Redis queues the vote.
3. The Worker processes the queued vote.
4. PostgreSQL stores the vote.
5. The Result application displays the updated totals.

## Technology Stack

| Technology | Purpose |
|---|---|
| Docker | Containerizing application services |
| Docker Compose | Running the application locally |
| Terraform | Provisioning AWS infrastructure |
| Amazon EKS | Managed Kubernetes cluster |
| Kubernetes | Managing application workloads |
| Amazon EBS | Persistent database storage |
| Helm | Packaging and deploying Kubernetes resources |
| GitHub Actions | Automating CI/CD |
| Trivy | Scanning container images for vulnerabilities |
| Docker Hub | Storing container images |
| AWS IAM and OIDC | Managing access and permissions |

## Project Structure

```text
example-voting-app/
├── vote/                       # Voting frontend
├── result/                     # Results frontend
├── worker/                     # Vote processing service
├── seed-data/                  # Sample data utilities
├── compose.yaml                # Local development services
├── terraform/                  # AWS infrastructure code
├── helm/
│   └── voting-app/             # Helm chart
├── .github/
│   └── workflows/
│       └── ci-cd.yaml          # CI/CD pipeline
└── README.md
```

The exact files and directories may vary slightly depending on the repository version.

## 1. Run Locally with Docker Compose

Clone the repository and enter the project directory:

```bash
git clone https://github.com/YOUR_USERNAME/example-voting-app.git
cd example-voting-app
```

Validate the Compose configuration:

```bash
docker compose config
```

Build and start the application:

```bash
docker compose up -d --build
```

Check running containers:

```bash
docker compose ps
```

View service logs:

```bash
docker compose logs -f
```

Stop the application:

```bash
docker compose down
```

The local application provides the foundation for testing the voting workflow before deploying to Kubernetes.

## 2. Container Hardening

The application Dockerfiles were reviewed and improved to follow container security best practices.

Hardening activities include:

- Using appropriate, pinned base-image versions where applicable.
- Running application processes as non-root users where supported.
- Adding `.dockerignore` files to avoid copying unnecessary files into images.
- Building and testing the application containers.
- Reducing unnecessary files and dependencies in container images.

These practices help reduce image size and limit the potential attack surface.

## 3. Provision AWS Infrastructure with Terraform

Terraform provisions the Kubernetes infrastructure on AWS.

The target infrastructure includes:

- An Amazon EKS cluster named `voting-app-eks`.
- AWS networking using the default VPC and its subnets.
- Managed worker nodes.
- IAM permissions and OIDC integration for Kubernetes workloads.
- The Amazon EBS CSI driver for persistent volume provisioning.

The cluster is deployed in `us-east-1`.

Initialize and validate Terraform from the infrastructure directory:

```bash
terraform init
terraform fmt -check
terraform validate
terraform plan
```

Apply the infrastructure when the plan has been reviewed:

```bash
terraform apply
```

Configure `kubectl` to access the cluster:

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name voting-app-eks
```

Verify cluster access:

```bash
kubectl get nodes
kubectl get namespaces
```

**Important:** Review AWS costs before creating resources. Destroy practice infrastructure when it is no longer needed, after confirming that doing so will not remove data or resources you want to keep.

```bash
terraform destroy
```

## 4. CI/CD with GitHub Actions

The GitHub Actions workflow automates building, scanning, publishing, and deploying the application.

The pipeline is designed to:

1. Check out the source code.
2. Build the Vote, Result, and Worker container images.
3. Scan the images with Trivy.
4. Publish images to Docker Hub when changes are pushed to `main`.
5. Tag images with the Git commit SHA for traceability.
6. Validate the Helm chart.
7. Deploy the application to Amazon EKS.
8. Verify Kubernetes deployment rollouts.

### Image Tags

Images use commit-specific tags, for example:

```text
pharmakarios1/voting-app-vote:<commit-sha>
pharmakarios1/voting-app-result:<commit-sha>
pharmakarios1/voting-app-worker:<commit-sha>
```

Commit-SHA tags make it possible to identify the exact application version deployed.

### Required GitHub Secrets

Configure the following secrets in the repository's GitHub Actions settings:

| Secret | Purpose |
|---|---|
| `DOCKER_USERNAME` | Docker Hub username |
| `DOCKER_PASSWORD` | Docker Hub access token or password |
| `AWS_ACCESS_KEY_ID` | AWS access key for deployment |
| `AWS_SECRET_ACCESS_KEY` | AWS secret access key |
| `AWS_REGION` | AWS deployment region |
| `EKS_CLUSTER_NAME` | EKS cluster name |

Never commit credentials, access keys, or other secrets to the repository.

## 5. Container Image Scanning with Trivy

Trivy scans built container images for known vulnerabilities before they are published.

The current workflow is configured to fail when it detects **CRITICAL vulnerabilities**, including vulnerabilities that do not yet have fixes.

This helps prevent images with critical known vulnerabilities from progressing through the pipeline.

To inspect an image locally, install Trivy and run:

```bash
trivy image \
  --severity CRITICAL \
  --ignore-unfixed=false \
  pharmakarios1/voting-app-result:latest
```

Review scan results and update affected base images or dependencies where appropriate. Do not ignore vulnerabilities without understanding and documenting the risk.

## 6. Deploy with Helm

The Helm chart manages the Kubernetes resources required by the voting application.

It includes the Vote, Result, Worker, Redis, and PostgreSQL services, along with their deployments, service configuration, and database storage.

Validate the chart:

```bash
helm lint ./helm/voting-app
```

Render the Kubernetes manifests without deploying:

```bash
helm template voting-app ./helm/voting-app
```

Deploy or upgrade the application:

```bash
helm upgrade --install voting-app ./helm/voting-app \
  --namespace voting-app \
  --create-namespace \
  --wait \
  --timeout 10m
```

Check the deployment:

```bash
kubectl get pods -n voting-app
kubectl get services -n voting-app
kubectl get deployments -n voting-app
```

### Application Access

The Vote and Result services are configured as NodePort services on ports `31000` and `31001`, respectively.

Actual external access depends on the cluster's service configuration and networking setup. The project also explores external access through an AWS Application Load Balancer.

## 7. Persistent Database Storage

PostgreSQL requires persistent storage so that database data can survive pod replacement.

The deployment uses:

- A PersistentVolumeClaim (PVC) to request storage.
- A PersistentVolume (PV) to represent the provisioned storage.
- Amazon EBS through the EBS CSI driver.
- The `gp3` StorageClass.
- A `1Gi` database volume.

Check storage resources:

```bash
kubectl get pvc -n voting-app
kubectl get pv
kubectl get storageclass
```

A `Bound` PVC indicates that the storage claim has been matched to a volume. It does not, by itself, guarantee that PostgreSQL is healthy; check the database pod and logs as well.

```bash
kubectl get pods -n voting-app
kubectl logs deployment/voting-app-voting-app-db -n voting-app
```

## 8. Helm Rollback Testing

Rollback testing demonstrates how to recover from a failed application release.

View the release history:

```bash
helm history voting-app -n voting-app
```

After identifying a known-good revision, introduce a controlled deployment failure in a safe test environment and observe the result.

Roll back to the selected revision:

```bash
helm rollback voting-app REVISION -n voting-app \
  --wait \
  --timeout 10m
```

Replace `REVISION` with the actual known-good revision from `helm history`.

Verify the recovery:

```bash
helm history voting-app -n voting-app
kubectl get pods -n voting-app
kubectl rollout status deployment/voting-app-voting-app-vote \
  -n voting-app
kubectl rollout status deployment/voting-app-voting-app-result \
  -n voting-app
```

A successful rollback should restore the intended application configuration. Confirm that the application works and that the database remains healthy after recovery.

## 9. Troubleshooting Commands

Check all resources in the application namespace:

```bash
kubectl get all -n voting-app
```

Inspect pod details:

```bash
kubectl describe pod POD_NAME -n voting-app
```

Read current logs:

```bash
kubectl logs POD_NAME -n voting-app
```

Read logs from a previously terminated container:

```bash
kubectl logs POD_NAME -n voting-app --previous
```

Inspect recent events:

```bash
kubectl get events -n voting-app \
  --sort-by=.metadata.creationTimestamp
```

Check Helm release status:

```bash
helm status voting-app -n voting-app
```

## Project Deliverables

- [ ] Forked and working Voting App repository.
- [ ] Locally running application using Docker Compose.
- [ ] Hardened application containers.
- [ ] Terraform code for reproducible AWS EKS infrastructure.
- [ ] GitHub Actions CI/CD workflow.
- [ ] Trivy vulnerability scanning.
- [ ] Docker Hub images tagged with commit SHAs.
- [ ] Helm chart for deploying the application.
- [ ] Persistent PostgreSQL storage.
- [ ] Successful deployment and application verification.
- [ ] Demonstrated failed release and successful Helm rollback.
- [ ] Architecture diagram and documented deployment instructions.

## Learning Outcomes

This project demonstrates practical experience with containerization, container security, infrastructure as code, Kubernetes orchestration, AWS cloud infrastructure, CI/CD automation, vulnerability scanning, Helm releases, persistent storage, troubleshooting, and deployment recovery.

## Acknowledgements

The application is based on the [Docker Samples Example Voting App](https://github.com/dockersamples/example-voting-app).

This repository extends the application with DevOps automation and cloud deployment practices for educational purposes.
