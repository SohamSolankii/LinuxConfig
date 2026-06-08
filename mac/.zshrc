export GITHUB_TOKEN="YOUR_GITHUB_TOKEN_HERE"

export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"
export PATH="/usr/local/bin:$PATH"
export PATH="/usr/local/bin:$PATH"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion


export ZSH="$HOME/.oh-my-zsh"
export ZSH_CUSTOM="$ZSH/custom"

plugins=(
	git
	zsh-autosuggestions
	zsh-syntax-highlighting
	fast-syntax-highlighting
)

ZSH_THEME="gozilla"
# ZSH_THEME="minimal"

source $ZSH/oh-my-zsh.sh


alias start="npm start"

# git aliases
alias gc="git checkout"
alias gp='git pull'
alias unstage='git restore --staged .gitignore'
alias gaa='git add . -- ":(exclude)package.json" ":(exclude)switch.sh"'
alias grs='git restore --staged .'
alias gr='git restore .'
alias gcm='git commit -m'

alias notes='$EDITOR ~/notes.txt'

# application aliases
alias slack="open -a Slack"
alias db="open -a DataGrip"
alias pm="open -a Postman"
alias wh="open -a WhatsApp"
alias leapp="open -a Leapp"
alias chrome="open -a Google\ Chrome"
alias podman="open -a Podman\ Desktop"
alias spotify="open -a Spotify"
alias dia="open -a Dia"

# Added by Antigravity
export PATH="/Users/apple/.antigravity/antigravity/bin:$PATH"

# g++ version change from apple clang to homebrew g++
alias g++=g++-15
alias gcc=gcc-15


# env switch script for graphqlapi
se() {
  ENV_NAME=$1
  REGION=$2
  PACKAGE_FILE="package.json"

  if [ -z "$ENV_NAME" ]; then
    echo "Usage:"
    echo "  se staging"
    echo "  se preprod"
    echo "  se develop"
    echo "  se prod us-east-1"
    echo "  se lrt"
    return 1
  fi

  ############################################
  # LRT (SECOND REPO)
  ############################################
  if [[ "$ENV_NAME" == "lrt" ]]; then
    echo "🚀 Switching LRT repo..."

    sed -i '' '/"start":/c\
      "start": "rm -rf esbuild && REGION=eu-west-1 ENV_ENABLE_SENTRY=0 ENV=staging DISTRIBUTION=platform _IS_LOCAL=true node ./esbuild.config.mjs",' "$PACKAGE_FILE"

    FILE="src/index.js"

    # Add PORT if missing
    grep -q "const PORT = 3009" "$FILE" || \
    sed -i '' '1s/^/const PORT = 3009;\n/' "$FILE"

    # Replace port usage
    sed -i '' 's/app.listen(3001/app.listen(PORT/' "$FILE"
    sed -i '' 's/listening on 3001/listening on 3009/' "$FILE"

    echo "✅ LRT setup applied (PORT=3009, ENV=staging)"
    return 0
  fi

  ############################################
  # BASE START SCRIPT
  ############################################
  BASE_START="rm -rf .esbuild && NODE_OPTIONS='--enable-source-maps --dns-result-order=ipv4first --no-network-family-autoselection' ENV_ENABLE_SENTRY=0 npx serverless offline"

  ############################################
  # DEFAULTS
  ############################################
  STAGE="development"
  REGION_VAL="eu-west-1"
  EXTRA_FLAGS="--httpPort 3001 --param='local=true' --noTimeout"
  PREFIX=""

  ############################################
  # ENV LOGIC
  ############################################
  if [[ "$ENV_NAME" == "staging" || "$ENV_NAME" == "preprod" ]]; then
    STAGE="$ENV_NAME"

  elif [[ "$ENV_NAME" == "prod" ]]; then
    if [ -z "$REGION" ]; then
      echo "❌ Region required for prod"
      return 1
    fi

    STAGE="production"
    REGION_VAL="$REGION"
    PREFIX="DB_READ_ONLY=1 "

    # Production file updates
    sed -i '' 's/^  global.analyticsDb/  \/\/ global.analyticsDb/' src/lib/initialization/globals.js
    sed -i '' 's/runGraphQLPlayground:.*/runGraphQLPlayground: true,/' src/config/production/defaults.js
    sed -i '' 's/graphqlIntrospection:.*/graphqlIntrospection: true,/' src/config/production/defaults.js

    awk -v region="$REGION" '
    $1 == "production:" { in_prod=1 }

    in_prod && $1 == region ":" {
        in_region=1
        print
        next
    }

    in_region && $1 == "REDIRECTION_PERCENTAGE_TO_SLAVE:" {
        print "    REDIRECTION_PERCENTAGE_TO_SLAVE: 0"
        in_region=0
        next
    }

    { print }
    ' env.yml > temp.yml && mv temp.yml env.yml

  elif [[ "$ENV_NAME" == "develop" ]]; then
    echo "🔄 Resetting to development state..."

    git checkout -- package.json \
                   src/lib/initialization/globals.js \
                   src/config/production/defaults.js \
                   env.yml

    echo "✅ Restored files from git"
    return 0

  else
    echo "❌ Invalid environment"
    return 1
  fi

  ############################################
  # BUILD FINAL START SCRIPT
  ############################################
  if [[ "$ENV_NAME" == "prod" ]]; then
    FINAL_START="rm -rf .esbuild && ${PREFIX}NODE_OPTIONS='--enable-source-maps --dns-result-order=ipv4first --no-network-family-autoselection' ENV_ENABLE_SENTRY=0 npx serverless offline -s $STAGE -r $REGION_VAL $EXTRA_FLAGS"
  else
    FINAL_START="$BASE_START -s $STAGE -r $REGION_VAL $EXTRA_FLAGS"
  fi

  ############################################
  # SAFE JSON REPLACE
  ############################################
  sed -i '' '/"start":/c\
    "start": "'"$FINAL_START"'",' "$PACKAGE_FILE"

  echo "✅ Switched to $ENV_NAME ($REGION_VAL)"
}

export JAVA_HOME=$(/usr/libexec/java_home)
export PATH=$JAVA_HOME/bin:$PATH
