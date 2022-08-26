{\rtf1\ansi\ansicpg936\cocoartf1504\cocoasubrtf830
{\fonttbl\f0\fnil\fcharset134 PingFangSC-Regular;}
{\colortbl;\red255\green255\blue255;}
{\*\expandedcolortbl;;}
{\info
{\author alen}}\vieww17040\viewh14980\viewkind1
\deftab720
\pard\pardeftab720\ri0\partightenfactor0

\f0\fs28 \cf0 // <ORACLIZE_API>\
/*\
Copyright (c) 2015-2016 Oraclize SRL\
Copyright (c) 2016 Oraclize LTD\
\
\
\
Permission is hereby granted, free of charge, to any person obtaining a copy\
of this software and associated documentation files (the "Software"), to deal\
in the Software without restriction, including without limitation the rights\
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell\
copies of the Software, and to permit persons to whom the Software is\
furnished to do so, subject to the following conditions:\
\
\
\
The above copyright notice and this permission notice shall be included in\
all copies or substantial portions of the Software.\
\
\
\
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR\
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,\
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE\
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER\
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,\
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN\
THE SOFTWARE.\
*/\
\
// This api is currently targeted at 0.4.18, please import oraclizeAPI_pre0.4.sol or oraclizeAPI_0.4 where necessary\
\
pragma solidity >=0.4.18;// Incompatible compiler version... please select one stated within pragma solidity or use different oraclizeAPI version\
\
contract OraclizeI \{\
    address public cbAddress;\
    function query(uint _timestamp, string _datasource, string _arg) external payable returns (bytes32 _id);\
    function query_withGasLimit(uint _timestamp, string _datasource, string _arg, uint _gaslimit) external payable returns (bytes32 _id);\
    function query2(uint _timestamp, string _datasource, string _arg1, string _arg2) public payable returns (bytes32 _id);\
    function query2_withGasLimit(uint _timestamp, string _datasource, string _arg1, string _arg2, uint _gaslimit) external payable returns (bytes32 _id);\
    function queryN(uint _timestamp, string _datasource, bytes _argN) public payable returns (bytes32 _id);\
    function queryN_withGasLimit(uint _timestamp, string _datasource, bytes _argN, uint _gaslimit) external payable returns (bytes32 _id);\
    function getPrice(string _datasource) public returns (uint _dsprice);\
    function getPrice(string _datasource, uint gaslimit) public returns (uint _dsprice);\
    function setProofType(byte _proofType) external;\
    function setCustomGasPrice(uint _gasPrice) external;\
    function randomDS_getSessionPubKeyHash() external constant returns(bytes32);\
\}\
\
contract OraclizeAddrResolverI \{\
    function getAddress() public returns (address _addr);\
\}\
\
/*\
Begin solidity-cborutils\
\
https://github.com/smartcontractkit/solidity-cborutils\
\
MIT License\
\
Copyright (c) 2018 SmartContract ChainLink, Ltd.\
\
Permission is hereby granted, free of charge, to any person obtaining a copy\
of this software and associated documentation files (the "Software"), to deal\
in the Software without restriction, including without limitation the rights\
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell\
copies of the Software, and to permit persons to whom the Software is\
furnished to do so, subject to the following conditions:\
\
The above copyright notice and this permission notice shall be included in all\
copies or substantial portions of the Software.\
\
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR\
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,\
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE\
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER\
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,\
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE\
SOFTWARE.\
 */\
\
library Buffer \{\
    struct buffer \{\
        bytes buf;\
        uint capacity;\
    \}\
\
    function init(buffer memory buf, uint capacity) internal pure \{\
        if(capacity % 32 != 0) capacity += 32 - (capacity % 32);\
        // Allocate space for the buffer data\
        buf.capacity = capacity;\
        assembly \{\
            let ptr := mload(0x40)\
            mstore(buf, ptr)\
            mstore(0x40, add(ptr, capacity))\
        \}\
    \}\
\
    function resize(buffer memory buf, uint capacity) private pure \{\
        bytes memory oldbuf = buf.buf;\
        init(buf, capacity);\
        append(buf, oldbuf);\
    \}\
\
    function max(uint a, uint b) private pure returns(uint) \{\
        if(a > b) \{\
            return a;\
        \}\
        return b;\
    \}\
\
    /**\
     * @dev Appends a byte array to the end of the buffer. Reverts if doing so\
     *      would exceed the capacity of the buffer.\
     * @param buf The buffer to append to.\
     * @param data The data to append.\
     * @return The original buffer.\
     */\
    function append(buffer memory buf, bytes data) internal pure returns(buffer memory) \{\
        if(data.length + buf.buf.length > buf.capacity) \{\
            resize(buf, max(buf.capacity, data.length) * 2);\
        \}\
\
        uint dest;\
        uint src;\
        uint len = data.length;\
        assembly \{\
            // Memory address of the buffer data\
            let bufptr := mload(buf)\
            // Length of existing buffer data\
            let buflen := mload(bufptr)\
            // Start address = buffer address + buffer length + sizeof(buffer length)\
            dest := add(add(bufptr, buflen), 32)\
            // Update buffer length\
            mstore(bufptr, add(buflen, mload(data)))\
            src := add(data, 32)\
        \}\
\
        // Copy word-length chunks while possible\
        for(; len >= 32; len -= 32) \{\
            assembly \{\
                mstore(dest, mload(src))\
            \}\
            dest += 32;\
            src += 32;\
        \}\
\
        // Copy remaining bytes\
        uint mask = 256 ** (32 - len) - 1;\
        assembly \{\
            let srcpart := and(mload(src), not(mask))\
            let destpart := and(mload(dest), mask)\
            mstore(dest, or(destpart, srcpart))\
        \}\
\
        return buf;\
    \}\
\
    /**\
     * @dev Appends a byte to the end of the buffer. Reverts if doing so would\
     * exceed the capacity of the buffer.\
     * @param buf The buffer to append to.\
     * @param data The data to append.\
     * @return The original buffer.\
     */\
    function append(buffer memory buf, uint8 data) internal pure \{\
        if(buf.buf.length + 1 > buf.capacity) \{\
            resize(buf, buf.capacity * 2);\
        \}\
\
        assembly \{\
            // Memory address of the buffer data\
            let bufptr := mload(buf)\
            // Length of existing buffer data\
            let buflen := mload(bufptr)\
            // Address = buffer address + buffer length + sizeof(buffer length)\
            let dest := add(add(bufptr, buflen), 32)\
            mstore8(dest, data)\
            // Update buffer length\
            mstore(bufptr, add(buflen, 1))\
        \}\
    \}\
\
    /**\
     * @dev Appends a byte to the end of the buffer. Reverts if doing so would\
     * exceed the capacity of the buffer.\
     * @param buf The buffer to append to.\
     * @param data The data to append.\
     * @return The original buffer.\
     */\
    function appendInt(buffer memory buf, uint data, uint len) internal pure returns(buffer memory) \{\
        if(len + buf.buf.length > buf.capacity) \{\
            resize(buf, max(buf.capacity, len) * 2);\
        \}\
\
        uint mask = 256 ** len - 1;\
        assembly \{\
            // Memory address of the buffer data\
            let bufptr := mload(buf)\
            // Length of existing buffer data\
            let buflen := mload(bufptr)\
            // Address = buffer address + buffer length + sizeof(buffer length) + len\
            let dest := add(add(bufptr, buflen), len)\
            mstore(dest, or(and(mload(dest), not(mask)), data))\
            // Update buffer length\
            mstore(bufptr, add(buflen, len))\
        \}\
        return buf;\
    \}\
\}\
\
library CBOR \{\
    using Buffer for Buffer.buffer;\
\
    uint8 private constant MAJOR_TYPE_INT = 0;\
    uint8 private constant MAJOR_TYPE_NEGATIVE_INT = 1;\
    uint8 private constant MAJOR_TYPE_BYTES = 2;\
    uint8 private constant MAJOR_TYPE_STRING = 3;\
    uint8 private constant MAJOR_TYPE_ARRAY = 4;\
    uint8 private constant MAJOR_TYPE_MAP = 5;\
    uint8 private constant MAJOR_TYPE_CONTENT_FREE = 7;\
\
    function encodeType(Buffer.buffer memory buf, uint8 major, uint value) private pure \{\
        if(value <= 23) \{\
            buf.append(uint8((major << 5) | value));\
        \} else if(value <= 0xFF) \{\
            buf.append(uint8((major << 5) | 24));\
            buf.appendInt(value, 1);\
        \} else if(value <= 0xFFFF) \{\
            buf.append(uint8((major << 5) | 25));\
            buf.appendInt(value, 2);\
        \} else if(value <= 0xFFFFFFFF) \{\
            buf.append(uint8((major << 5) | 26));\
            buf.appendInt(value, 4);\
        \} else if(value <= 0xFFFFFFFFFFFFFFFF) \{\
            buf.append(uint8((major << 5) | 27));\
            buf.appendInt(value, 8);\
        \}\
    \}\
\
    function encodeIndefiniteLengthType(Buffer.buffer memory buf, uint8 major) private pure \{\
        buf.append(uint8((major << 5) | 31));\
    \}\
\
    function encodeUInt(Buffer.buffer memory buf, uint value) internal pure \{\
        encodeType(buf, MAJOR_TYPE_INT, value);\
    \}\
\
    function encodeInt(Buffer.buffer memory buf, int value) internal pure \{\
        if(value >= 0) \{\
            encodeType(buf, MAJOR_TYPE_INT, uint(value));\
        \} else \{\
            encodeType(buf, MAJOR_TYPE_NEGATIVE_INT, uint(-1 - value));\
        \}\
    \}\
\
    function encodeBytes(Buffer.buffer memory buf, bytes value) internal pure \{\
        encodeType(buf, MAJOR_TYPE_BYTES, value.length);\
        buf.append(value);\
    \}\
\
    function encodeString(Buffer.buffer memory buf, string value) internal pure \{\
        encodeType(buf, MAJOR_TYPE_STRING, bytes(value).length);\
        buf.append(bytes(value));\
    \}\
\
    function startArray(Buffer.buffer memory buf) internal pure \{\
        encodeIndefiniteLengthType(buf, MAJOR_TYPE_ARRAY);\
    \}\
\
    function startMap(Buffer.buffer memory buf) internal pure \{\
        encodeIndefiniteLengthType(buf, MAJOR_TYPE_MAP);\
    \}\
\
    function endSequence(Buffer.buffer memory buf) internal pure \{\
        encodeIndefiniteLengthType(buf, MAJOR_TYPE_CONTENT_FREE);\
    \}\
\}\
\
/*\
End solidity-cborutils\
 */\
\
contract usingOraclize \{\
    uint constant day = 60*60*24;\
    uint constant week = 60*60*24*7;\
    uint constant month = 60*60*24*30;\
    byte constant proofType_NONE = 0x00;\
    byte constant proofType_TLSNotary = 0x10;\
    byte constant proofType_Android = 0x20;\
    byte constant proofType_Ledger = 0x30;\
    byte constant proofType_Native = 0xF0;\
    byte constant proofStorage_IPFS = 0x01;\
    uint8 constant networkID_auto = 0;\
    uint8 constant networkID_mainnet = 1;\
    uint8 constant networkID_testnet = 2;\
    uint8 constant networkID_morden = 2;\
    uint8 constant networkID_consensys = 161;\
\
    OraclizeAddrResolverI OAR;\
\
    OraclizeI oraclize;\
    modifier oraclizeAPI \{\
        if((address(OAR)==0)||(getCodeSize(address(OAR))==0))\
            oraclize_setNetwork(networkID_auto);\
\
        if(address(oraclize) != OAR.getAddress())\
            oraclize = OraclizeI(OAR.getAddress());\
\
        _;\
    \}\
    modifier coupon(string code)\{\
        oraclize = OraclizeI(OAR.getAddress());\
        _;\
    \}\
\
    function oraclize_setNetwork(uint8 networkID) internal returns(bool)\{\
      return oraclize_setNetwork();\
      networkID; // silence the warning and remain backwards compatible\
    \}\
    function oraclize_setNetwork() internal returns(bool)\{\
        if (getCodeSize(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed)>0)\{ //mainnet\
            OAR = OraclizeAddrResolverI(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed);\
            oraclize_setNetworkName("eth_mainnet");\
            return true;\
        \}\
        if (getCodeSize(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1)>0)\{ //ropsten testnet\
            OAR = OraclizeAddrResolverI(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1);\
            oraclize_setNetworkName("eth_ropsten3");\
            return true;\
        \}\
        if (getCodeSize(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e)>0)\{ //kovan testnet\
            OAR = OraclizeAddrResolverI(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e);\
            oraclize_setNetworkName("eth_kovan");\
            return true;\
        \}\
        if (getCodeSize(0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48)>0)\{ //rinkeby testnet\
            OAR = OraclizeAddrResolverI(0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48);\
            oraclize_setNetworkName("eth_rinkeby");\
            return true;\
        \}\
        if (getCodeSize(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475)>0)\{ //ethereum-bridge\
            OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);\
            return true;\
        \}\
        if (getCodeSize(0x20e12A1F859B3FeaE5Fb2A0A32C18F5a65555bBF)>0)\{ //ether.camp ide\
            OAR = OraclizeAddrResolverI(0x20e12A1F859B3FeaE5Fb2A0A32C18F5a65555bBF);\
            return true;\
        \}\
        if (getCodeSize(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA)>0)\{ //browser-solidity\
            OAR = OraclizeAddrResolverI(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA);\
            return true;\
        \}\
        return false;\
    \}\
\
    function __callback(bytes32 myid, string result) public \{\
        __callback(myid, result, new bytes(0));\
    \}\
    function __callback(bytes32 myid, string result, bytes proof) public \{\
      return;\
      myid; result; proof; // Silence compiler warnings\
    \}\
\
    function oraclize_getPrice(string datasource) oraclizeAPI internal returns (uint)\{\
        return oraclize.getPrice(datasource);\
    \}\
\
    function oraclize_getPrice(string datasource, uint gaslimit) oraclizeAPI internal returns (uint)\{\
        return oraclize.getPrice(datasource, gaslimit);\
    \}\
\
    function oraclize_query(string datasource, string arg) oraclizeAPI internal returns (bytes32 id)\{\
        uint price = oraclize.getPrice(datasource);\
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price\
        return oraclize.query.value(price)(0, datasource, arg);\
    \}\
    function oraclize_query(uint timestamp, string datasource, string arg) oraclizeAPI internal returns (bytes32 id)\{\
        uint price = oraclize.getPrice(datasource);\
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price\
        return oraclize.query.value(price)(timestamp, datasource, arg);\
    \}\
    function oraclize_query(uint timestamp, string datasource, string arg, uint gaslimit) oraclizeAPI internal returns (bytes32 id)\{\
        uint price = oraclize.getPrice(datasource, gaslimit);\
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price\
        return oraclize.query_withGasLimit.value(price)(timestamp, datasource, arg, gaslimit);\
    \}\
    function oraclize_query(string datasource, string arg, uint gaslimit) oraclizeAPI internal returns (bytes32 id)\{\
        uint price = oraclize.getPrice(datasource, gaslimit);\
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price\
        return oraclize.query_withGasLimit.value(price)(0, datasource, arg, gaslimit);\
    \}\
    function oraclize_query(string datasource, string arg1, string arg2) oraclizeAPI internal returns (bytes32 id)\{\
        uint price = oraclize.getPrice(datasource);\
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price\
        return oraclize.query2.value(price)(0, datasource, arg1, arg2);\
    \}\
    function oraclize_query(uint timestamp, string datasource, string arg1, string arg2) oraclizeAPI internal returns (bytes32 id)\{\
        uint price = oraclize.getPrice(datasource);\
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price\
        return oraclize.query2.value(price)(timestamp, datasource, arg1, arg2);\
    \}\
    function oraclize_query(uint timestamp, string datasource, string arg1, string arg2, uint gaslimit) oraclizeAPI internal returns (bytes32 id)\{\
        uint price = oraclize.getPrice(datasource, gaslimit);\
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price\
        return oraclize.query2_withGasLimit.value(price)(timestamp, datasource, arg1, arg2, gaslimit);\
    \}\
    function oraclize_query(string datasource, string arg1, string arg2, uint gaslimit) oraclizeAPI internal returns (bytes32 id)\{\
        uint price = oraclize.getPrice(datasource, gaslimit);\
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price\
        return oraclize.query2_withGasLimit.value(price)(0, datasource, arg1, arg2, gaslimit);\
    \}\
    function oraclize_query(string datasource, string[] argN) oraclizeAPI internal returns (bytes32 id)\{\
        uint price = oraclize.getPrice(datasource);\
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price\
        bytes memory args = stra2cbor(argN);\
        return oraclize.queryN.value(price)(0, datasource, args);\
    \}\
    function oraclize_query(uint timestamp, string datasource, string[] argN) oraclizeAPI internal returns (bytes32 id)\{\
        uint price = oraclize.getPrice(datasource);\
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price\
        bytes memory args = stra2cbor(argN);\
        return oraclize.queryN.value(price)(timestamp, datasource, args);\
    \}\
    function oraclize_query(uint timestamp, string datasource, string[] argN, uint gaslimit) oraclizeAPI internal returns (bytes32 id)\{\
        uint price = oraclize.getPrice(datasource, gaslimit);\
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price\
        bytes memory args = stra2cbor(argN);\
        return oraclize.queryN_withGasLimit.value(price)(timestamp, datasource, args, gaslimit);\
    \}\
    function oraclize_query(string datasource, string[] argN, uint gaslimit) oraclizeAPI internal returns (bytes32 id)\{\
        uint price = oraclize.getPrice(datasource, gaslimit);\
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price\
        bytes memory args = stra2cbor(argN);\
        return oraclize.queryN_withGasLimit.value(price)(0, datasource, args, gaslimit);\
    \}\
    function oraclize_query(string datasource, string[1] args) oraclizeAPI internal returns (bytes32 id) \{\
        string[] memory dynargs = new string[](1);\
        dynargs[0] = args[0];\
        return oraclize_query(datasource, dynargs);\
    \}\
    function oraclize_query(uint timestamp, string datasource, string[1] args) oraclizeAPI internal returns (bytes32 id) \{\
        string[] memory dynargs = new string[](1);\
        dynargs[0] = args[0];\
        return oraclize_query(timestamp, datasource, dynargs);\
    \}\
    function oraclize_query(uint timestamp, string datasource, string[1] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) \{\
        string[] memory dynargs = new string[](1);\
        dynargs[0] = args[0];\
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);\
    \}\
    function oraclize_query(string datasource, string[1] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) \{\
        string[] memory dynargs = new string[](1);\
        dynargs[0] = args[0];\
        return oraclize_query(datasource, dynargs, gaslimit);\
    \}\
