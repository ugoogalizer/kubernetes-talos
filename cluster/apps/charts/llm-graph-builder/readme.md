
# Deploying Neo4j's llm-graph-builder within Kubernetes


They do not pre-build and host the container images, you are meant to build them yourself.  
Backend: 
 - can be build as a docker container without customisation as it takes environment variables that can be changed on container runtime.  I pre-built this, pushed it to a local container registry and used from there.
Frontend: 
 - has to have custom arguments provided to it before container image build, and appears to be their argument to not pre-build it.  In my case I pre-built the image with my defaults
 - has to be deployed on a trusted source [see this](https://github.com/auth0/auth0-spa-js/blob/main/FAQ.md#why-do-i-get-auth0-spa-js-must-run-on-a-secure-origin), so therefore you must have some way of deploying with a TLS certificate, aka cert-manager

I already had ollama running in the environment with a deployment of open-webui (see ./cluster/apps/root/templates/open-webui-helm.yaml) 
  -  that configuration made ollama available here: [http://open-webui-ollama.ollama.svc.cluster.local:11434](http://open-webui-ollama.ollama.svc.cluster.local:11434)
  - I downloaded and ran `ollama_qwen2.5-coder` as the model within ollama, so configured the env in the k8s backend manifest to use it, and the docker build args in the frontend to connect to it (seems really stupid this isn't a runtime env)

The backend from this chart deploys itself at [http://backend.llm-graph-builder.svc.cluster.local:8000](http://backend.llm-graph-builder.svc.cluster.local:8000)

These URLs are not reachable outside the cluster

neo4j: neo4j-rocks-lb-neo4j.neo4j.svc.cluster.local

## Environment Setup

### Container Registry
First create a new project in Harbor called 'llm-graph-builder' and grant a dev user access to it, you'll need those credentials for the `docker login` statement below

### Docker Build Server
``` bash
# Personal parameters
export HARBORURL=harbor.rockyroad.rocks

cd ~/
git clone https://github.com/neo4j-labs/llm-graph-builder.git
cd ~/llm-graph-builder/

```

### Build the Generic backend image
``` bash
# Ensure you have the latest 
git pull

#Set Build Parameters
export VERSIONTAG=0.1

# BACKEND
cd ~/llm-graph-builder/backend

#Build the Image
docker build -t llm-graph-builder-backend:latest -t llm-graph-builder-backend:${VERSIONTAG} .

#Get the image name, it will be something like 41d81c9c2d99: 
export IMAGE=$(docker images -q llm-graph-builder-backend:latest)
echo ${IMAGE}

#Login to local harbor
docker login ${HARBORURL}:443

#Tag and Push the image to local harbor
docker tag ${IMAGE} ${HARBORURL}:443/llm-graph-builder/llm-graph-builder-backend:latest
docker tag ${IMAGE} ${HARBORURL}:443/llm-graph-builder/llm-graph-builder-backend:${VERSIONTAG}
docker push ${HARBORURL}:443/llm-graph-builder/llm-graph-builder-backend:latest
docker push ${HARBORURL}:443/llm-graph-builder/llm-graph-builder-backend:${VERSIONTAG}

#Tag and Push the image to public docker hub repo
# docker login -u ugoogalizer docker.io/ugoogalizer/llm-graph-builder-backend
# docker tag ${IMAGE} docker.io/ugoogalizer/llm-graph-builder-backend:latest
# docker tag ${IMAGE} docker.io/ugoogalizer/llm-graph-builder-backend:${VERSIONTAG}
# docker push docker.io/ugoogalizer/llm-graph-builder-backend:latest
# docker push docker.io/ugoogalizer/llm-graph-builder-backend:${VERSIONTAG}
```


### Build the Customised frontend image
``` bash
# Ensure you have the latest 
git pull

#Set Build Parameters
export VERSIONTAG=0.5

# FRONTEND
cd ~/llm-graph-builder/frontend

# Set Default Environment Args: 
# source example.env
# Set Override Environment Args:
# VITE_BACKEND_API_URL="http://backend.llm-graph-builder.svc.cluster.local:8000"
# VITE_LLM_MODELS_PROD="ollama_qwen2.5-coder,openai_gpt_4o,openai_gpt_4o_mini,diffbot,gemini_1.5_flash"
# VITE_LLM_MODELS="ollama_qwen2.5-coder,diffbot,openai_gpt_3.5,openai_gpt_4o"

#Build the Image
docker build -t llm-graph-builder-frontend:latest -t llm-graph-builder-frontend:${VERSIONTAG} . \
  --build-arg VITE_SKIP_AUTH="true" \
  --build-arg VITE_FRONTEND_HOSTNAME="localhost:8080" \
  --build-arg VITE_BATCH_SIZE=2 \
  --build-arg VITE_ENV="DEV" \
  --build-arg VITE_TIME_PER_PAGE=50 \
  --build-arg VITE_CHUNK_SIZE=5242880 \
  --build-arg VITE_CHUNK_OVERLAP=20 \
  --build-arg VITE_TOKENS_PER_CHUNK=100 \
  --build-arg VITE_CHUNK_TO_COMBINE=1 \
  --build-arg VITE_LARGE_FILE_SIZE=5242880 \
  --build-arg VITE_REACT_APP_SOURCES="local,youtube,wiki,s3,web" \
  --build-arg VITE_BACKEND_API_URL="https://llm-graph-builder-backend.rockyroad.rocks" \
  --build-arg VITE_LLM_MODELS_PROD="ollama_deepseek-r1,ollama_qwen2.5-coder,openai_gpt_4o,openai_gpt_4o_mini,diffbot,gemini_1.5_flash" \
  --build-arg VITE_LLM_MODELS="ollama_deepseek-r1,ollama_qwen2.5-coder,diffbot,openai_gpt_3.5,openai_gpt_4o"


  # --build-arg VITE_BACKEND_API_URL="http://backend.llm-graph-builder.svc.cluster.local:8000" 

#Get the image name, it will be something like 41d81c9c2d99: 
export IMAGE=$(docker images -q llm-graph-builder-frontend:latest)
echo ${IMAGE}

#Login to local harbor
docker login ${HARBORURL}:443

#Tag and Push the image to local harbor
docker tag ${IMAGE} ${HARBORURL}:443/llm-graph-builder/llm-graph-builder-frontend:latest
docker tag ${IMAGE} ${HARBORURL}:443/llm-graph-builder/llm-graph-builder-frontend:${VERSIONTAG}
docker push ${HARBORURL}:443/llm-graph-builder/llm-graph-builder-frontend:latest
docker push ${HARBORURL}:443/llm-graph-builder/llm-graph-builder-frontend:${VERSIONTAG}

#Tag and Push the image to public docker hub repo
# docker login -u ugoogalizer docker.io/ugoogalizer/llm-graph-builder-frontend
# docker tag ${IMAGE} docker.io/ugoogalizer/llm-graph-builder-frontend:latest
# docker tag ${IMAGE} docker.io/ugoogalizer/llm-graph-builder-frontend:${VERSIONTAG}
# docker push docker.io/ugoogalizer/llm-graph-builder-frontend:latest
# docker push docker.io/ugoogalizer/llm-graph-builder-frontend:${VERSIONTAG}
```

