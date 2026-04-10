#!/bin/bash

set -e

odin build . -debug

gf2 -ex=r squirrel



