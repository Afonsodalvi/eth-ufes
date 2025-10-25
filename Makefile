-include .env

ifeq ($(network),sepolia)
	NETWORK_ARGS := --rpc-url $(ETHEREUM_SEPOLIA_RPC) $(EXPLORER_API_KEY) --broadcast
	EXPLORER_API_KEY := --etherscan-api-key $(ETHERSCAN_API_KEY)
	CHAIN_ID := 11155111
endif

ifeq ($(network),ethereum)
	NETWORK_ARGS := --rpc-url $(ETHEREUM_RPC_URL) --broadcast --verify -vvvv
	CHAIN_ID := 1
endif

ifeq ($(network),amoy)
	NETWORK_ARGS := --rpc-url $(AMOY_RPC_URL) --etherscan-api-key $(EXPLORER_API_KEY) --verifier-url https://api.etherscan.io/v2/api?chainid=80002 --broadcast --gas-limit 30000000 --gas-price 20000000000 --gas-estimate-multiplier 200 --verify -vvvv
	CHAIN_ID := 80002
endif

ifeq ($(network),polygon)
	NETWORK_ARGS := --rpc-url $(POLYGON_RPC_URL) --etherscan-api-key $(EXPLORER_API_KEY) --verifier-url https://api.etherscan.io/v2/api?chainid=137 --broadcast --gas-estimate-multiplier 200 --verify
	CHAIN_ID := 137
endif

# ===========================================
# COMANDOS DE DEPLOY
# ===========================================

# Deploy individual de contratos
deploy-counter:
	forge script script/Counter.s.sol:CounterScript $(NETWORK_ARGS)

deploy-class-vote:
	forge script script/ClassVote.s.sol:ClassVoteScript $(NETWORK_ARGS)

deploy-escrow:
	forge script script/Escrow.s.sol:EscrowScript $(NETWORK_ARGS)

deploy-time-lock:
	forge script script/TimeLockVault.s.sol:TimeLockVaultScript $(NETWORK_ARGS)

deploy-safe-piggy:
	forge script script/SafePiggy.s.sol:SafePiggyScript $(NETWORK_ARGS)

# Deploy todos os contratos
deploy-all:
	forge script script/DeployAll.s.sol:DeployAllScript $(NETWORK_ARGS)

# Deploy com verificação
deploy-verify:
	forge script script/DeployAll.s.sol:DeployAllScript $(NETWORK_ARGS) --verify

# Deploy local (Anvil)
deploy-local:
	forge script script/DeployAll.s.sol:DeployAllScript --rpc-url http://localhost:8545 --broadcast

# Deploy com logs detalhados
deploy-verbose:
	forge script script/DeployAll.s.sol:DeployAllScript $(NETWORK_ARGS) -vvvv

# ===========================================
# COMANDOS DE TESTE
# ===========================================

# Testar todos os contratos
test-all:
	forge test

# Testar contratos específicos
test-counter:
	forge test --match-contract CounterTest

test-class-vote:
	forge test --match-contract ClassVoteTest

test-escrow:
	forge test --match-contract EscrowTest

test-time-lock:
	forge test --match-contract TimeLockVaultTest

test-safe-piggy:
	forge test --match-contract SafePiggyTest

# Testar com gas report
test-gas:
	forge test --gas-report

# ===========================================
# COMANDOS DE BUILD E VERIFICAÇÃO
# ===========================================

# Build todos os contratos
build:
	forge build

# Limpar artifacts
clean:
	forge clean

# Verificar contratos
verify:
	forge verify-contract $(CONTRACT_ADDRESS) $(CONTRACT_PATH) --etherscan-api-key $(ETHERSCAN_API_KEY)

# ===========================================
# COMANDOS DE DESENVOLVIMENTO
# ===========================================

# Iniciar rede local
anvil:
	anvil

# Deploy em rede local
deploy-anvil:
	forge script script/DeployAll.s.sol:DeployAllScript --rpc-url http://localhost:8545 --broadcast --private-key $(PRIVATE_KEY)

# Interagir com contratos
interact:
	cast call $(CONTRACT_ADDRESS) "functionName()" --rpc-url $(RPC_URL)

# ===========================================
# COMANDOS DE UTILIDADE
# ===========================================

# Mostrar informações da rede
network-info:
	@echo "Network: $(network)"
	@echo "RPC URL: $(RPC_URL)"
	@echo "Chain ID: $(CHAIN_ID)"
	@echo "Explorer: $(EXPLORER_URL)"

# Salvar endereços dos contratos
save-addresses:
	@echo "Contract addresses saved to deployed-contracts.json"

# Verificar saldo
check-balance:
	cast balance $(ADDRESS) --rpc-url $(RPC_URL)

# Verificar nonce
check-nonce:
	cast nonce $(ADDRESS) --rpc-url $(RPC_URL)