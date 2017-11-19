This library compiles [PaPiRus](https://github.com/PiSupply/PaPiRus) into the [resin](https://resin.io/) Docker container for the Raspberry Pi 1/Zero.

To use this docker image, inherit from it.

```
FROM andrewneo/resin-papirus-rpi:1.0

WORKDIR /app
ADD . /app

CMD ["python3", "main.py"]
```
