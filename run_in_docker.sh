#!/bin/bash

docker run -it --rm  --privileged --security-opt seccomp=unconfined --tmpfs /run --tmpfs /run/lock -v /sys/fs/cgroup:/sys/fs/cgroup:ro mhvtl:latest /bin/bash


