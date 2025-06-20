# This is a basic workflow to help you get started with Actions

name: CI # name of the workflow it is optional

# Controls when the workflow will run
on:
  # Triggers the workflow on push or pull request events but only for the "main" branch
  # Events https://docs.github.com/en/actions/writing-workflows/choosing-when-your-workflow-runs/events-that-trigger-workflows
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]

  # Allows you to run this workflow manually from the Actions tab
  workflow_dispatch:

# A workflow run is made up of one or more jobs that can run sequentially or in parallel but default is parallel 
jobs:
  # This workflow contains a single job called "build"
  build:
    # The type of runner that the job will run on
    runs-on: ubuntu-latest

    # Steps represent a sequence of tasks that will be executed as part of the job
    steps:
      # Checks-out your repository under $GITHUB_WORKSPACE, so your job can access it
      - uses: actions/checkout@v4

      # Runs a single command using the runners shell
      - name: Run a one-line script
        run: echo Hello, world!

      # Runs a set of commands using the runners shell
      - name: Run a multi-line script
        run: |
          echo Add other actions to build,
          echo test, and deploy your project.

# Example to run sequential mode:
jobs:
  job1:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Job 1"

  job2:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Job 2"

# Example to run parallel mode:

jobs:
  job1:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Job 1"

  job2:
    runs-on: ubuntu-latest
    needs: job1
    steps:
      - run: echo "Job 2"

# if we have multiple yaml files/workflows under .github/workflows following is the order it will follow.

| Situation                         | Sequence                       |
| --------------------------------- | ------------------------------ |
| Multiple `.yml` with same trigger | No sequence — run in parallel  |
| Jobs in one `.yml` with `needs:`  | Runs sequentially as defined   |
| Use `workflow_run`                | Can trigger workflows in order |


# deploy.yml
on:
  workflow_run:
    workflows: ["Build"]
    types:
      - completed


########## GITHUB WORKFLOW AND ACTION LIMITATIONS ##############

One repository can contain many workflows but only 20 workflows can we running at same time
Job concurrency is also limited depends on github license plan. for free tier it is 20 jobs per repository
Jobs are limited to six hours of runtime
Log file limited to 64 kb

Actions can't trigger workflows

# GitHub blocks workflow triggers if the push was done by another workflow using GITHUB_TOKEN
Example: # .github/workflows/testaction.yml
name: Test Action
on:
  workflow_dispatch:  # Trigger manually for test

jobs:
  simulate_push:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repo
        uses: actions/checkout@v4

      - name: Make a file change
        run: |
          echo "Test at $(date)" >> testtrigger.txt

      - name: Commit & Push using GITHUB_TOKEN
        run: |
          git config user.name "github-actions"
          git config user.email "github-actions@github.com"
          git add testtrigger.txt
          git commit -m "test commit from action"
          git push

# To achieve above one we need to use personal access token
      - name: Push using PAT
        run: |
          git remote set-url origin https://x-access-token:${{ secrets.PAT_TOKEN }}@github.com/${{ github.repository }}
          git push


# workflow_run - it will trigger dependent workflow first and after completing it will trigger current workflow
# workflow_call - if you want reuse the workflow you need to mention this
# workflow_dispatch - if you want to manually trigger the workflow then we can put this in yaml file