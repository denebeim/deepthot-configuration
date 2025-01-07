# Deployments

This directory contains that either haven't been automated or don't need automation.

For instance deploying awx is just cd awx dir, kubectl -k .   Which doesn't seem to be needing automation.

Helm charts are, or should be the same way.

The important thing is anything in here should be deployed with one command.  All the orchestration must be in 
the kustomize/helm steps.

There is one issue that I still have, namely secrets.  I'm using ansible vault for my secrets atm and that won't work from the command line.  They've gotta be called from ansible.  Secrets need to be addressed better.  I'm thinking hashicorp vault, but I haven't gotten there yet.
