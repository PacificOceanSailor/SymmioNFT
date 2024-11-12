// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract SymmioNFTProxy is TransparentUpgradeableProxy{
    constructor(address _logic, address _admin) 
        TransparentUpgradeableProxy(_logic, _admin, abi.encodeWithSignature("initialize()")) 
    {}

    function get_admin() external view returns(address){
        return _proxyAdmin();
    }
}
