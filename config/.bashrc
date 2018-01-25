# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
        . /etc/bashrc
fi

# User specific aliases and functions
PATH=$PATH:$HOME/bin:$HOME/php/bin:$HOME/nginx/sbin:$HOME/redis/bin:$HOME/mongodb/3.4.9/bin
export PATH

alias supervisorctl='supervisorctl -c /home/worker/supervisor/supervisord.conf'
alias logn="tail -F /home/worker/data/nginx/logs/* /home/worker/data/nginx/logs/*"
alias logp="tail -F /home/worker/data/php/log/*"
alias logr="tail -F /home/worker/data/www/runtime/*/*.log"
