
ifeq "$(PROXY_DATABASE_TYPE)" ""
    database:=mysql
else
    database:=$(PROXY_DATABASE_TYPE)
endif

.PHONY: all

all: build test

clean:
	mix deps.clean --all

build:
	mix deps.get && mix compile

test:
	MIX_ENV=test PROXY_DATABASE_TYPE=$(database) SPAWN_STATESTORE_KEY=3Jnb0hZiHIzHTOih7t2cTEPEpY98Tu1wvQkPfq/XwqE= elixir --name federated_01@127.0.0.1 -S mix test

run:
	MIX_ENV=prod mix deps.get
	MIX_ENV=prod PROXY_DATABASE_TYPE=$(database) SPAWN_STATESTORE_KEY=3Jnb0hZiHIzHTOih7t2cTEPEpY98Tu1wvQkPfq/XwqE= iex --name federated_01@127.0.0.1 -S mix