\
    function oraclize_query(string datasource, string[2] args) oraclizeAPI internal returns (bytes32 id) \{\
        string[] memory dynargs = new string[](2);\
        dynargs[0] = args[0];\
        dynargs[1] = args[1];\
        return oraclize_query(datasource, dynargs);\
    \}\
    function oraclize_query(uint timestamp, string datasource, string[2] args) oraclizeAPI internal returns (bytes32 id) \{\
        string[] memory dynargs = new string[](2);\
        dynargs[0] = args[0];\
        dynargs[1] = args[1];\
        return oraclize_query(timestamp, datasource, dynargs);\
    \}\
    function oraclize_query(uint timestamp, string datasource, string[2] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) \{\
        string[] memory dynargs = new string[](2);\
        dynargs[0] = args[0];\
        dynargs[1] = args[1];\
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);\
    \}\
    function oraclize_query(string datasource, string[2] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) \{\
        string[] memory dynargs = new string[](2);\
        dynargs[0] = args[0];\
        dynargs[1] = args[1];\
        return oraclize_query(datasource, dynargs, gaslimit);\
    \}\
    function oraclize_query(string datasource, string[3] args) oraclizeAPI internal returns (bytes32 id) \{\
        string[] memory dynargs = new string[](3);\
        dynargs[0] = args[0];\
        dynargs[1] = args[1];\
        dynargs[2] = args[2];\
        return oraclize_query(datasource, dynargs);\
    \}\
    function oraclize_query(uint timestamp, string datasource, string[3] args) oraclizeAPI internal returns (bytes32 id) \{\
        string[] memory dynargs = new string[](3);\
        dynargs[0] = args[0];\
        dynargs[1] = args[1];\
        dynargs[2] = args[2];\
        return oraclize_query(timestamp, datasource, dynargs);\
    \}\
    function oraclize_query(uint timestamp, string datasource, string[3] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) \{\
        string[] memory dynargs = new string[](3);\
        dynargs[0] = args[0];\
        dynargs[1] = args[1];\
        dynargs[2] = args[2];\
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);\
    \}\
    function oraclize_query(string datasource, string[3] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) \{\
        string[] memory dynargs = new string[](3);\
        dynargs[0] = args[0];\
        dynargs[1] = args[1];\
        dynargs[2] = args[2];\
        return oraclize_query(datasource, dynargs, gaslimit);\
    \}\
