# Outline for multiple deployments throught the day

Premise: we are responsible for developing, deploying, and supporting a simple application throughout its lifecycle.  

We will deal with the initial deployment, then 

## Intro

## Workstation Setup

## Git  - getting the application code

## Discovering Application Dependencies - what does the app need?

## Deciding How to Deploy App and its platform components

### Apache cookbook <-- intro to chef
  not a great TDD example - DEB auto-starts the service! - we want something that is broken by default :)
  We might be hitting them with DO, Test Kitchen, Chef, and TDD simultaneously :(
  Wanted: some way of splitting DO out, as a separate module?
##### git commit
### widgetworld cookbook <-- intro to TDD
#### Say what you want to see on the machine (the application code should exist), RED
##### git commit
#### Make it work, badly (crude file copy) GREEN
##### git commit
#### Will refactor later using capistrano-under-chef!
### Postgres and passenger cookbooks provided by instructors
#### If there are new concepts introduced, by all means teach them
#### Or they can be kept on as enrichment - watch the clock, if we're ahead, we dive in; if we're behind, we hand them working cookbooks; if we end early, we can circle back.

## Deploy to Testing!
### Spinup machines - one per team?
### Something goes wrong - something planned
### Requires a cookbook iteration
#### topic branch 
#### Write a failing test first
#### Make the test pass
#### re-deploy

## Launch Day!
### Spinup machines!
### How do you know it's working?
#### Evil mode: instructor runs script to kill postgres
#### Let attendees diagnose manually for a while

## Monitoring, Shcmonitoring
### Monitoring tiers
### Picking a monitoring system
### Connecting to a monitoring system
### Configure monitoring like anything else, via chef
### Alerting

## Marketing Promised a New Widget
### Developers scramble to develop it
#### Unrealistic time budget
#### They exceed it 
#### Ops' deadline doesn't move, but their start date does
#### How can they get ahead of it?
### Time to deploy a incremental change!
#### crude file copy doesn't support versioning
#### iterate on cookbook, TDD
##### code deployment test should now watch for version deployed (RED)
##### capistrano or git deployment should deploy version (GREEN)
