#!/bin/bash
export RED='\033[0;31m'
export YELLOW='\033[1;33m'
export GREEN='\033[0;32m'
export BLUE='\033[0;34m'
export BROWN='\033[0;33m'
export PURPLE='\033[0;35m'
export NC='\033[0m' # No Color

clear

echo -e "${GREEN}Execute commit(default message: 'building terraform') - press enter to continue...${NC}"
read varinput
git add .

git commit -m "building terraform"

echo -e "${GREEN}Execute push - press enter to continue...${NC}"
read varinput
git push