\
    function oraclize_query(string datasource, string[4] args) oraclizeAPI internal returns (bytes32 id) \{\
        string[] memory dynargs = new string[](4);\
        dynargs[0] = args[0];\
        dynargs[1] = args[1];\
        dynargs[2] = args[2];\
        dynargs[3] = args[3];\
        return oraclize_query(datasource, dynargs);\
    \}\
    function oraclize_query(uint timestamp, string datasource, string[4] args) oraclizeAPI internal returns (bytes32 id) \{\
        string[] memory dynargs = new string[](4);\
        dynargs[0] = args[0];\
        dynargs[1] = args[1];\
        dynargs[2] = args[2];\
        dynargs[3] = args[3];\
        return oraclize_query(timestamp, datasource, dynargs);\
    \}\
    function oraclize_query(uint timestamp, string datasource, string[4] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) \{\
        string[] memory dynargs = new string[](4);\
        dynargs[0] = args[0];\
        dynargs[1] = args[1];\
        dynargs[2] = args[2];\
        dynargs[3] = args[3];\
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);\
    \}\
    function oraclize_query(string datasource, string[4] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) \{\
        string[] memory dynargs = new string[](4);\
        dynargs[0] = args[0];\
        dynargs[1] = args[1];\
        dynargs[2] = args[2];\
        dynargs[3] = args[3];\
        return oraclize_query(datasource, dynargs, gaslimit);\
    \}\
    function oraclize_query(string datasource, string[5] args) oraclizeAPI internal returns (bytes32 id) \{\
        string[] memory dynargs = new string[](5);\
        dynargs[0] = args[0];\
        dynargs[1] = args[1];\
        dynargs[2] = args[2];\
        dynargs[3] = args[3];\
        dynargs[4] = args[4];\
        return oraclize_query(datasource, dynargs);\
    \}\
    function oraclize_query(uint timestamp, string datasource, string[5] args) oraclizeAPI internal returns (bytes32 id) \{\
        string[] memory dynargs = new string[](5);\
        dynargs[0] = args[0];\
        dynargs[1] = args[1];\
        dynargs[2] = args[2];\
        dynargs[3] = args[3];\
        dynargs[4] = args[4];\
        return oraclize_query(timestamp, datasource, dynargs);\
    \}\
    function oraclize_query(uint timestamp, string datasource, string[5] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) \{\
        string[] memory dynargs = new string[](5);\
        dynargs[0] = args[0];\
        dynargs[1] = args[1];\
        dynargs[2] = args[2];\
        dynargs[3] = args[3];\
        dynargs[4] = args[4];\
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);\
    \}\
    function oraclize_query(string datasource, string[5] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) \{\
        string[] memory dynargs = new string[](5);\
        dynargs[0] = args[0];\
        dynargs[1] = args[1];\
        dynargs[2] = args[2];\
        dynargs[3] = args[3];\
        dynargs[4] = args[4];\
        return oraclize_query(datasource, dynargs, gaslimit);\
    \}\
    function oraclize_query(string datasource, bytes[] argN) oraclizeAPI internal returns (bytes32 id)\{\
        uint price = oraclize.getPrice(datasource);\
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price\
        bytes memory args = ba2cbor(argN);\
        return oraclize.queryN.value(price)(0, datasource, args);\
    \}\
    function oraclize_query(uint timestamp, string datasource, bytes[] argN) oraclizeAPI internal returns (bytes32 id)\{\
        uint price = oraclize.getPrice(datasource);\
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price\
        bytes memory args = ba2cbor(argN);\
        return oraclize.queryN.value(price)(timestamp, datasource, args);\
    \}\
    function oraclize_query(uint timestamp, string datasource, bytes[] argN, uint gaslimit) oraclizeAPI internal returns (bytes32 id)\{\
        uint price = oraclize.getPrice(datasource, gaslimit);\
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price\
        bytes memory args = ba2cbor(argN);\
        return oraclize.queryN_withGasLimit.value(price)(timestamp, datasource, args, gaslimit);\
    \}\
    function oraclize_query(string datasource, bytes[] argN, uint gaslimit) oraclizeAPI internal returns (bytes32 id)\{\
        uint price = oraclize.getPrice(datasource, gaslimit);\
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price\
        bytes memory args = ba2cbor(argN);\
        return oraclize.queryN_withGasLimit.value(price)(0, datasource, args, gaslimit);\
    \}\
    function oraclize_query(string datasource, bytes[1] args) oraclizeAPI internal returns (bytes32 id) \{\
        bytes[] memory dynargs = new bytes[](1);\
        dynargs[0] = args[0];\
        return oraclize_query(datasource, dynargs);\
    \}\
    function oraclize_query(uint timestamp, string datasource, bytes[1] args) oraclizeAPI internal returns (bytes32 id) \{\
        bytes[] memory dynargs = new bytes[](1);\
        dynargs[0] = args[0];\
        return oraclize_query(timestamp, datasource, dynargs);\
    \}\
    function oraclize_query(uint timestamp, string datasource, bytes[1] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) \{\
        bytes[] memory dynargs = new bytes[](1);\
        dynargs[0] = args[0];\
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);\
    \}\
    function oraclize_query(string datasource, bytes[1] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) \{\
        bytes[] memory dynargs = new bytes[](1);\
        dynargs[0] = args[0];\
        return oraclize_query(datasource, dynargs, gaslimit);\
    \}\
\
    function oraclize_query(string datasource, bytes[2] args) oraclizeAPI internal returns (bytes32 id) \{\
        bytes[] memory dynargs = new bytes[](2);\
        dynargs[0] = args[0];\
        dynargs[1] = args[1];\
        return oraclize_query(datasource, dynargs);\
    \}\
    function oraclize_query(uint timestamp, string datasource, bytes[2] args) oraclizeAPI internal returns (bytes32 id) \{\
        bytes[] memory dynargs = new bytes[](2);\
        dynargs[0] = args[0];\
        dynargs[1] = args[1];\
        return oraclize_query(timestamp, datasource, dynargs);\
    \}\
    function oraclize_query(uint timestamp, string datasource, bytes[2] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) \{\
        bytes[] memory dynargs = new bytes[](2);\
        dynargs[0] = args[0];\
        dynargs[1] = args[1];\
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);\
    \}\
    function oraclize_query(string datasource, bytes[2] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) \{\
        bytes[] memory dynargs = new bytes[](2);\
        dynargs[0] = args[0];\
        dynargs[1] = args[1];\
        return oraclize_query(datasource, dynargs, gaslimit);\
    \}\
    function oraclize_query(string datasource, bytes[3] args) oraclizeAPI internal returns (bytes32 id) \{\
        bytes[] memory dynargs = new bytes[](3);\
        dynargs[0] = args[0];\
        dynargs[1] = args[1];\
        dynargs[2] = args[2];\
        return oraclize_query(datasource, dynargs);\
    \}\
    function oraclize_query(uint timestamp, string datasource, bytes[3] args) oraclizeAPI internal returns (bytes32 id) \{\
        bytes[] memory dynargs = new bytes[](3);\
        dynargs[0] = args[0];\
        dynargs[1] = args[1];\
        dynargs[2] = args[2];\
        return oraclize_query(timestamp, datasource, dynargs);\
    \}\
    function oraclize_query(uint timestamp, string datasource, bytes[3] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) \{\
        bytes[] memory dynargs = new bytes[](3);\
        dynargs[0] = args[0];\
        dynargs[1] = args[1];\
        dynargs[2] = args[2];\
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);\
    \}\
    function oraclize_query(string datasource, bytes[3] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) \{\
        bytes[] memory dynargs = new bytes[](3);\
        dynargs[0] = args[0];\
        dynargs[1] = args[1];\
        dynargs[2] = args[2];\
        return oraclize_query(datasource, dynargs, gaslimit);\
    \}\
