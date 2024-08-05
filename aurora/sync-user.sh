#!/usr/bin/env bash

cd $HOME
flatpak update -y

sudo cp -R /usr/gradle_home $HOME/.gradle
sudo chown -R $USER:$USER $HOME/.gradle

cp -R /usr/minecraft/forge $HOME
find . -name "*.launch" | xargs sed -i -e "s/usr/home\/$USER/g" -e 's:minecraft\/forge:forge:g'

cd forge
./gradlew runClient

