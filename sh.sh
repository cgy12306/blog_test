#!/bin/bash

#hugo -t compose

cd public
git pull origin master
git add .
git commit -m "test"
git push origin master
cd ..
git pull origin master
git add .
git commit -m "test"
git push origin master