\
    function oraclize_query(string datasource, bytes[4] args) oraclizeAPI internal returns (bytes32 id) \{\
        bytes[] memory dynargs = new bytes[](4);\
        dynargs[0] = args[0];\
        dynargs[1] = args[1];\
        dynargs[2] = args[2];\
        dynargs[3] = args[3];\
        return oraclize_query(datasource, dynargs);\
    \}\
    function oraclize_query(uint timestamp, string datasource, bytes[4] args) oraclizeAPI internal returns (bytes32 id) \{\
        bytes[] memory dynargs = new bytes[](4);\
        dynargs[0] = args[0];\
        dynargs[1] = args[1];\
        dynargs[2] = args[2];\
        dynargs[3] = args[3];\
        return oraclize_query(timestamp, datasource, dynargs);\
    \}\
    function oraclize_query(uint timestamp, string datasource, bytes[4] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) \{\
        bytes[] memory dynargs = new bytes[](4);\
        dynargs[0] = args[0];\
        dynargs[1] = args[1];\
        dynargs[2] = args[2];\
        dynargs[3] = args[3];\
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);\
    \}\
    function oraclize_query(string datasource, bytes[4] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) \{\
        bytes[] memory dynargs = new bytes[](4);\
        dynargs[0] = args[0];\
        dynargs[1] = args[1];\
        dynargs[2] = args[2];\
        dynargs[3] = args[3];\
        return oraclize_query(datasource, dynargs, gaslimit);\
    \}\
    function oraclize_query(string datasource, bytes[5] args) oraclizeAPI internal returns (bytes32 id) \{\
        bytes[] memory dynargs = new bytes[](5);\
        dynargs[0] = args[0];\
        dynargs[1] = args[1];\
        dynargs[2] = args[2];\
        dynargs[3] = args[3];\
        dynargs[4] = args[4];\
        return oraclize_query(datasource, dynargs);\
    \}\
    function oraclize_query(uint timestamp, string datasource, bytes[5] args) oraclizeAPI internal returns (bytes32 id) \{\
        bytes[] memory dynargs = new bytes[](5);\
        dynargs[0] = args[0];\
        dynargs[1] = args[1];\
        dynargs[2] = args[2];\
        dynargs[3] = args[3];\
        dynargs[4] = args[4];\
        return oraclize_query(timestamp, datasource, dynargs);\
    \}\
    function oraclize_query(uint timestamp, string datasource, bytes[5] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) \{\
        bytes[] memory dynargs = new bytes[](5);\
        dynargs[0] = args[0];\
        dynargs[1] = args[1];\
        dynargs[2] = args[2];\
        dynargs[3] = args[3];\
        dynargs[4] = args[4];\
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);\
    \}\
    function oraclize_query(string datasource, bytes[5] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) \{\
        bytes[] memory dynargs = new bytes[](5);\
        dynargs[0] = args[0];\
        dynargs[1] = args[1];\
        dynargs[2] = args[2];\
        dynargs[3] = args[3];\
        dynargs[4] = args[4];\
        return oraclize_query(datasource, dynargs, gaslimit);\
    \}\
\
    function oraclize_cbAddress() oraclizeAPI internal returns (address)\{\
        return oraclize.cbAddress();\
    \}\
    function oraclize_setProof(byte proofP) oraclizeAPI internal \{\
        return oraclize.setProofType(proofP);\
    \}\
    function oraclize_setCustomGasPrice(uint gasPrice) oraclizeAPI internal \{\
        return oraclize.setCustomGasPrice(gasPrice);\
    \}\
\
    function oraclize_randomDS_getSessionPubKeyHash() oraclizeAPI internal returns (bytes32)\{\
        return oraclize.randomDS_getSessionPubKeyHash();\
    \}\
\
    function getCodeSize(address _addr) constant internal returns(uint _size) \{\
        assembly \{\
            _size := extcodesize(_addr)\
        \}\
    \}\
\
    function parseAddr(string _a) internal pure returns (address)\{\
        bytes memory tmp = bytes(_a);\
        uint160 iaddr = 0;\
        uint160 b1;\
        uint160 b2;\
        for (uint i=2; i<2+2*20; i+=2)\{\
            iaddr *= 256;\
            b1 = uint160(tmp[i]);\
            b2 = uint160(tmp[i+1]);\
            if ((b1 >= 97)&&(b1 <= 102)) b1 -= 87;\
            else if ((b1 >= 65)&&(b1 <= 70)) b1 -= 55;\
            else if ((b1 >= 48)&&(b1 <= 57)) b1 -= 48;\
            if ((b2 >= 97)&&(b2 <= 102)) b2 -= 87;\
            else if ((b2 >= 65)&&(b2 <= 70)) b2 -= 55;\
            else if ((b2 >= 48)&&(b2 <= 57)) b2 -= 48;\
            iaddr += (b1*16+b2);\
        \}\
        return address(iaddr);\
    \}\
\
    function strCompare(string _a, string _b) internal pure returns (int) \{\
        bytes memory a = bytes(_a);\
        bytes memory b = bytes(_b);\
        uint minLength = a.length;\
        if (b.length < minLength) minLength = b.length;\
        for (uint i = 0; i < minLength; i ++)\
            if (a[i] < b[i])\
                return -1;\
            else if (a[i] > b[i])\
                return 1;\
        if (a.length < b.length)\
            return -1;\
        else if (a.length > b.length)\
            return 1;\
        else\
            return 0;\
    \}\
\
    function indexOf(string _haystack, string _needle) internal pure returns (int) \{\
        bytes memory h = bytes(_haystack);\
        bytes memory n = bytes(_needle);\
        if(h.length < 1 || n.length < 1 || (n.length > h.length))\
            return -1;\
        else if(h.length > (2**128 -1))\
            return -1;\
        else\
        \{\
            uint subindex = 0;\
            for (uint i = 0; i < h.length; i ++)\
            \{\
                if (h[i] == n[0])\
                \{\
                    subindex = 1;\
                    while(subindex < n.length && (i + subindex) < h.length && h[i + subindex] == n[subindex])\
                    \{\
                        subindex++;\
                    \}\
                    if(subindex == n.length)\
                        return int(i);\
                \}\
            \}\
            return -1;\
        \}\
    \}\
\
    function strConcat(string _a, string _b, string _c, string _d, string _e) internal pure returns (string) \{\
        bytes memory _ba = bytes(_a);\
        bytes memory _bb = bytes(_b);\
        bytes memory _bc = bytes(_c);\
        bytes memory _bd = bytes(_d);\
        bytes memory _be = bytes(_e);\
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);\
        bytes memory babcde = bytes(abcde);\
        uint k = 0;\
        for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];\
        for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];\
        for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];\
        for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];\
        for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];\
        return string(babcde);\
    \}\
\
    function strConcat(string _a, string _b, string _c, string _d) internal pure returns (string) \{\
        return strConcat(_a, _b, _c, _d, "");\
    \}\
\
    function strConcat(string _a, string _b, string _c) internal pure returns (string) \{\
        return strConcat(_a, _b, _c, "", "");\
    \}\
\
    function strConcat(string _a, string _b) internal pure returns (string) \{\
        return strConcat(_a, _b, "", "", "");\
    \}\
\
    // parseInt\
    function parseInt(string _a) internal pure returns (uint) \{\
        return parseInt(_a, 0);\
    \}\
\
    // parseInt(parseFloat*10^_b)\
    function parseInt(string _a, uint _b) internal pure returns (uint) \{\
        bytes memory bresult = bytes(_a);\
        uint mint = 0;\
        bool decimals = false;\
        for (uint i=0; i<bresult.length; i++)\{\
            if ((bresult[i] >= 48)&&(bresult[i] <= 57))\{\
                if (decimals)\{\
                   if (_b == 0) break;\
                    else _b--;\
                \}\
                mint *= 10;\
                mint += uint(bresult[i]) - 48;\
            \} else if (bresult[i] == 46) decimals = true;\
        \}\
        if (_b > 0) mint *= 10**_b;\
        return mint;\
    \}\
\
    function uint2str(uint i) internal pure returns (string)\{\
        if (i == 0) return "0";\
        uint j = i;\
        uint len;\
        while (j != 0)\{\
            len++;\
            j /= 10;\
        \}\
        bytes memory bstr = new bytes(len);\
        uint k = len - 1;\
        while (i != 0)\{\
            bstr[k--] = byte(48 + i % 10);\
            i /= 10;\
        \}\
        return string(bstr);\
    \}\
\
    using CBOR for Buffer.buffer;\
    function stra2cbor(string[] arr) internal pure returns (bytes) \{\
        Buffer.buffer memory buf;\
        Buffer.init(buf, 1024);\
        buf.startArray();\
        for (uint i = 0; i < arr.length; i++) \{\
            buf.encodeString(arr[i]);\
        \}\
        buf.endSequence();\
        return buf.buf;\
    \}\
\
    function ba2cbor(bytes[] arr) internal pure returns (bytes) \{\
        Buffer.buffer memory buf;\
        Buffer.init(buf, 1024);\
        buf.startArray();\
        for (uint i = 0; i < arr.length; i++) \{\
            buf.encodeBytes(arr[i]);\
        \}\
        buf.endSequence();\
        return buf.buf;\
    \}\
\
    string oraclize_network_name;\
    function oraclize_setNetworkName(string _network_name) internal \{\
        oraclize_network_name = _network_name;\
    \}\
\
    function oraclize_getNetworkName() internal view returns (string) \{\
        return oraclize_network_name;\
    \}\
