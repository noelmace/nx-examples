set -e
set -x

# VERSIONS=(8.9.0 9.0.4 9.1.4 9.2.4 9.3.0 9.4.5 9.5.1 9.6.0 9.7.1 9.8.0 10.0.13 10.1.0 10.2.1 10.3.3 10.4.15 11.0.20 11.1.0 11.1.5 11.2.12 11.3.2 11.4.0 11.5.2 11.6.3 12.0.8 12.1.1 12.2.0 12.3.4)
VERSIONS=(9.5.1 9.6.0 9.7.1 9.8.0 10.0.13 10.1.0 10.2.1 10.3.3 10.4.15 11.0.20 11.1.0 11.1.5 11.2.12 11.3.2 11.4.0 11.5.2 11.6.3 12.0.8 12.1.1 12.2.0 12.3.4)

CURRENT_NX_VERSION=$(awk -F \" '/"@nrwl\/workspace": ".+"/ { print $4; exit; }' package.json)

echo "Current Nx Version: $CURRENT_NX_VERSION"

# SEARCH_VERSION=">${CURRENT_NX_VERSION} <13"
# NEXT_NX_VERSION=$(npm view @nrwl/workspace@"${SEARCH_VERSION}" version | awk 'NR==1 {gsub(/\047/, "", $2); print $2}')

notify-and-stop() {
  message=${1:?"A message must be specified."}

  notify-send "NX Upgrade Stopped" "$message" -u critical
  paplay /usr/share/sounds/freedesktop/stereo/complete.oga

  read -p "$message (Y/n)" -n 1 -r
  if [[ $REPLY =~ ^[Nn]$ ]]
  then
      exit 2
  fi
}

migrate() {
  NX_VERSION=${1:?"The major version must be specified."}

  rm -rf /tmp/tmp-*

  # NX_VERSION=$(npm view @nrwl/workspace@~${NX_MINOR_VERSION} version | awk 'END {gsub(/\047/, "", $2); print $2}')

  # if [ -z "$NX_VERSION" ]; then
  #   echo "no matching version for @nrwl/workspace@~${NX_MINOR_VERSION}";
  #   exit 1;
  # else
  #   echo "updating to $NX_VERSION"
  # fi

  nx migrate $NX_VERSION

  notify-and-stop "Run yarn install"

  yarn

  notify-and-stop "Commit update"

  git add --all
  git commit -m "nx migrate $NX_VERSION"

  if [ -f "./migrations.json" ]; then

    nx migrate --run-migrations=migrations.json > docs/nx-migrate-${NX_MINOR_VERSION//\./-}-0.log

    notify-and-stop "Commit current migrations"

    rm -f migrations.json
    git add --all
    git commit -m "run migration to $NX_MINOR_VERSION"
  fi
}

for VERSION in ${VERSIONS[*]}; do
  notify-and-stop "Run nx migration $VERSION"
  migrate ${VERSION}
done

