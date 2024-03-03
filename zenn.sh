#!/bin/bash

read -p "slug名を入力してください。YYYYMMDD-部分は不要：" slug
fullslug="$(date '+%Y%m%d')-${slug}"
npx zenn new:article --slug "${fullslug}"
mkdir images/"${fullslug}"