\
    function oraclize_newRandomDSQuery(uint _delay, uint _nbytes, uint _customGasLimit) internal returns (bytes32)\{\
        require((_nbytes > 0) && (_nbytes <= 32));\
        // Convert from seconds to ledger timer ticks\
        _delay *= 10;\
        bytes memory nbytes = new bytes(1);\
        nbytes[0] = byte(_nbytes);\
        bytes memory unonce = new bytes(32);\
        bytes memory sessionKeyHash = new bytes(32);\
        bytes32 sessionKeyHash_bytes32 = oraclize_randomDS_getSessionPubKeyHash();\
        assembly \{\
            mstore(unonce, 0x20)\
            mstore(add(unonce, 0x20), xor(blockhash(sub(number, 1)), xor(coinbase, timestamp)))\
            mstore(sessionKeyHash, 0x20)\
            mstore(add(sessionKeyHash, 0x20), sessionKeyHash_bytes32)\
        \}\
        bytes memory delay = new bytes(32);\
        assembly \{\
            mstore(add(delay, 0x20), _delay)\
        \}\
\
        bytes memory delay_bytes8 = new bytes(8);\
        copyBytes(delay, 24, 8, delay_bytes8, 0);\
\
        bytes[4] memory args = [unonce, nbytes, sessionKeyHash, delay];\
        bytes32 queryId = oraclize_query("random", args, _customGasLimit);\
\
        bytes memory delay_bytes8_left = new bytes(8);\
\
        assembly \{\
            let x := mload(add(delay_bytes8, 0x20))\
            mstore8(add(delay_bytes8_left, 0x27), div(x, 0x100000000000000000000000000000000000000000000000000000000000000))\
            mstore8(add(delay_bytes8_left, 0x26), div(x, 0x1000000000000000000000000000000000000000000000000000000000000))\
            mstore8(add(delay_bytes8_left, 0x25), div(x, 0x10000000000000000000000000000000000000000000000000000000000))\
            mstore8(add(delay_bytes8_left, 0x24), div(x, 0x100000000000000000000000000000000000000000000000000000000))\
            mstore8(add(delay_bytes8_left, 0x23), div(x, 0x1000000000000000000000000000000000000000000000000000000))\
            mstore8(add(delay_bytes8_left, 0x22), div(x, 0x10000000000000000000000000000000000000000000000000000))\
            mstore8(add(delay_bytes8_left, 0x21), div(x, 0x100000000000000000000000000000000000000000000000000))\
            mstore8(add(delay_bytes8_left, 0x20), div(x, 0x1000000000000000000000000000000000000000000000000))\
\
        \}\
\
        oraclize_randomDS_setCommitment(queryId, keccak256(delay_bytes8_left, args[1], sha256(args[0]), args[2]));\
        return queryId;\
    \}\
\
    function oraclize_randomDS_setCommitment(bytes32 queryId, bytes32 commitment) internal \{\
        oraclize_randomDS_args[queryId] = commitment;\
    \}\
\
    mapping(bytes32=>bytes32) oraclize_randomDS_args;\
    mapping(bytes32=>bool) oraclize_randomDS_sessionKeysHashVerified;\
\
    function verifySig(bytes32 tosignh, bytes dersig, bytes pubkey) internal returns (bool)\{\
        bool sigok;\
        address signer;\
\
        bytes32 sigr;\
        bytes32 sigs;\
\
        bytes memory sigr_ = new bytes(32);\
        uint offset = 4+(uint(dersig[3]) - 0x20);\
        sigr_ = copyBytes(dersig, offset, 32, sigr_, 0);\
        bytes memory sigs_ = new bytes(32);\
        offset += 32 + 2;\
        sigs_ = copyBytes(dersig, offset+(uint(dersig[offset-1]) - 0x20), 32, sigs_, 0);\
\
        assembly \{\
            sigr := mload(add(sigr_, 32))\
            sigs := mload(add(sigs_, 32))\
        \}\
\
\
        (sigok, signer) = safer_ecrecover(tosignh, 27, sigr, sigs);\
        if (address(keccak256(pubkey)) == signer) return true;\
        else \{\
            (sigok, signer) = safer_ecrecover(tosignh, 28, sigr, sigs);\
            return (address(keccak256(pubkey)) == signer);\
        \}\
    \}\
\
    function oraclize_randomDS_proofVerify__sessionKeyValidity(bytes proof, uint sig2offset) internal returns (bool) \{\
        bool sigok;\
\
        // Step 6: verify the attestation signature, APPKEY1 must sign the sessionKey from the correct ledger app (CODEHASH)\
        bytes memory sig2 = new bytes(uint(proof[sig2offset+1])+2);\
        copyBytes(proof, sig2offset, sig2.length, sig2, 0);\
\
        bytes memory appkey1_pubkey = new bytes(64);\
        copyBytes(proof, 3+1, 64, appkey1_pubkey, 0);\
\
        bytes memory tosign2 = new bytes(1+65+32);\
        tosign2[0] = byte(1); //role\
        copyBytes(proof, sig2offset-65, 65, tosign2, 1);\
        bytes memory CODEHASH = hex"fd94fa71bc0ba10d39d464d0d8f465efeef0a2764e3887fcc9df41ded20f505c";\
        copyBytes(CODEHASH, 0, 32, tosign2, 1+65);\
        sigok = verifySig(sha256(tosign2), sig2, appkey1_pubkey);\
\
        if (sigok == false) return false;\
\
\
        // Step 7: verify the APPKEY1 provenance (must be signed by Ledger)\
        bytes memory LEDGERKEY = hex"7fb956469c5c9b89840d55b43537e66a98dd4811ea0a27224272c2e5622911e8537a2f8e86a46baec82864e98dd01e9ccc2f8bc5dfc9cbe5a91a290498dd96e4";\
\
        bytes memory tosign3 = new bytes(1+65);\
        tosign3[0] = 0xFE;\
        copyBytes(proof, 3, 65, tosign3, 1);\
\
        bytes memory sig3 = new bytes(uint(proof[3+65+1])+2);\
        copyBytes(proof, 3+65, sig3.length, sig3, 0);\
\
        sigok = verifySig(sha256(tosign3), sig3, LEDGERKEY);\
\
        return sigok;\
    \}\
\
    modifier oraclize_randomDS_proofVerify(bytes32 _queryId, string _result, bytes _proof) \{\
        // Step 1: the prefix has to match 'LP\\x01' (Ledger Proof version 1)\
        require((_proof[0] == "L") && (_proof[1] == "P") && (_proof[2] == 1));\
\
        bool proofVerified = oraclize_randomDS_proofVerify__main(_proof, _queryId, bytes(_result), oraclize_getNetworkName());\
        require(proofVerified);\
\
        _;\
    \}\
\
    function oraclize_randomDS_proofVerify__returnCode(bytes32 _queryId, string _result, bytes _proof) internal returns (uint8)\{\
        // Step 1: the prefix has to match 'LP\\x01' (Ledger Proof version 1)\
        if ((_proof[0] != "L")||(_proof[1] != "P")||(_proof[2] != 1)) return 1;\
\
        bool proofVerified = oraclize_randomDS_proofVerify__main(_proof, _queryId, bytes(_result), oraclize_getNetworkName());\
        if (proofVerified == false) return 2;\
\
        return 0;\
    \}\
\
    function matchBytes32Prefix(bytes32 content, bytes prefix, uint n_random_bytes) internal pure returns (bool)\{\
        bool match_ = true;\
\
        require(prefix.length == n_random_bytes);\
\
        for (uint256 i=0; i< n_random_bytes; i++) \{\
            if (content[i] != prefix[i]) match_ = false;\
        \}\
\
        return match_;\
    \}\
\
    function oraclize_randomDS_proofVerify__main(bytes proof, bytes32 queryId, bytes result, string context_name) internal returns (bool)\{\
\
        // Step 2: the unique keyhash has to match with the sha256 of (context name + queryId)\
        uint ledgerProofLength = 3+65+(uint(proof[3+65+1])+2)+32;\
        bytes memory keyhash = new bytes(32);\
        copyBytes(proof, ledgerProofLength, 32, keyhash, 0);\
        if (!(keccak256(keyhash) == keccak256(sha256(context_name, queryId)))) return false;\
\
        bytes memory sig1 = new bytes(uint(proof[ledgerProofLength+(32+8+1+32)+1])+2);\
        copyBytes(proof, ledgerProofLength+(32+8+1+32), sig1.length, sig1, 0);\
\
        // Step 3: we assume sig1 is valid (it will be verified during step 5) and we verify if 'result' is the prefix of sha256(sig1)\
        if (!matchBytes32Prefix(sha256(sig1), result, uint(proof[ledgerProofLength+32+8]))) return false;\
\
        // Step 4: commitment match verification, keccak256(delay, nbytes, unonce, sessionKeyHash) == commitment in storage.\
        // This is to verify that the computed args match with the ones specified in the query.\
        bytes memory commitmentSlice1 = new bytes(8+1+32);\
        copyBytes(proof, ledgerProofLength+32, 8+1+32, commitmentSlice1, 0);\
\
        bytes memory sessionPubkey = new bytes(64);\
        uint sig2offset = ledgerProofLength+32+(8+1+32)+sig1.length+65;\
        copyBytes(proof, sig2offset-64, 64, sessionPubkey, 0);\
\
        bytes32 sessionPubkeyHash = sha256(sessionPubkey);\
        if (oraclize_randomDS_args[queryId] == keccak256(commitmentSlice1, sessionPubkeyHash))\{ //unonce, nbytes and sessionKeyHash match\
            delete oraclize_randomDS_args[queryId];\
        \} else return false;\
\
\
        // Step 5: validity verification for sig1 (keyhash and args signed with the sessionKey)\
        bytes memory tosign1 = new bytes(32+8+1+32);\
        copyBytes(proof, ledgerProofLength, 32+8+1+32, tosign1, 0);\
        if (!verifySig(sha256(tosign1), sig1, sessionPubkey)) return false;\
\
        // verify if sessionPubkeyHash was verified already, if not.. let's do it!\
        if (oraclize_randomDS_sessionKeysHashVerified[sessionPubkeyHash] == false)\{\
            oraclize_randomDS_sessionKeysHashVerified[sessionPubkeyHash] = oraclize_randomDS_proofVerify__sessionKeyValidity(proof, sig2offset);\
        \}\
\
        return oraclize_randomDS_sessionKeysHashVerified[sessionPubkeyHash];\
    \}\
\
    // the following function has been written by Alex Beregszaszi (@axic), use it under the terms of the MIT license\
    function copyBytes(bytes from, uint fromOffset, uint length, bytes to, uint toOffset) internal pure returns (bytes) \{\
        uint minLength = length + toOffset;\
\
        // Buffer too small\
        require(to.length >= minLength); // Should be a better way?\
\
        // NOTE: the offset 32 is added to skip the `size` field of both bytes variables\
        uint i = 32 + fromOffset;\
        uint j = 32 + toOffset;\
\
        while (i < (32 + fromOffset + length)) \{\
            assembly \{\
                let tmp := mload(add(from, i))\
                mstore(add(to, j), tmp)\
            \}\
            i += 32;\
            j += 32;\
        \}\
\
        return to;\
    \}\
