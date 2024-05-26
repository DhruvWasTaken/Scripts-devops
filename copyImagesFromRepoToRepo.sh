#!/bin/bash
set -e

################################# UPDATE THESE #################################
LAST_N_TAGS=10

SOURCE_REGION="us-west-2"
DESTINATION_REGION="us-west-2"

# SOURCE_PROFILE="profile_1"
#DESTINATION_PROFILE="profile_2"

SOURCE_BASE_PATH="224817087040.dkr.ecr.$SOURCE_REGION.amazonaws.com"
DESTINATION_BASE_PATH="224817087040.dkr.ecr.$DESTINATION_REGION.amazonaws.com"
#################################################################################

URI="224817087040.dkr.ecr.us-west-2.amazonaws.com/testgcci"
SNAME="testgcci"
DNAME="ecr-test"

echo "Start repo copy: `date`"

# source account login
aws --region $SOURCE_REGION ecr get-login-password | docker login --username AWS --password-stdin $SOURCE_BASE_PATH

# destination account login
# aws --region $DESTINATION_REGION ecr get-login-password | docker login --username AWS --password-stdin $DESTINATION_BASE_PATH


# for i in ${!URI[@]}; do
echo "====> Grabbing latest $LAST_N_TAGS from ${SNAME} repo"
# create ecr repo if one does not exist in destination account
aws ecr describe-repositories --repository-names ${DNAME} || aws ecr create-repository --repository-name ${DNAME}

for tag in $(aws ecr describe-images --repository-name ${SNAME} \
  --query 'sort_by(imageDetails,& imagePushedAt)[*]' \
  --filter tagStatus=TAGGED --output text \
  | grep IMAGETAGS | awk '{print $2}' | tail -$LAST_N_TAGS); do

  echo "start pulling image ${URI}:$tag"
  docker pull ${URI}:$tag
  docker tag ${URI}:$tag $DESTINATION_BASE_PATH/${DNAME}:$tag

  echo "start pushing image $DESTINATION_BASE_PATH/${DNAME}:$tag"
  docker push $DESTINATION_BASE_PATH/${DNAME}:$tag
  echo ""
done
# done

echo "Finish repo copy: `date`"
echo "Don't forget to purge you local docker images!"
#Uncomment to delete all
#docker rmi $(for i in ${!NAME[@]}; do docker images | grep ${NAME[$i]} | tr -s ' ' | cut -d ' ' -f 3 | uniq; done) -f