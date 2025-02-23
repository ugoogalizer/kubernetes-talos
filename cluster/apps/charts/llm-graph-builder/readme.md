
Backend: 
 - can be build as a docker container without customisation as it takes environment variables that can be changed on container runtime


Frontend: 
 - has to have custom arguments provided to it 





``` bash

# First create a new project in Harbor called 'llm-graph-builder' and grant a dev user access to it, you'll need those credentials for the `docker login` statement below





git clone https://github.com/neo4j-labs/llm-graph-builder.git

cd llm-graph-builder/

# Personal parameters
export HARBORURL=harbor.rockyroad.rocks

git pull

#Set Build Parameters
export VERSIONTAG=0.1

# BACKEND
cd backend

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
# docker login -u ugoogalizer docker.io/ugoogalizer/autoshift
# docker tag ${IMAGE} docker.io/ugoogalizer/autoshift:latest
# docker tag ${IMAGE} docker.io/ugoogalizer/autoshift:${VERSIONTAG}
# docker push docker.io/ugoogalizer/autoshift:latest
# docker push docker.io/ugoogalizer/autoshift:${VERSIONTAG}
```