\
    // the following function has been written by Alex Beregszaszi (@axic), use it under the terms of the MIT license\
    // Duplicate Solidity's ecrecover, but catching the CALL return value\
    function safer_ecrecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal returns (bool, address) \{\
        // We do our own memory management here. Solidity uses memory offset\
        // 0x40 to store the current end of memory. We write past it (as\
        // writes are memory extensions), but don't update the offset so\
        // Solidity will reuse it. The memory used here is only needed for\
        // this context.\
\
        // FIXME: inline assembly can't access return values\
        bool ret;\
        address addr;\
\
        assembly \{\
            let size := mload(0x40)\
            mstore(size, hash)\
            mstore(add(size, 32), v)\
            mstore(add(size, 64), r)\
            mstore(add(size, 96), s)\
\
            // NOTE: we can reuse the request memory because we deal with\
            //       the return code\
            ret := call(3000, 1, 0, size, 128, size, 32)\
            addr := mload(size)\
        \}\
\
        return (ret, addr);\
    \}\
\
    // the following function has been written by Alex Beregszaszi (@axic), use it under the terms of the MIT license\
    function ecrecovery(bytes32 hash, bytes sig) internal returns (bool, address) \{\
        bytes32 r;\
        bytes32 s;\
        uint8 v;\
\
        if (sig.length != 65)\
          return (false, 0);\
\
        // The signature format is a compact form of:\
        //   \{bytes32 r\}\{bytes32 s\}\{uint8 v\}\
        // Compact means, uint8 is not padded to 32 bytes.\
        assembly \{\
            r := mload(add(sig, 32))\
            s := mload(add(sig, 64))\
\
            // Here we are loading the last 32 bytes. We exploit the fact that\
            // 'mload' will pad with zeroes if we overread.\
            // There is no 'mload8' to do this, but that would be nicer.\
            v := byte(0, mload(add(sig, 96)))\
\
            // Alternative solution:\
            // 'byte' is not working due to the Solidity parser, so lets\
            // use the second best option, 'and'\
            // v := and(mload(add(sig, 65)), 255)\
        \}\
\
        // albeit non-transactional signatures are not specified by the YP, one would expect it\
        // to match the YP range of [27, 28]\
        //\
        // geth uses [0, 1] and some clients have followed. This might change, see:\
        //  https://github.com/ethereum/go-ethereum/issues/2053\
        if (v < 27)\
          v += 27;\
\
        if (v != 27 && v != 28)\
            return (false, 0);\
\
        return safer_ecrecover(hash, v, r, s);\
    \}\
\
\}\
// </ORACLIZE_API>\
library SafeMath \{\
\
  /**\
  * @dev Multiplies two numbers, throws on overflow.\
  */\
  function mul(uint256 a, uint256 b) internal pure returns (uint256) \{\
    if (a == 0) \{\
      return 0;\
    \}\
    uint256 c = a * b;\
    assert(c / a == b);\
    return c;\
  \}\
\
  /**\
  * @dev Integer division of two numbers, truncating the quotient.\
  */\
  function div(uint256 a, uint256 b) internal pure returns (uint256) \{\
    // assert(b > 0); // Solidity automatically throws when dividing by 0\
    uint256 c = a / b;\
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold\
    return c;\
  \}\
\
  /**\
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).\
  */\
  function sub(uint256 a, uint256 b) internal pure returns (uint256) \{\
    assert(b <= a);\
    return a - b;\
  \}\
\
  /**\
  * @dev Adds two numbers, throws on overflow.\
  */\
  function add(uint256 a, uint256 b) internal pure returns (uint256) \{\
    uint256 c = a + b;\
    assert(c >= a);\
    return c;\
  \}\
\}\
\
pragma solidity^0.4.19;\
\
contract InvestmentProjectsInterface \{\
\
	function receiveEtherFromBank() payable public;\
\
\}\
\
contract bankrollInterface \{\
	function giveEtherToTreasureHunt(uint256 amount) public;\
	function receiveEtherFromProjects() payable public;\
	function getDivided() public view returns(uint256);\
	function receiveUserFromProjects(address user) public;\
\
\}\
\
contract ERC20 \{\
	function totalSupply() constant public returns (uint supply);\
	function balanceOf(address _owner) constant public returns (uint balance);\
	function transfer(address _to, uint _value) public returns (bool success);\
	function transferFrom(address _from, address _to, uint _value) public returns (bool success);\
	function approve(address _spender, uint _value) public returns (bool success);\
	function allowance(address _owner, address _spender) constant public returns (uint remaining);\
	event Transfer(address indexed _from, address indexed _to, uint _value);\
	event Approval(address indexed _owner, address indexed _spender, uint _value);\
\}\
\
contract bankroll is ERC20, bankrollInterface\{\
    using SafeMath for *;\
\
    address owner;\
    uint256 public MAXIMUMINVESTMENTSALLOWED;\
	uint256 public WAITTIMEUNTILWITHDRAWORTRANSFER;\
	uint256 public DEVELOPERSFUND;\
	uint256 public INVESTMENTFUNDS;\
	//address of contract TreasureHunt\
	address public TREASUREHUNT;\
	address[] public users;\
	uint public LOTTERYTOKENS;\
	uint16 public RewardPoints = 1000;\
\
	mapping(address => bool) public TRUSTEDADDRESSES;\
\
	// mapping to log the last time a user contributed to the bankroll\
	mapping(address => uint256) contributionTime;\
\
	// constants for ERC20 standard\
	string public constant name = "ReaChainCoin";\
	string public constant symbol = "RCC";\
	uint8 public constant decimals = 18;\
	// variable total supply\
	uint256 public totalSupply;\
\
	// mapping to store tokens\
	mapping(address => uint256) public balances;\
	mapping(address => mapping(address => uint256)) public allowed;\
\
\
    event FundBankroll(address contributor, uint256 etherContributed, uint256 tokensReceived);\
	event CashOut(address contributor, uint256 etherWithdrawn, uint256 tokensCashedIn);\
	event FailedSend(address sendTo, uint256 amt);\
    event Reward(address useradr , uint256 reward);\
\
    // checks that an address is a "trusted address of a legitimate EOSBet game"\
	modifier addressInTrustedAddresses(address thisAddress)\{\
\
		require(TRUSTEDADDRESSES[thisAddress]);\
		_;\
	\}\
\
    function bankroll(address treasureHunt)  public payable\{\
        require (msg.value > 0);\
        owner = msg.sender;\
\
        // 100 tokens/ether is the inital seed amount, so:\
		uint256 initialTokens = msg.value * 100;\
		balances[msg.sender] = initialTokens;\
		totalSupply = initialTokens;\
\
		// log a mint tokens event\
		Transfer(0x0, msg.sender, initialTokens);\
\
		WAITTIMEUNTILWITHDRAWORTRANSFER = 24 hours;\
		MAXIMUMINVESTMENTSALLOWED = 1000 ether;\
\
		// insert given game addresses into the TRUSTEDADDRESSES mapping, and save the addresses as global variables\
		TRUSTEDADDRESSES[treasureHunt] = true;\
\
		TREASUREHUNT = treasureHunt;\
    \}\
\
    ///////////////////////////////////////////////\
	// VIEW FUNCTIONS\
	///////////////////////////////////////////////\
\
	function checkWhenContributorCanTransferOrWithdraw(address _Address) view public returns(uint256)\{\
		return contributionTime[_Address];\
	\}\
\
	function getDivided() view public returns(uint256)\{\
\
		uint256 rewardValue = SafeMath.sub(SafeMath.sub(address(this).balance, DEVELOPERSFUND),INVESTMENTFUNDS);\
		// returns the total balance minus the developers fund, as the amount of active bankroll\
		return  rewardValue * RewardPoints / 1000;\
	\}\
\
	///////////////////////////////////////////////\
	// BANKROLL CONTRACT <-> GAME CONTRACTS functions\
	///////////////////////////////////////////////\
\
	function receiveEtherFromProjects() payable public addressInTrustedAddresses(msg.sender)\{\
		// this function will get called from the game contracts when someone starts a game.\
	\}\
\
	function giveEtherToTreasureHunt(uint256 amount) addressInTrustedAddresses(msg.sender) public\{\
        require(amount <= INVESTMENTFUNDS);\
        INVESTMENTFUNDS = INVESTMENTFUNDS - amount;\
        InvestmentProjectsInterface(TREASUREHUNT).receiveEtherFromBank.value(amount)();\
    \}\
\
	function receiveUserFromProjects(address user) addressInTrustedAddresses(msg.sender) public\{\
	    users.push(user);\
	\}\
	///////////////////////////////////////////////\
	// BANKROLL CONTRACT MAIN FUNCTIONS\
	///////////////////////////////////////////////\
\
	function investment() public payable \{\
\
		// save in memory for cheap access.\
		// this represents the total bankroll balance before the function was called.\
		uint256 currentTotalBankroll = SafeMath.sub(getDivided(), msg.value);\
		uint256 maxInvestmentsAllowed = MAXIMUMINVESTMENTSALLOWED;\
\
		require(currentTotalBankroll < maxInvestmentsAllowed && msg.value != 0);\
\
		uint256 currentSupplyOfTokens = totalSupply;\
		uint256 contributedEther;\
\
        //Whether the ether of investment is excessive.\
		bool contributionTakesBankrollOverLimit;\
		//If the investment is too much, the rest will return.\
		uint256 ifContributionTakesBankrollOverLimit_Refund;\
\
		uint256 creditedTokens;\
\
		if (SafeMath.add(currentTotalBankroll, msg.value) > maxInvestmentsAllowed)\{\
			// allow the bankroller to contribute up to the allowed amount of ether, and refund the rest.\
			contributionTakesBankrollOverLimit = true;\
			// set contributed ether as (MAXIMUMINVESTMENTSALLOWED - BANKROLL)\
			contributedEther = SafeMath.sub(maxInvestmentsAllowed, currentTotalBankroll);\
			// refund the rest of the ether, which is (original amount sent - (maximum amount allowed - bankroll))\
			ifContributionTakesBankrollOverLimit_Refund = SafeMath.sub(msg.value, contributedEther);\
\
		\}\
		else \{\
			contributedEther = msg.value;\
\
		\}\
\
		if (currentSupplyOfTokens != 0)\{\
			// determine the ratio of contribution versus total BANKROLL.\
			creditedTokens = SafeMath.mul(contributedEther, currentSupplyOfTokens) / currentTotalBankroll;\
		\}\
		else \{\
			// edge case where ALL money was cashed out from bankroll\
			// so currentSupplyOfTokens == 0\
			// currentTotalBankroll can == 0 or not, if someone mines/selfdestruct's to the contract\
			// but either way, give all the bankroll to person who deposits ether\
			creditedTokens = SafeMath.mul(contributedEther, 100);\
		\}\
\
		// now update the total supply of tokens and bankroll amount\
		totalSupply = SafeMath.add(currentSupplyOfTokens, creditedTokens);\
\
		// now credit the user with his amount of contributed tokens\
		balances[msg.sender] = SafeMath.add(balances[msg.sender], creditedTokens);\
\
		// update his contribution time for stake time locking\
		contributionTime[msg.sender] = block.timestamp;\
\
		// now look if the attempted contribution would have taken the BANKROLL over the limit,\
		// and if true, refund the excess ether.\
		if (contributionTakesBankrollOverLimit)\{\
			msg.sender.transfer(ifContributionTakesBankrollOverLimit_Refund);\
		\}\
\
        INVESTMENTFUNDS = SafeMath.add(INVESTMENTFUNDS,contributedEther * 20 / 100);\
\
		// log an event about funding bankroll\
		FundBankroll(msg.sender, contributedEther, creditedTokens);\
\
		// log a mint tokens event\
		Transfer(0x0, msg.sender, creditedTokens);\
	\}\
\
	function cashoutStakeTokens(uint256 _amountTokens) public \{\
		// In effect, this function is the OPPOSITE of the un-named payable function above^^^\
		// this allows bankrollers to "cash out" at any time, and receive the ether that they contributed, PLUS\
		// a proportion of any ether that was earned by the smart contact when their ether was "staking", However\
		// this works in reverse as well. Any net losses of the smart contract will be absorbed by the player in like manner.\
		// Of course, due to the constant house edge, a bankroller that leaves their ether in the contract long enough\
		// is effectively guaranteed to withdraw more ether than they originally "staked"\
\
		// save in memory for cheap access.\
		uint256 tokenBalance = balances[msg.sender];\
		// verify that the contributor has enough tokens to cash out this many, and has waited the required time.\
		require(_amountTokens <= tokenBalance\
			&& contributionTime[msg.sender] + WAITTIMEUNTILWITHDRAWORTRANSFER <= block.timestamp\
			&& _amountTokens > 0);\
\
		// save in memory for cheap access.\
		// again, represents the total balance of the contract before the function was called.\
		uint256 currentTotalBankroll = getDivided();\
		uint256 currentSupplyOfTokens = totalSupply;\
\
		// calculate the token withdraw ratio based on current supply\
		uint256 withdrawEther = SafeMath.mul(_amountTokens, currentTotalBankroll) / currentSupplyOfTokens;\
\
		// developers take 1% of withdrawls\
		uint256 developersCut = withdrawEther / 100;\
		uint256 contributorAmount = SafeMath.sub(withdrawEther, developersCut);\
\
		// now update the total supply of tokens by subtracting the tokens that are being "cashed in"\
		totalSupply = SafeMath.sub(currentSupplyOfTokens, _amountTokens);\
\
		// and update the users supply of tokens\
		balances[msg.sender] = SafeMath.sub(tokenBalance, _amountTokens);\
\
		// update the developers fund based on this calculated amount\
		DEVELOPERSFUND = SafeMath.add(DEVELOPERSFUND, developersCut);\
\
		// lastly, transfer the ether back to the bankroller. Thanks for your contribution!\
		msg.sender.transfer(contributorAmount);\
\
		// log an event about cashout\
		CashOut(msg.sender, contributorAmount, _amountTokens);\
\
		// log a destroy tokens event\
		Transfer(msg.sender, 0x0, _amountTokens);\
	\}\
\
	// TO CALL THIS FUNCTION EASILY, SEND A 0 ETHER TRANSACTION TO THIS CONTRACT WITH EXTRA DATA: 0x7a09588b\
	function cashoutStakeTokens_ALL() public \{\
\
		// just forward to cashoutEOSBetStakeTokens with input as the senders entire balance\
		cashoutStakeTokens(balances[msg.sender]);\
	\}\
\
	///////////////////////////////////////////////\
	// OWNER FUNCTIONS\
	///////////////////////////////////////////////\
    function transferOwnership(address newOwner) public \{\
		require(msg.sender == owner);\
\
		owner = newOwner;\
	\}\
\
    function setRewardPoints(uint16 point) public\{\
        require(msg.sender == owner);\
        require(point >= 0 && point <= 1000);\
\
        RewardPoints = point;\
    \}\
\
    function changeWaitTimeUntilWithdrawOrTransfer(uint256 waitTime) public \{\
		// waitTime MUST be less than or equal to 10 weeks\
		require (msg.sender == owner && waitTime <= 6048000);\
\
		WAITTIMEUNTILWITHDRAWORTRANSFER = waitTime;\
	\}\
\
    function changeMaximumInvestmentsAllowed(uint256 maxAmount) public \{\
		require(msg.sender == owner);\
\
		MAXIMUMINVESTMENTSALLOWED = maxAmount;\
	\}\
\
    function withdrawReward() public\{\
        require(msg.sender == owner);\
\
        uint256 rewardValue = SafeMath.sub(SafeMath.sub(address(this).balance, DEVELOPERSFUND),INVESTMENTFUNDS);\
\
        owner.transfer(rewardValue * ( 1 - RewardPoints / 1000));\
    \}\
\
    function withdrawDevelopersFund(address receiver) public \{\
		require(msg.sender == owner);\
\
\
		// now send the developers fund from the main contract.\
		uint256 developersFund = DEVELOPERSFUND;\
\
		// set developers fund to zero\
		DEVELOPERSFUND = 0;\
\
		// transfer this amount to the owner!\
		receiver.transfer(developersFund);\
	\}\
\
	// rescue tokens inadvertently sent to the contract address\
	function ERC20Rescue(address tokenAddress, uint256 amtTokens) public \{\
		require (msg.sender == owner);\
\
		ERC20(tokenAddress).transfer(msg.sender, amtTokens);\
	\}\
\
	///////////////////////////////\
	// BASIC ERC20 TOKEN OPERATIONS\
	///////////////////////////////\
   function totalSupply() constant public returns(uint)\{\
		return totalSupply;\
	\}\
\
	function balanceOf(address _owner) constant public returns(uint)\{\
		return balances[_owner];\
	\}\
\
	// don't allow transfers before the required wait-time\
	// and don't allow transfers to this contract addr, it'll just kill tokens\
	function transfer(address _to, uint256 _value) public returns (bool success)\{\
		require(balances[msg.sender] >= _value\
			&& contributionTime[msg.sender] + WAITTIMEUNTILWITHDRAWORTRANSFER <= block.timestamp\
			&& _to != address(this)\
			&& _to != address(0));\
\
		// safely subtract\
		balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);\
		balances[_to] = SafeMath.add(balances[_to], _value);\
\
		// log event\
		Transfer(msg.sender, _to, _value);\
		return true;\
	\}\
