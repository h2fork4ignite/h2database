#!/usr/bin/env bash
set -o nounset
set -o errexit
set -o pipefail
set -o errtrace
set -o functrace


RELEASE_VERSION=${1:-}
DEVELOPMENT_VERSION=${2:-}
ROOT_DIR=$(realpath $(dirname "${BASH_SOURCE[0]}")/..)


cd ${ROOT_DIR}
REMOTE=$(git remote -v | grep "git@github.com:h2fork4ignite/sql-engine.git" | awk {'print $1'} | uniq)
PROJECT_VERSION=$(mvn -q help:evaluate -Dexpression=project.version -DforceStdout)
if [ "${RELEASE_VERSION}" == "" ]; then
    RELEASE_VERSION=$(sed -r 's|-SNAPSHOT||' <<< ${PROJECT_VERSION})
fi
if [ "${DEVELOPMENT_VERSION}" != "" ]; then
    grep -qE "^[0-9]+\.[0-9]+(.[0-9]+)*-SNAPSHOT$" <<< ${DEVELOPMENT_VERSION} || {
        echo "[ERROR] New development version is invalid"
        exit 1
    }
else
    DEVELOPMENT_VERSION=$(sed -r 's|([0-9]+\.)([0-9]+)(.*)|echo "\1$((\2+1))\3"|ge' <<< ${PROJECT_VERSION})
fi


# Create release branch
echo 
echo "################################"
echo "#   1. CREATE RELEASE BRANCH   #"
echo "################################"
git fetch --prune --tags --all --force
git checkout master
git pull
git checkout -b release-${RELEASE_VERSION}

mvn versions:set -N \
                 -DnewVersion=${RELEASE_VERSION} \
                 -DgenerateBackupPoms=false \
                 -DgroupId=* -DartifactId=* -DoldVersion=* \
                 -DprocessDependencies=false

git add -u
git commit -m "Prepared release ${RELEASE_VERSION} branch"


# Update master branch
echo
echo "###############################"
echo "#   2. UPDATE MASTER BRANCH   #"
echo "###############################"
git checkout master

mvn versions:set -N \
                 -DnewVersion=${DEVELOPMENT_VERSION} \
                 -DgenerateBackupPoms=false \
                 -DgroupId=* -DartifactId=* -DoldVersion=* \
                 -DprocessDependencies=false

git add -u
git commit -m "Next development iteration of version $(sed -r 's|-SNAPSHOT||'<<< ${DEVELOPMENT_VERSION})"


# Push changes
echo
echo "############################################"
echo "#   3. Push changes to remote repository   #"
echo "############################################"
while true; do
    read -n 1 -p "Push changes to repository? [y/n] " answer
    grep -qiE "(y|n)" <<< ${answer} && break || {
        echo "[ERROR] Answer should be y(es) or n(o)"
    }
done
case ${answer} in
    y|Y)
        git push ${REMOTE} release-${RELEASE_VERSION}
        git push ${REMOTE} master
        ;;
    n|N)
        echo
        echo "To push changes to repository, you should execute the following commands:"
        echo "    > git push ${REMOTE} release-${RELEASE_VERSION} - push release branch"
        echo "    > git push ${REMOTE} master - push master branch"
        ;;
esac

