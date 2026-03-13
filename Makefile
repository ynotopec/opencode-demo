SHELL := /usr/bin/env bash

.PHONY: up down status check help

up:
	./opencode.sh up

down:
	./opencode.sh down

status:
	./opencode.sh status

check:
	bash -n opencode.sh start-opencode.sh stop-opencode.sh

help:
	@echo "Targets: up, down, status, check"