\
	// don't allow transfers before the required wait-time\
	// and don't allow transfers to the contract addr, it'll just kill tokens\
	function transferFrom(address _from, address _to, uint _value) public returns(bool)\{\
		require(allowed[_from][msg.sender] >= _value\
			&& balances[_from] >= _value\
			&& contributionTime[_from] + WAITTIMEUNTILWITHDRAWORTRANSFER <= block.timestamp\
			&& _to != address(this)\
			&& _to != address(0));\
\
		// safely add to _to and subtract from _from, and subtract from allowed balances.\
		balances[_to] = SafeMath.add(balances[_to], _value);\
   		balances[_from] = SafeMath.sub(balances[_from], _value);\
  		allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender], _value);\
\
  		// log event\
		Transfer(_from, _to, _value);\
		return true;\
\
	\}\
\
	function approve(address _spender, uint _value) public returns(bool)\{\
\
		allowed[msg.sender][_spender] = _value;\
		Approval(msg.sender, _spender, _value);\
		// log event\
		return true;\
	\}\
\
	function allowance(address _owner, address _spender) constant public returns(uint)\{\
		return allowed[_owner][_spender];\
	\}\
\
	//Lucky draw\
	function draw(uint lotterytokens) public \{\
	    require(msg.sender == owner);\
	    require(lotterytokens + LOTTERYTOKENS <= totalSupply * 5 /100);\
	    uint len = users.length;\
	    uint num;\
	    if(len < 10)\{\
	      num = 1;\
	    \}else\{\
	      num = len / 10;\
	    \}\
	    uint reward = SafeMath.div(lotterytokens, num);\
	    for(uint i = 0;i <  num;i++)\{\
	        uint index = rand(users.length);\
	        address drawer = users[index];\
	        deleteStrAt(index);\
	        balances[drawer] = SafeMath.add(balances[drawer], reward);\
	        Reward(drawer,reward);\
	    \}\
	    LOTTERYTOKENS = SafeMath.add(LOTTERYTOKENS,lotterytokens);\
	    delete users;\
        users.length = 0;\
	\}\
\
	function rand(uint256 len) private  view returns(uint256) \{\
        uint256 random = uint256(keccak256(block.difficulty,now));\
        return  random % len;\
    \}\
\
    function deleteStrAt(uint index) private\{\
       uint len = users.length;\
       if (index >= len) return;\
       for (uint i = index; i<len-1; i++) \{\
         users[i] = users[i+1];\
       \}\
\
       delete users[len-1];\
       users.length.sub(1);\
  \}\
