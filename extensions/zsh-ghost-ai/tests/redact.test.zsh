# Redaction and ignore patterns: unit tests in the runner's shell.

source $ZGA_ROOT/lib/config.zsh
source $ZGA_ROOT/lib/redact.zsh

_r() { _zga_redact "$1"; print -rn -- "$REPLY"; }
local R='<redacted>'

t_case "redact tokens"
t_eq "$(_r 'gh auth login --with-token ghp_abcdefghijklmnopqrstuvwxyz0123456789')" "gh auth login --with-token $R" "GitHub token"
t_eq "$(_r 'echo github_pat_11ABCDEFG_abcdefghijk')"       "echo $R"            "GitHub fine-grained token"
t_eq "$(_r 'curl -H x sk-ant-api03-abcdefghijklmnop')"     "curl -H x $R"       "Anthropic-style key"
t_eq "$(_r 'aws configure set aws_access_key_id AKIAIOSFODNN7EXAMPLE')" "aws configure set aws_access_key_id $R" "AWS access key"
t_eq "$(_r 'jwt eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIn0.abc123')" "jwt $R"         "JWT"
t_eq "$(_r 'slack xoxb-1234-5678-abcdef')"                  "slack $R"           "Slack token"
t_eq "$(_r 'git push https://oauth2:glpat-abcDEF123_xyz@gitlab.com/x.git')" "git push https://oauth2:$R@gitlab.com/x.git" "GitLab token in a URL"

t_case "redact assignments and flags"
t_eq "$(_r 'export DATABASE_URL=postgres://u:p@h/db')"      "export DATABASE_URL=$R" "any exported value"
t_eq "$(_r 'export NAME="two words"')"                      "export NAME=$R"     "quoted exported value"
t_eq "$(_r 'API_KEY=abc123 ./run')"                         "API_KEY=$R ./run"   "secret-sounding NAME=value"
t_eq "$(_r 'my_password=hunter2 cmd')"                      "my_password=$R cmd" "case-insensitive names"
t_eq "$(_r 'mysql --password=hunter2 db')"                  "mysql --password=$R db" "--password=value"
t_eq "$(_r 'vault login --token s.abcdef')"                 "vault login --token $R" "--token value"
t_eq "$(_r 'curl -H "Authorization: Bearer abc.def"')"      "curl -H \"Authorization: Bearer $R\"" "Authorization header"
t_eq "$(_r 'curl https://user:hunter2@example.com/x')"      "curl https://user:$R@example.com/x" "password in a URL"

t_case "leave ordinary commands alone"
local cmd
for cmd in 'mkdir -p foo/bar' 'git commit -m "fix token parsing"' 'ls -la ~/.ssh' \
           'echo $PATH' 'docker ps -a --format "{{.Names}}"' 'skip-tests=true make' \
           'cd ~/Devspace/Cybercore' 'ssh git@github.com'; do
  t_eq "$(_r "$cmd")" "$cmd" "unchanged: $cmd"
done

t_case "ignore pattern"
_i() { _zga_ignored "$1" && print -n yes || print -n no; }
t_eq "$(_i 'pass show github')"     "yes" "pass"
t_eq "$(_i 'gpg --decrypt x.gpg')"  "yes" "gpg"
t_eq "$(_i 'ssh-add ~/.ssh/key')"   "yes" "ssh-add"
t_eq "$(_i 'echo $AWS_SECRET')"     "yes" "case-insensitive *secret*"
t_eq "$(_i 'git status')"           "no"  "ordinary command"
t_eq "$(_i 'passwd')"               "yes" "passwd"
