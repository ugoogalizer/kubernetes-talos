
Learned experience, there will be gaps, it will be oppinionated in places. Very keen for others to contribute at any stage


# 101 Basic Concepts - seminar style
 - Basic computing concepts: 
   - Compute & Memory
   - Storage
   - Networking
   - and mixing the above into advanced: 
     - Scheduling / topology / availability
 - Declarative vs Imperative
 - What's a container (vs metal vs VM) -- https://kubernetes.io/docs/concepts/overview/#going-back-in-time
 - What is docker and container runtimes? 
 - What are container images? 
 - What are container repositories? (and proxy caches)
 - What is k8s? 
 - Version Control / Git --> GitOps
 - What is Helm and Kustomize (& my challenges with them)

# Initial Concepts Deploy to K8s - seminar style
 - kubectl
 - Storage:
   - Persistent Volumes
   - Storage Volume Claims 
   - Storage Classes
   - Storage Provisioners / Dynamic Provisioning
 - Basic Networking Concepts
 - Services: 
   - Cluster IP
   - NodePort
   - Load Balancing (L2 vs external vs others)
 - Ingress and Gateway API (noting my limited knowledge yet on Gateway API)
 - Continual Deployment / GitOps Deployments (argocd)
 - TLS Certificates / Certificate Management (cert-manager)
   - Certificate requests and lifecycle management
 - Secrets Management
 - Workload Differences: 
   - Deployment/ReplicaSet
   - StatefulSet
   - DaemonSet
   - Job/Cronjob
 - External services: 
    - Storage, ideally with a storage provisioner
    - Certificate Issuer
    - Secrets Management
    - External Reverse Proxy/Tunnels (if external access is required)
 - Security
    - NetworkPolicy (highly dependent on CNI)
    

# More Advanced Concepts Deploy to K8s - seminar style
 - NVIDIA drivers
 - Auto scaling
 - Scheduling
     - Taints and tolerations
     - Node Selectors and Affinity

# More Advanced Concepts Needed to Run a Cluster - seminar style
 - Configuration (etcd)
 - kubeapi
 - K8s Flavour and OS (ideally avoiding double virtualisation). MC's lived experience
   - Vanilla
   - RKE2
   - Talos Linux
 - Container Runtimes 
 - CNI
 - Reverse Proxyies (i.e. Cloudflare)
 - Trust management (trust-manager)
 - Backup
 - Schedling/Premption/Eviction/Draining

# How to build and deploy an app - hands on style (would require a cluster playspace)
 - Write a mini-app
 - Containerise it
    - Automate the containerisation of it
 - Deploy it ("schedule" it), ideally via GitOps
 - Make available as a service, ideally with an Ingress/GatewayAPI and automated certificate

# How to build your own cluster - hands on style (would require HW and external services)
 - Prep metal, (ideally not a VM)
 - Deploy OS (ideally declaratively - Talos Linux a good choice, but there are others)
 - Bootstrap Cluster
 - Configure Cluster (aka deploy key cluster services)
 - Place Cluster into declarative GitOps deployment
 - (Deploy apps as per above)

# Known Gaps:
 - Automated testing
 - Cluster authentication
 - Runtime security (i.e. Application Allowlisting)