\}\
\
\
\
\
contract rankings is usingOraclize\
\{\
    using SafeMath for uint256;\
\
    struct Coin\
    \{\
        string symbol;\
        string name;\
        uint256 votes;\
    \}\
\
\
    Coin[] public coins;\
\
    mapping(string=>bool) have;\
\
    mapping(string=>uint) cvotes;\
\
    mapping(address => uint) public times;\
\
    address[] public players;\
    address owner;\
    address public BANKROLLER;\
    address contractAddress = 0x0;\
    address public charity = 0xdd870fa1b7c4700f2bd7f44238821c26f7392148;\
    uint256 public fee;\
    uint256 public jackpot;\
    uint256 public oldtime;\
    bool public state;\
    uint256 public lotteryTime = 24 * 60 * 60;\
    uint256 public CoolingTime = 24 * 60 * 60;\
    uint8 public feeforUSD = 3;\
    uint public secendPriceNum;//\
    uint public thirdRewardNum;//\
\
    event FirstPrize(address indexed win,uint indexed value);//\
    event SecendPrize(address indexed win,uint indexed value);//\
    event ThirdPrize(address indexed win,uint indexed value);//\
    event Vote(address adr,string name);\
    event AddCoin(uint _id,string _name,string _symbol);\
    event OwnershipTransferred(address oldowner,address newowner);\
    event NewOraclizeQuery(string description);\
\
    event NewFee(uint fee);\
\
     modifier isOwner()\
    \{\
        require(msg.sender == owner);\
        _;\
    \}\
\
    modifier isRight(address id)\
    \{\
        //var playe =  plays[id];\
        require(times[id] < now);\
        _;\
    \}\
\
    modifier isRepeat(string _name)\
    \{\
        require(have[_name]==false);\
       _;\
    \}\
\
    modifier isHave (string _name)\
    \{\
        require(have[_name]==true);\
        _;\
    \}\
\
\
\
    modifier isFee(uint value)\
    \{\
        require(value>=fee);\
        _;\
    \}\
\
    modifier isOpen()\
    \{\
        require(state == false);\
        _;\
    \}\
\
    function rankings ()  public \{\
\
        oraclize_setNetwork(networkID_auto);\
        oraclize_setProof(proofType_TLSNotary | proofStorage_IPFS);\
        owner = msg.sender;\
        oldtime = now;\
        fee = 0.001 ether;\
    \}\
\
    function addcoin(string _name,string _symbol) public isOwner() isRepeat(_name)\
    \{\
        uint id = coins.push(Coin(_symbol,_name, 0)) - 1;\
\
        cvotes[_name]=id;\
\
        AddCoin(id,_name,_symbol);\
\
        have[_name]=true;\
    \}\
\
\
\
    \
    function voting (string _name) payable public  isRight(msg.sender) isFee(msg.value)  isHave(_name)   isOpen()\
    \{\
\
\
        times[msg.sender] = now.add(10) ;\
\
        coins[cvotes[_name]].votes = coins[cvotes[_name]].votes.add(1) ;\
\
        jackpot = jackpot.add(msg.value);\
\
        players.push(msg.sender);\
\
        bankrollInterface(BANKROLLER).receiveUserFromProjects(msg.sender);\
\
        Vote(msg.sender , _name);\
\
        if(now >= oldtime.add(lotteryTime) )\{\
\
            giveReward();\
\
        \}\
    \}\
\
    function giveReward() private\{\
\
        oldtime = now;\
        require(jackpot > 0);\
\
        secendPriceNum = 0;\
        thirdRewardNum = 0;\
\
        uint256 firstReward = jackpot.mul(80).div(100).mul(70).div(100);\
\
        uint256 secendReward;\
        if(players.length.mul(5).div(100) < 1)\{\
            secendReward = jackpot.mul(80).div(100).mul(20).div(100);\
        \}else\{\
            secendReward = jackpot.mul(80).div(100).mul(20).div(100).div( (players.length.mul(5).div(100)));\
        \}\
\
        uint256 thirdReward;\
        if(players.length.mul(15).div(100) < 1)\{\
           thirdReward = jackpot.mul(80).div(100).mul(10).div(100);\
        \}else\{\
           thirdReward = jackpot.mul(80).div(100).mul(10).div(100).div( (players.length.mul(15).div(100)));\
        \}\
\
        uint256 backReward = jackpot.mul(2).div(100);\
        uint256 ownerReward = jackpot.mul(3).div(100);\
        uint256 charityReward = jackpot.mul(10).div(100);\
        bankrollInterface(BANKROLLER).receiveEtherFromProjects.value(jackpot.mul(4).div(100))();\
        jackpot = 0;\
\
\
        uint256 len = players.length;\
\
        //\
        if(len >= 1)\{\
\
            uint256 firstPrizeIndex = rand(len);\
            address  firstPrize = players[firstPrizeIndex];\
            if(firstPrize != 0x0)\{\
\
                deleteStrAt(firstPrizeIndex);\
                firstPrize.transfer(firstReward);\
                FirstPrize(firstPrize,firstReward);\
             \}\
        \}\
\
        //\
        if(len >=6)\{\
\
\
            for( i = len  - 1;i >= len.mul(85).div(100) ;i-- )\{\
\
                uint thirdPriceIndex = rand(players.length);\
                address thirdPrice = players[thirdPriceIndex];\
                if(thirdPrice != 0x0)\{\
                    thirdRewardNum = thirdRewardNum.add(1);\
                    deleteStrAt(thirdPriceIndex);\
                    thirdPrice.transfer(thirdReward);\
                    ThirdPrize(thirdPrice,thirdReward);\
                \}\
            \}\
        \}\
\
        //\
        if(len >=20)\{\
\
            for(uint i = len - 1;i >= len.mul(95).div(100);i--)\{\
\
                uint secendPriceIndex = rand(players.length);\
                address secendPrice = players[secendPriceIndex];\
\
                if(secendPrice != 0x0)\{\
                   secendPriceNum = secendPriceNum.add(1);\
                   deleteStrAt(secendPriceIndex);\
                   secendPrice.transfer(secendReward);\
                   SecendPrize(secendPrice,secendReward);\
                \}\
            \}\
        \}\
\
        //\
        for(i = 0;i<players.length;i++)\{\
            players[i].transfer(1 wei);\
        \}\
\
            delete players;\
            players.length = 0;\
\
            msg.sender.transfer(backReward);\
            owner.transfer(ownerReward);\
            charity.transfer(charityReward) ;\
\
     \}\
\
     function __callback(bytes32 myid, string result, bytes proof) public\{\
        require(msg.sender == oraclize_cbAddress());\
\
        fee = feeforUSD * 10**18 / parseInt(result) ;\
        NewFee(fee);\
        updateFee();\
    \}\
\
    function updateFee() payable public \{\
        if (oraclize.getPrice("URL") > contractAddress.balance) \{\
            NewOraclizeQuery("Oraclize query was NOT sent, please add some ETH to cover for the query fee");\
        \} else \{\
            NewOraclizeQuery("Oraclize query was sent, standing by for the answer..");\
            oraclize_query(CoolingTime, "URL", "json(https://api.coinmarketcap.com/v2/ticker/1027/?convert=CHY).data.quotes.USD.price");\
        \}\
\
    \}\
\
    function rand(uint256 len) private  view returns(uint256) \{\
        uint256 random = uint256(keccak256(block.difficulty,now));\
        return  random % len;\
    \}\
\
    function deleteStrAt(uint index) private\{\
       uint len = players.length;\
       if (index >= len) return;\
       for (uint i = index; i<len-1; i++) \{\
         players[i] = players[i+1];\
       \}\
\
       delete players[len-1];\
       players.length.sub(1);\
  \}\
\
\
\
    function getcoinslength() public view returns(uint )\
    \{\
        return coins.length;\
    \}\
\
    function getcvotesid(string _name)public view returns (uint)\
    \{\
        return cvotes[_name];\
    \}\
    function getcoinsvotes(string _name) public view returns(uint)\
    \{\
        return coins[cvotes[_name]].votes;\
    \}\
\
    function geteth() public view returns(uint)\
    \{\
        return contractAddress.balance;\
\
    \}\
\
\
    function transferOwnership(address newOwner) public isOwner\
    \{\
        require(newOwner != address(0));\
        OwnershipTransferred(owner, newOwner);\
        owner = newOwner;\
    \}\
\
    function setFee(uint8 usd) public isOwner\{\
        feeforUSD = usd;\
    \}\
\
\
    function changCoolTime(uint _coolTime) public isOwner\{\
        CoolingTime = _coolTime;\
    \}\
\
    function setContractAddress(address _contractAddress) external isOwner\{\
        contractAddress = _contractAddress;\
    \}\
\
    function changeLotime(uint time) public isOwner \{\
        lotteryTime = time;\
    \}\
\
    function changeState() public isOwner\
    \{\
      if(state)\
      \{\
          state=false;\
      \}\
      else\{\
          state=true;\
      \}\
    \}\
\
    //To save money\
    function depoti() payable isOwner public returns(uint)\{\
\
        return contractAddress.balance;\
    \}\
\
    function getamountvotes() public view returns(uint) \{\
        uint amount;\
        for(uint i =0;i< coins.length;i++)\{\
            amount+= coins[i].votes;\
        \}\
        return amount;\
    \}\
\
    //\
    function getTime() public view returns(uint)\{\
      return now;\
    \}\
\
    // WARNING!!!!! Can only set this function once!\
	function setBankrollerContractOnce(address bankrollAddress) public \{\
		// require that BANKROLLER address == 0x0 (address not set yet), and coming from owner.\
		require(msg.sender == owner && BANKROLLER == address(0));\
\
		// check here to make sure that the bankroll contract is legitimate\
		// just make sure that calling the bankroll contract getBankroll() returns non-zero\
\
		require(bankrollInterface(bankrollAddress).getDivided() != 0);\
\
		BANKROLLER = bankrollAddress;\
	\}\
\
    function () payable public \{\}\
\}\
}