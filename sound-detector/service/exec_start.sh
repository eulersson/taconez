CONTAINER_NAME=anesowa-sound-detector-prod
if [[ "$(docker ps -aq --filter name=$CONTAINER_NAME)" = "" ]]; then
  echo Container already exists, starting instead of creating a new one.
  docker start anesowa-sound-detector-prod
else
  echo Container does not exist, creating a new one.
  bash /home/anesowa/sound-detector/docker/run_prod.sh
fi

