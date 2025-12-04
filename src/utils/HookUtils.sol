// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Hooks} from "v4-core/libraries/Hooks.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";

/// @title HookUtils
/// @notice Utilitários para trabalhar com hooks do Uniswap V4
library HookUtils {
    using Hooks for IHooks;
    
    /// @notice Calcula o endereço do hook com flags corretas
    /// @param flags Flags de permissão do hook
    /// @return hookAddress Endereço calculado com flags
    function calculateHookAddress(uint160 flags) internal pure returns (address hookAddress) {
        uint160 hookPermissionCount = 14;
        uint160 clearAllHookPermissionsMask = ~uint160(0) << hookPermissionCount;
        
        return address(
            uint160(
                type(uint160).max & clearAllHookPermissionsMask | flags
            )
        );
    }

    /// @notice Valida se um hook tem as permissões corretas
    /// @param hook Endereço do hook
    /// @param permissions Permissões esperadas
    /// @return isValid Se o hook tem as permissões corretas
    function validateHookPermissions(
        IHooks hook,
        Hooks.Permissions memory permissions
    ) internal pure returns (bool isValid) {
        Hooks.validateHookPermissions(hook, permissions);
        return true; // Se não reverteu, é válido
    }

    /// @notice Verifica se um hook tem uma permissão específica
    /// @param hook Endereço do hook
    /// @param flag Flag de permissão
    /// @return hasPermission Se o hook tem a permissão
    function hasPermission(IHooks hook, uint160 flag) internal pure returns (bool) {
        return hook.hasPermission(flag);
    }
}

