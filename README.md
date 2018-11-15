# ESP32 Development Environment Docker Image (WIP) 

Another general-purpose ESP32 development environment docker image, with built-in ESP-IDF, ESP toolchains, Vim and KDevelop IDE.

## Build

```
docker build -t jacksonhu2207/esp32-cmake-dev .
```

## Run

With X11 configs (for KDevelop) passing in:

```
docker run --rm -it -v YOUR_PROJECT_DIR:/home/developer/project --net=host --env="DISPLAY" --volume="$HOME/.Xauthority:/root/.Xauthority:rw"  jacksonhu2207/esp32-cmake-dev
```

Without X11 configs passing in:
```
sudo docker run --rm -it -v YOUR_PROJECT_DIR:/home/developer/project jacksonhu2207/esp32-cmake-dev
```