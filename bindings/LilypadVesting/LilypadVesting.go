// Code generated - DO NOT EDIT.
// This file is a generated binding and any manual changes will be lost.

package lilypadvesting

import (
	"errors"
	"math/big"
	"strings"

	ethereum "github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/event"
)

// Reference imports to suppress errors if they are not otherwise used.
var (
	_ = errors.New
	_ = big.NewInt
	_ = strings.NewReader
	_ = ethereum.NotFound
	_ = bind.Bind
	_ = common.Big1
	_ = types.BloomLookup
	_ = event.NewSubscription
	_ = abi.ConvertType
)

// LilypadVestingVestingSchedule is an auto generated low-level Go binding around an user-defined struct.
type LilypadVestingVestingSchedule struct {
	Beneficiary     common.Address
	TotalAmount     *big.Int
	StartTime       uint64
	Released        *big.Int
	CliffDuration   uint64
	VestingDuration uint64
	Revoked         bool
}

// LilypadVestingMetaData contains all meta data concerning the LilypadVesting contract.
var LilypadVestingMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"constructor\",\"inputs\":[{\"name\":\"_l2TokenAddress\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"DEFAULT_ADMIN_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"beneficiarySchedules\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"calculateReleasableTokens\",\"inputs\":[{\"name\":\"beneficiary\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"scheduleId\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"createVestingSchedule\",\"inputs\":[{\"name\":\"beneficiary\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"startTime\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"cliffDuration\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"vestingDuration\",\"type\":\"uint64\",\"internalType\":\"uint64\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"getL2TokenAddress\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getNumberOfSchedulesForBeneficiary\",\"inputs\":[{\"name\":\"beneficiary\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getRoleAdmin\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getVestingSchedule\",\"inputs\":[{\"name\":\"scheduleId\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"tuple\",\"internalType\":\"structLilypadVesting.VestingSchedule\",\"components\":[{\"name\":\"beneficiary\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"totalAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"startTime\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"released\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"cliffDuration\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"vestingDuration\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"revoked\",\"type\":\"bool\",\"internalType\":\"bool\"}]}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getVestingScheduleCount\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getVestingScheduleIds\",\"inputs\":[{\"name\":\"beneficiary\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getWithdrawableAmount\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"grantRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"hasRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"releaseTokens\",\"inputs\":[{\"name\":\"scheduleId\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"renounceRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"callerConfirmation\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"revokeRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"scheduleExists\",\"inputs\":[{\"name\":\"scheduleId\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"supportsInterface\",\"inputs\":[{\"name\":\"interfaceId\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"vestingScheduleCount\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"vestingSchedules\",\"inputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"beneficiary\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"totalAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"startTime\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"released\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"cliffDuration\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"vestingDuration\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"revoked\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"withdraw\",\"inputs\":[{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"event\",\"name\":\"LilypadVesting__VestingScheduleCreated\",\"inputs\":[{\"name\":\"beneficiary\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"scheduleId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"startTime\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"LilypadVesting__l2TokensReleased\",\"inputs\":[{\"name\":\"beneficiary\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"scheduleId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleAdminChanged\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"previousAdminRole\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"newAdminRole\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleGranted\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"sender\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleRevoked\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"sender\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"AccessControlBadConfirmation\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"AccessControlUnauthorizedAccount\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"neededRole\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}]},{\"type\":\"error\",\"name\":\"LilypadVesting__InsufficientBalanceToWithdraw\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"LilypadVesting__InvalidAmount\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"LilypadVesting__InvalidBeneficiary\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"LilypadVesting__InvalidDuration\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"LilypadVesting__InvalidScheduleId\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"LilypadVesting__InvalidStartTime\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"LilypadVesting__InvalidVestingSchedule\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"LilypadVesting__NoVestingSchedule\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"LilypadVesting__NothingToRelease\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"LilypadVesting__TransferFailed\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"LilypadVesting__VestingScheduleRevoked\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"LilypadVesting__ZeroAddressNotAllowed\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ReentrancyGuardReentrantCall\",\"inputs\":[]}]",
}

// LilypadVestingABI is the input ABI used to generate the binding from.
// Deprecated: Use LilypadVestingMetaData.ABI instead.
var LilypadVestingABI = LilypadVestingMetaData.ABI

// LilypadVesting is an auto generated Go binding around an Ethereum contract.
type LilypadVesting struct {
	LilypadVestingCaller     // Read-only binding to the contract
	LilypadVestingTransactor // Write-only binding to the contract
	LilypadVestingFilterer   // Log filterer for contract events
}

// LilypadVestingCaller is an auto generated read-only Go binding around an Ethereum contract.
type LilypadVestingCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// LilypadVestingTransactor is an auto generated write-only Go binding around an Ethereum contract.
type LilypadVestingTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// LilypadVestingFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type LilypadVestingFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// LilypadVestingSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type LilypadVestingSession struct {
	Contract     *LilypadVesting   // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// LilypadVestingCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type LilypadVestingCallerSession struct {
	Contract *LilypadVestingCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts         // Call options to use throughout this session
}

// LilypadVestingTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type LilypadVestingTransactorSession struct {
	Contract     *LilypadVestingTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts         // Transaction auth options to use throughout this session
}

// LilypadVestingRaw is an auto generated low-level Go binding around an Ethereum contract.
type LilypadVestingRaw struct {
	Contract *LilypadVesting // Generic contract binding to access the raw methods on
}

// LilypadVestingCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type LilypadVestingCallerRaw struct {
	Contract *LilypadVestingCaller // Generic read-only contract binding to access the raw methods on
}

// LilypadVestingTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type LilypadVestingTransactorRaw struct {
	Contract *LilypadVestingTransactor // Generic write-only contract binding to access the raw methods on
}

// NewLilypadVesting creates a new instance of LilypadVesting, bound to a specific deployed contract.
func NewLilypadVesting(address common.Address, backend bind.ContractBackend) (*LilypadVesting, error) {
	contract, err := bindLilypadVesting(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &LilypadVesting{LilypadVestingCaller: LilypadVestingCaller{contract: contract}, LilypadVestingTransactor: LilypadVestingTransactor{contract: contract}, LilypadVestingFilterer: LilypadVestingFilterer{contract: contract}}, nil
}

// NewLilypadVestingCaller creates a new read-only instance of LilypadVesting, bound to a specific deployed contract.
func NewLilypadVestingCaller(address common.Address, caller bind.ContractCaller) (*LilypadVestingCaller, error) {
	contract, err := bindLilypadVesting(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &LilypadVestingCaller{contract: contract}, nil
}

// NewLilypadVestingTransactor creates a new write-only instance of LilypadVesting, bound to a specific deployed contract.
func NewLilypadVestingTransactor(address common.Address, transactor bind.ContractTransactor) (*LilypadVestingTransactor, error) {
	contract, err := bindLilypadVesting(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &LilypadVestingTransactor{contract: contract}, nil
}

// NewLilypadVestingFilterer creates a new log filterer instance of LilypadVesting, bound to a specific deployed contract.
func NewLilypadVestingFilterer(address common.Address, filterer bind.ContractFilterer) (*LilypadVestingFilterer, error) {
	contract, err := bindLilypadVesting(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &LilypadVestingFilterer{contract: contract}, nil
}

// bindLilypadVesting binds a generic wrapper to an already deployed contract.
func bindLilypadVesting(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := LilypadVestingMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_LilypadVesting *LilypadVestingRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _LilypadVesting.Contract.LilypadVestingCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_LilypadVesting *LilypadVestingRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _LilypadVesting.Contract.LilypadVestingTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_LilypadVesting *LilypadVestingRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _LilypadVesting.Contract.LilypadVestingTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_LilypadVesting *LilypadVestingCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _LilypadVesting.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_LilypadVesting *LilypadVestingTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _LilypadVesting.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_LilypadVesting *LilypadVestingTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _LilypadVesting.Contract.contract.Transact(opts, method, params...)
}

// DEFAULTADMINROLE is a free data retrieval call binding the contract method 0xa217fddf.
//
// Solidity: function DEFAULT_ADMIN_ROLE() view returns(bytes32)
func (_LilypadVesting *LilypadVestingCaller) DEFAULTADMINROLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _LilypadVesting.contract.Call(opts, &out, "DEFAULT_ADMIN_ROLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// DEFAULTADMINROLE is a free data retrieval call binding the contract method 0xa217fddf.
//
// Solidity: function DEFAULT_ADMIN_ROLE() view returns(bytes32)
func (_LilypadVesting *LilypadVestingSession) DEFAULTADMINROLE() ([32]byte, error) {
	return _LilypadVesting.Contract.DEFAULTADMINROLE(&_LilypadVesting.CallOpts)
}

// DEFAULTADMINROLE is a free data retrieval call binding the contract method 0xa217fddf.
//
// Solidity: function DEFAULT_ADMIN_ROLE() view returns(bytes32)
func (_LilypadVesting *LilypadVestingCallerSession) DEFAULTADMINROLE() ([32]byte, error) {
	return _LilypadVesting.Contract.DEFAULTADMINROLE(&_LilypadVesting.CallOpts)
}

// BeneficiarySchedules is a free data retrieval call binding the contract method 0x46ca4241.
//
// Solidity: function beneficiarySchedules(address , uint256 ) view returns(uint256)
func (_LilypadVesting *LilypadVestingCaller) BeneficiarySchedules(opts *bind.CallOpts, arg0 common.Address, arg1 *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _LilypadVesting.contract.Call(opts, &out, "beneficiarySchedules", arg0, arg1)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// BeneficiarySchedules is a free data retrieval call binding the contract method 0x46ca4241.
//
// Solidity: function beneficiarySchedules(address , uint256 ) view returns(uint256)
func (_LilypadVesting *LilypadVestingSession) BeneficiarySchedules(arg0 common.Address, arg1 *big.Int) (*big.Int, error) {
	return _LilypadVesting.Contract.BeneficiarySchedules(&_LilypadVesting.CallOpts, arg0, arg1)
}

// BeneficiarySchedules is a free data retrieval call binding the contract method 0x46ca4241.
//
// Solidity: function beneficiarySchedules(address , uint256 ) view returns(uint256)
func (_LilypadVesting *LilypadVestingCallerSession) BeneficiarySchedules(arg0 common.Address, arg1 *big.Int) (*big.Int, error) {
	return _LilypadVesting.Contract.BeneficiarySchedules(&_LilypadVesting.CallOpts, arg0, arg1)
}

// CalculateReleasableTokens is a free data retrieval call binding the contract method 0x3b7f27eb.
//
// Solidity: function calculateReleasableTokens(address beneficiary, uint256 scheduleId) view returns(uint256)
func (_LilypadVesting *LilypadVestingCaller) CalculateReleasableTokens(opts *bind.CallOpts, beneficiary common.Address, scheduleId *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _LilypadVesting.contract.Call(opts, &out, "calculateReleasableTokens", beneficiary, scheduleId)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// CalculateReleasableTokens is a free data retrieval call binding the contract method 0x3b7f27eb.
//
// Solidity: function calculateReleasableTokens(address beneficiary, uint256 scheduleId) view returns(uint256)
func (_LilypadVesting *LilypadVestingSession) CalculateReleasableTokens(beneficiary common.Address, scheduleId *big.Int) (*big.Int, error) {
	return _LilypadVesting.Contract.CalculateReleasableTokens(&_LilypadVesting.CallOpts, beneficiary, scheduleId)
}

// CalculateReleasableTokens is a free data retrieval call binding the contract method 0x3b7f27eb.
//
// Solidity: function calculateReleasableTokens(address beneficiary, uint256 scheduleId) view returns(uint256)
func (_LilypadVesting *LilypadVestingCallerSession) CalculateReleasableTokens(beneficiary common.Address, scheduleId *big.Int) (*big.Int, error) {
	return _LilypadVesting.Contract.CalculateReleasableTokens(&_LilypadVesting.CallOpts, beneficiary, scheduleId)
}

// GetL2TokenAddress is a free data retrieval call binding the contract method 0x0be86c50.
//
// Solidity: function getL2TokenAddress() view returns(address)
func (_LilypadVesting *LilypadVestingCaller) GetL2TokenAddress(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _LilypadVesting.contract.Call(opts, &out, "getL2TokenAddress")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// GetL2TokenAddress is a free data retrieval call binding the contract method 0x0be86c50.
//
// Solidity: function getL2TokenAddress() view returns(address)
func (_LilypadVesting *LilypadVestingSession) GetL2TokenAddress() (common.Address, error) {
	return _LilypadVesting.Contract.GetL2TokenAddress(&_LilypadVesting.CallOpts)
}

// GetL2TokenAddress is a free data retrieval call binding the contract method 0x0be86c50.
//
// Solidity: function getL2TokenAddress() view returns(address)
func (_LilypadVesting *LilypadVestingCallerSession) GetL2TokenAddress() (common.Address, error) {
	return _LilypadVesting.Contract.GetL2TokenAddress(&_LilypadVesting.CallOpts)
}

// GetNumberOfSchedulesForBeneficiary is a free data retrieval call binding the contract method 0xec24aecb.
//
// Solidity: function getNumberOfSchedulesForBeneficiary(address beneficiary) view returns(uint256)
func (_LilypadVesting *LilypadVestingCaller) GetNumberOfSchedulesForBeneficiary(opts *bind.CallOpts, beneficiary common.Address) (*big.Int, error) {
	var out []interface{}
	err := _LilypadVesting.contract.Call(opts, &out, "getNumberOfSchedulesForBeneficiary", beneficiary)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetNumberOfSchedulesForBeneficiary is a free data retrieval call binding the contract method 0xec24aecb.
//
// Solidity: function getNumberOfSchedulesForBeneficiary(address beneficiary) view returns(uint256)
func (_LilypadVesting *LilypadVestingSession) GetNumberOfSchedulesForBeneficiary(beneficiary common.Address) (*big.Int, error) {
	return _LilypadVesting.Contract.GetNumberOfSchedulesForBeneficiary(&_LilypadVesting.CallOpts, beneficiary)
}

// GetNumberOfSchedulesForBeneficiary is a free data retrieval call binding the contract method 0xec24aecb.
//
// Solidity: function getNumberOfSchedulesForBeneficiary(address beneficiary) view returns(uint256)
func (_LilypadVesting *LilypadVestingCallerSession) GetNumberOfSchedulesForBeneficiary(beneficiary common.Address) (*big.Int, error) {
	return _LilypadVesting.Contract.GetNumberOfSchedulesForBeneficiary(&_LilypadVesting.CallOpts, beneficiary)
}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 role) view returns(bytes32)
func (_LilypadVesting *LilypadVestingCaller) GetRoleAdmin(opts *bind.CallOpts, role [32]byte) ([32]byte, error) {
	var out []interface{}
	err := _LilypadVesting.contract.Call(opts, &out, "getRoleAdmin", role)

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 role) view returns(bytes32)
func (_LilypadVesting *LilypadVestingSession) GetRoleAdmin(role [32]byte) ([32]byte, error) {
	return _LilypadVesting.Contract.GetRoleAdmin(&_LilypadVesting.CallOpts, role)
}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 role) view returns(bytes32)
func (_LilypadVesting *LilypadVestingCallerSession) GetRoleAdmin(role [32]byte) ([32]byte, error) {
	return _LilypadVesting.Contract.GetRoleAdmin(&_LilypadVesting.CallOpts, role)
}

// GetVestingSchedule is a free data retrieval call binding the contract method 0xbeb8f883.
//
// Solidity: function getVestingSchedule(uint256 scheduleId) view returns((address,uint256,uint64,uint256,uint64,uint64,bool))
func (_LilypadVesting *LilypadVestingCaller) GetVestingSchedule(opts *bind.CallOpts, scheduleId *big.Int) (LilypadVestingVestingSchedule, error) {
	var out []interface{}
	err := _LilypadVesting.contract.Call(opts, &out, "getVestingSchedule", scheduleId)

	if err != nil {
		return *new(LilypadVestingVestingSchedule), err
	}

	out0 := *abi.ConvertType(out[0], new(LilypadVestingVestingSchedule)).(*LilypadVestingVestingSchedule)

	return out0, err

}

// GetVestingSchedule is a free data retrieval call binding the contract method 0xbeb8f883.
//
// Solidity: function getVestingSchedule(uint256 scheduleId) view returns((address,uint256,uint64,uint256,uint64,uint64,bool))
func (_LilypadVesting *LilypadVestingSession) GetVestingSchedule(scheduleId *big.Int) (LilypadVestingVestingSchedule, error) {
	return _LilypadVesting.Contract.GetVestingSchedule(&_LilypadVesting.CallOpts, scheduleId)
}

// GetVestingSchedule is a free data retrieval call binding the contract method 0xbeb8f883.
//
// Solidity: function getVestingSchedule(uint256 scheduleId) view returns((address,uint256,uint64,uint256,uint64,uint64,bool))
func (_LilypadVesting *LilypadVestingCallerSession) GetVestingSchedule(scheduleId *big.Int) (LilypadVestingVestingSchedule, error) {
	return _LilypadVesting.Contract.GetVestingSchedule(&_LilypadVesting.CallOpts, scheduleId)
}

// GetVestingScheduleCount is a free data retrieval call binding the contract method 0x9295ccec.
//
// Solidity: function getVestingScheduleCount() view returns(uint256)
func (_LilypadVesting *LilypadVestingCaller) GetVestingScheduleCount(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _LilypadVesting.contract.Call(opts, &out, "getVestingScheduleCount")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetVestingScheduleCount is a free data retrieval call binding the contract method 0x9295ccec.
//
// Solidity: function getVestingScheduleCount() view returns(uint256)
func (_LilypadVesting *LilypadVestingSession) GetVestingScheduleCount() (*big.Int, error) {
	return _LilypadVesting.Contract.GetVestingScheduleCount(&_LilypadVesting.CallOpts)
}

// GetVestingScheduleCount is a free data retrieval call binding the contract method 0x9295ccec.
//
// Solidity: function getVestingScheduleCount() view returns(uint256)
func (_LilypadVesting *LilypadVestingCallerSession) GetVestingScheduleCount() (*big.Int, error) {
	return _LilypadVesting.Contract.GetVestingScheduleCount(&_LilypadVesting.CallOpts)
}

// GetVestingScheduleIds is a free data retrieval call binding the contract method 0xddcb2315.
//
// Solidity: function getVestingScheduleIds(address beneficiary) view returns(uint256[])
func (_LilypadVesting *LilypadVestingCaller) GetVestingScheduleIds(opts *bind.CallOpts, beneficiary common.Address) ([]*big.Int, error) {
	var out []interface{}
	err := _LilypadVesting.contract.Call(opts, &out, "getVestingScheduleIds", beneficiary)

	if err != nil {
		return *new([]*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new([]*big.Int)).(*[]*big.Int)

	return out0, err

}

// GetVestingScheduleIds is a free data retrieval call binding the contract method 0xddcb2315.
//
// Solidity: function getVestingScheduleIds(address beneficiary) view returns(uint256[])
func (_LilypadVesting *LilypadVestingSession) GetVestingScheduleIds(beneficiary common.Address) ([]*big.Int, error) {
	return _LilypadVesting.Contract.GetVestingScheduleIds(&_LilypadVesting.CallOpts, beneficiary)
}

// GetVestingScheduleIds is a free data retrieval call binding the contract method 0xddcb2315.
//
// Solidity: function getVestingScheduleIds(address beneficiary) view returns(uint256[])
func (_LilypadVesting *LilypadVestingCallerSession) GetVestingScheduleIds(beneficiary common.Address) ([]*big.Int, error) {
	return _LilypadVesting.Contract.GetVestingScheduleIds(&_LilypadVesting.CallOpts, beneficiary)
}

// GetWithdrawableAmount is a free data retrieval call binding the contract method 0x90be10cc.
//
// Solidity: function getWithdrawableAmount() view returns(uint256)
func (_LilypadVesting *LilypadVestingCaller) GetWithdrawableAmount(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _LilypadVesting.contract.Call(opts, &out, "getWithdrawableAmount")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetWithdrawableAmount is a free data retrieval call binding the contract method 0x90be10cc.
//
// Solidity: function getWithdrawableAmount() view returns(uint256)
func (_LilypadVesting *LilypadVestingSession) GetWithdrawableAmount() (*big.Int, error) {
	return _LilypadVesting.Contract.GetWithdrawableAmount(&_LilypadVesting.CallOpts)
}

// GetWithdrawableAmount is a free data retrieval call binding the contract method 0x90be10cc.
//
// Solidity: function getWithdrawableAmount() view returns(uint256)
func (_LilypadVesting *LilypadVestingCallerSession) GetWithdrawableAmount() (*big.Int, error) {
	return _LilypadVesting.Contract.GetWithdrawableAmount(&_LilypadVesting.CallOpts)
}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 role, address account) view returns(bool)
func (_LilypadVesting *LilypadVestingCaller) HasRole(opts *bind.CallOpts, role [32]byte, account common.Address) (bool, error) {
	var out []interface{}
	err := _LilypadVesting.contract.Call(opts, &out, "hasRole", role, account)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 role, address account) view returns(bool)
func (_LilypadVesting *LilypadVestingSession) HasRole(role [32]byte, account common.Address) (bool, error) {
	return _LilypadVesting.Contract.HasRole(&_LilypadVesting.CallOpts, role, account)
}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 role, address account) view returns(bool)
func (_LilypadVesting *LilypadVestingCallerSession) HasRole(role [32]byte, account common.Address) (bool, error) {
	return _LilypadVesting.Contract.HasRole(&_LilypadVesting.CallOpts, role, account)
}

// ScheduleExists is a free data retrieval call binding the contract method 0xa4b186f8.
//
// Solidity: function scheduleExists(uint256 scheduleId) view returns(bool)
func (_LilypadVesting *LilypadVestingCaller) ScheduleExists(opts *bind.CallOpts, scheduleId *big.Int) (bool, error) {
	var out []interface{}
	err := _LilypadVesting.contract.Call(opts, &out, "scheduleExists", scheduleId)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// ScheduleExists is a free data retrieval call binding the contract method 0xa4b186f8.
//
// Solidity: function scheduleExists(uint256 scheduleId) view returns(bool)
func (_LilypadVesting *LilypadVestingSession) ScheduleExists(scheduleId *big.Int) (bool, error) {
	return _LilypadVesting.Contract.ScheduleExists(&_LilypadVesting.CallOpts, scheduleId)
}

// ScheduleExists is a free data retrieval call binding the contract method 0xa4b186f8.
//
// Solidity: function scheduleExists(uint256 scheduleId) view returns(bool)
func (_LilypadVesting *LilypadVestingCallerSession) ScheduleExists(scheduleId *big.Int) (bool, error) {
	return _LilypadVesting.Contract.ScheduleExists(&_LilypadVesting.CallOpts, scheduleId)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_LilypadVesting *LilypadVestingCaller) SupportsInterface(opts *bind.CallOpts, interfaceId [4]byte) (bool, error) {
	var out []interface{}
	err := _LilypadVesting.contract.Call(opts, &out, "supportsInterface", interfaceId)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_LilypadVesting *LilypadVestingSession) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _LilypadVesting.Contract.SupportsInterface(&_LilypadVesting.CallOpts, interfaceId)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_LilypadVesting *LilypadVestingCallerSession) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _LilypadVesting.Contract.SupportsInterface(&_LilypadVesting.CallOpts, interfaceId)
}

// VestingScheduleCount is a free data retrieval call binding the contract method 0x53c7efa9.
//
// Solidity: function vestingScheduleCount() view returns(uint256)
func (_LilypadVesting *LilypadVestingCaller) VestingScheduleCount(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _LilypadVesting.contract.Call(opts, &out, "vestingScheduleCount")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// VestingScheduleCount is a free data retrieval call binding the contract method 0x53c7efa9.
//
// Solidity: function vestingScheduleCount() view returns(uint256)
func (_LilypadVesting *LilypadVestingSession) VestingScheduleCount() (*big.Int, error) {
	return _LilypadVesting.Contract.VestingScheduleCount(&_LilypadVesting.CallOpts)
}

// VestingScheduleCount is a free data retrieval call binding the contract method 0x53c7efa9.
//
// Solidity: function vestingScheduleCount() view returns(uint256)
func (_LilypadVesting *LilypadVestingCallerSession) VestingScheduleCount() (*big.Int, error) {
	return _LilypadVesting.Contract.VestingScheduleCount(&_LilypadVesting.CallOpts)
}

// VestingSchedules is a free data retrieval call binding the contract method 0x6d3cbe21.
//
// Solidity: function vestingSchedules(uint256 ) view returns(address beneficiary, uint256 totalAmount, uint64 startTime, uint256 released, uint64 cliffDuration, uint64 vestingDuration, bool revoked)
func (_LilypadVesting *LilypadVestingCaller) VestingSchedules(opts *bind.CallOpts, arg0 *big.Int) (struct {
	Beneficiary     common.Address
	TotalAmount     *big.Int
	StartTime       uint64
	Released        *big.Int
	CliffDuration   uint64
	VestingDuration uint64
	Revoked         bool
}, error) {
	var out []interface{}
	err := _LilypadVesting.contract.Call(opts, &out, "vestingSchedules", arg0)

	outstruct := new(struct {
		Beneficiary     common.Address
		TotalAmount     *big.Int
		StartTime       uint64
		Released        *big.Int
		CliffDuration   uint64
		VestingDuration uint64
		Revoked         bool
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.Beneficiary = *abi.ConvertType(out[0], new(common.Address)).(*common.Address)
	outstruct.TotalAmount = *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)
	outstruct.StartTime = *abi.ConvertType(out[2], new(uint64)).(*uint64)
	outstruct.Released = *abi.ConvertType(out[3], new(*big.Int)).(**big.Int)
	outstruct.CliffDuration = *abi.ConvertType(out[4], new(uint64)).(*uint64)
	outstruct.VestingDuration = *abi.ConvertType(out[5], new(uint64)).(*uint64)
	outstruct.Revoked = *abi.ConvertType(out[6], new(bool)).(*bool)

	return *outstruct, err

}

// VestingSchedules is a free data retrieval call binding the contract method 0x6d3cbe21.
//
// Solidity: function vestingSchedules(uint256 ) view returns(address beneficiary, uint256 totalAmount, uint64 startTime, uint256 released, uint64 cliffDuration, uint64 vestingDuration, bool revoked)
func (_LilypadVesting *LilypadVestingSession) VestingSchedules(arg0 *big.Int) (struct {
	Beneficiary     common.Address
	TotalAmount     *big.Int
	StartTime       uint64
	Released        *big.Int
	CliffDuration   uint64
	VestingDuration uint64
	Revoked         bool
}, error) {
	return _LilypadVesting.Contract.VestingSchedules(&_LilypadVesting.CallOpts, arg0)
}

// VestingSchedules is a free data retrieval call binding the contract method 0x6d3cbe21.
//
// Solidity: function vestingSchedules(uint256 ) view returns(address beneficiary, uint256 totalAmount, uint64 startTime, uint256 released, uint64 cliffDuration, uint64 vestingDuration, bool revoked)
func (_LilypadVesting *LilypadVestingCallerSession) VestingSchedules(arg0 *big.Int) (struct {
	Beneficiary     common.Address
	TotalAmount     *big.Int
	StartTime       uint64
	Released        *big.Int
	CliffDuration   uint64
	VestingDuration uint64
	Revoked         bool
}, error) {
	return _LilypadVesting.Contract.VestingSchedules(&_LilypadVesting.CallOpts, arg0)
}

// CreateVestingSchedule is a paid mutator transaction binding the contract method 0x74d42410.
//
// Solidity: function createVestingSchedule(address beneficiary, uint256 amount, uint64 startTime, uint64 cliffDuration, uint64 vestingDuration) returns(bool)
func (_LilypadVesting *LilypadVestingTransactor) CreateVestingSchedule(opts *bind.TransactOpts, beneficiary common.Address, amount *big.Int, startTime uint64, cliffDuration uint64, vestingDuration uint64) (*types.Transaction, error) {
	return _LilypadVesting.contract.Transact(opts, "createVestingSchedule", beneficiary, amount, startTime, cliffDuration, vestingDuration)
}

// CreateVestingSchedule is a paid mutator transaction binding the contract method 0x74d42410.
//
// Solidity: function createVestingSchedule(address beneficiary, uint256 amount, uint64 startTime, uint64 cliffDuration, uint64 vestingDuration) returns(bool)
func (_LilypadVesting *LilypadVestingSession) CreateVestingSchedule(beneficiary common.Address, amount *big.Int, startTime uint64, cliffDuration uint64, vestingDuration uint64) (*types.Transaction, error) {
	return _LilypadVesting.Contract.CreateVestingSchedule(&_LilypadVesting.TransactOpts, beneficiary, amount, startTime, cliffDuration, vestingDuration)
}

// CreateVestingSchedule is a paid mutator transaction binding the contract method 0x74d42410.
//
// Solidity: function createVestingSchedule(address beneficiary, uint256 amount, uint64 startTime, uint64 cliffDuration, uint64 vestingDuration) returns(bool)
func (_LilypadVesting *LilypadVestingTransactorSession) CreateVestingSchedule(beneficiary common.Address, amount *big.Int, startTime uint64, cliffDuration uint64, vestingDuration uint64) (*types.Transaction, error) {
	return _LilypadVesting.Contract.CreateVestingSchedule(&_LilypadVesting.TransactOpts, beneficiary, amount, startTime, cliffDuration, vestingDuration)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_LilypadVesting *LilypadVestingTransactor) GrantRole(opts *bind.TransactOpts, role [32]byte, account common.Address) (*types.Transaction, error) {
	return _LilypadVesting.contract.Transact(opts, "grantRole", role, account)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_LilypadVesting *LilypadVestingSession) GrantRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _LilypadVesting.Contract.GrantRole(&_LilypadVesting.TransactOpts, role, account)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_LilypadVesting *LilypadVestingTransactorSession) GrantRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _LilypadVesting.Contract.GrantRole(&_LilypadVesting.TransactOpts, role, account)
}

// ReleaseTokens is a paid mutator transaction binding the contract method 0x4b0babdd.
//
// Solidity: function releaseTokens(uint256 scheduleId) returns(bool)
func (_LilypadVesting *LilypadVestingTransactor) ReleaseTokens(opts *bind.TransactOpts, scheduleId *big.Int) (*types.Transaction, error) {
	return _LilypadVesting.contract.Transact(opts, "releaseTokens", scheduleId)
}

// ReleaseTokens is a paid mutator transaction binding the contract method 0x4b0babdd.
//
// Solidity: function releaseTokens(uint256 scheduleId) returns(bool)
func (_LilypadVesting *LilypadVestingSession) ReleaseTokens(scheduleId *big.Int) (*types.Transaction, error) {
	return _LilypadVesting.Contract.ReleaseTokens(&_LilypadVesting.TransactOpts, scheduleId)
}

// ReleaseTokens is a paid mutator transaction binding the contract method 0x4b0babdd.
//
// Solidity: function releaseTokens(uint256 scheduleId) returns(bool)
func (_LilypadVesting *LilypadVestingTransactorSession) ReleaseTokens(scheduleId *big.Int) (*types.Transaction, error) {
	return _LilypadVesting.Contract.ReleaseTokens(&_LilypadVesting.TransactOpts, scheduleId)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address callerConfirmation) returns()
func (_LilypadVesting *LilypadVestingTransactor) RenounceRole(opts *bind.TransactOpts, role [32]byte, callerConfirmation common.Address) (*types.Transaction, error) {
	return _LilypadVesting.contract.Transact(opts, "renounceRole", role, callerConfirmation)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address callerConfirmation) returns()
func (_LilypadVesting *LilypadVestingSession) RenounceRole(role [32]byte, callerConfirmation common.Address) (*types.Transaction, error) {
	return _LilypadVesting.Contract.RenounceRole(&_LilypadVesting.TransactOpts, role, callerConfirmation)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address callerConfirmation) returns()
func (_LilypadVesting *LilypadVestingTransactorSession) RenounceRole(role [32]byte, callerConfirmation common.Address) (*types.Transaction, error) {
	return _LilypadVesting.Contract.RenounceRole(&_LilypadVesting.TransactOpts, role, callerConfirmation)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_LilypadVesting *LilypadVestingTransactor) RevokeRole(opts *bind.TransactOpts, role [32]byte, account common.Address) (*types.Transaction, error) {
	return _LilypadVesting.contract.Transact(opts, "revokeRole", role, account)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_LilypadVesting *LilypadVestingSession) RevokeRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _LilypadVesting.Contract.RevokeRole(&_LilypadVesting.TransactOpts, role, account)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_LilypadVesting *LilypadVestingTransactorSession) RevokeRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _LilypadVesting.Contract.RevokeRole(&_LilypadVesting.TransactOpts, role, account)
}

// Withdraw is a paid mutator transaction binding the contract method 0x2e1a7d4d.
//
// Solidity: function withdraw(uint256 amount) returns(bool)
func (_LilypadVesting *LilypadVestingTransactor) Withdraw(opts *bind.TransactOpts, amount *big.Int) (*types.Transaction, error) {
	return _LilypadVesting.contract.Transact(opts, "withdraw", amount)
}

// Withdraw is a paid mutator transaction binding the contract method 0x2e1a7d4d.
//
// Solidity: function withdraw(uint256 amount) returns(bool)
func (_LilypadVesting *LilypadVestingSession) Withdraw(amount *big.Int) (*types.Transaction, error) {
	return _LilypadVesting.Contract.Withdraw(&_LilypadVesting.TransactOpts, amount)
}

// Withdraw is a paid mutator transaction binding the contract method 0x2e1a7d4d.
//
// Solidity: function withdraw(uint256 amount) returns(bool)
func (_LilypadVesting *LilypadVestingTransactorSession) Withdraw(amount *big.Int) (*types.Transaction, error) {
	return _LilypadVesting.Contract.Withdraw(&_LilypadVesting.TransactOpts, amount)
}

// LilypadVestingLilypadVestingVestingScheduleCreatedIterator is returned from FilterLilypadVestingVestingScheduleCreated and is used to iterate over the raw logs and unpacked data for LilypadVestingVestingScheduleCreated events raised by the LilypadVesting contract.
type LilypadVestingLilypadVestingVestingScheduleCreatedIterator struct {
	Event *LilypadVestingLilypadVestingVestingScheduleCreated // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *LilypadVestingLilypadVestingVestingScheduleCreatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(LilypadVestingLilypadVestingVestingScheduleCreated)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(LilypadVestingLilypadVestingVestingScheduleCreated)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *LilypadVestingLilypadVestingVestingScheduleCreatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *LilypadVestingLilypadVestingVestingScheduleCreatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// LilypadVestingLilypadVestingVestingScheduleCreated represents a LilypadVestingVestingScheduleCreated event raised by the LilypadVesting contract.
type LilypadVestingLilypadVestingVestingScheduleCreated struct {
	Beneficiary common.Address
	ScheduleId  *big.Int
	Amount      *big.Int
	StartTime   *big.Int
	Raw         types.Log // Blockchain specific contextual infos
}

// FilterLilypadVestingVestingScheduleCreated is a free log retrieval operation binding the contract event 0x8041caca5c525dbba3d75a05e10c0063bdd0448a460d4c3b509c60de4ff1f7a8.
//
// Solidity: event LilypadVesting__VestingScheduleCreated(address indexed beneficiary, uint256 indexed scheduleId, uint256 amount, uint256 startTime)
func (_LilypadVesting *LilypadVestingFilterer) FilterLilypadVestingVestingScheduleCreated(opts *bind.FilterOpts, beneficiary []common.Address, scheduleId []*big.Int) (*LilypadVestingLilypadVestingVestingScheduleCreatedIterator, error) {

	var beneficiaryRule []interface{}
	for _, beneficiaryItem := range beneficiary {
		beneficiaryRule = append(beneficiaryRule, beneficiaryItem)
	}
	var scheduleIdRule []interface{}
	for _, scheduleIdItem := range scheduleId {
		scheduleIdRule = append(scheduleIdRule, scheduleIdItem)
	}

	logs, sub, err := _LilypadVesting.contract.FilterLogs(opts, "LilypadVesting__VestingScheduleCreated", beneficiaryRule, scheduleIdRule)
	if err != nil {
		return nil, err
	}
	return &LilypadVestingLilypadVestingVestingScheduleCreatedIterator{contract: _LilypadVesting.contract, event: "LilypadVesting__VestingScheduleCreated", logs: logs, sub: sub}, nil
}

// WatchLilypadVestingVestingScheduleCreated is a free log subscription operation binding the contract event 0x8041caca5c525dbba3d75a05e10c0063bdd0448a460d4c3b509c60de4ff1f7a8.
//
// Solidity: event LilypadVesting__VestingScheduleCreated(address indexed beneficiary, uint256 indexed scheduleId, uint256 amount, uint256 startTime)
func (_LilypadVesting *LilypadVestingFilterer) WatchLilypadVestingVestingScheduleCreated(opts *bind.WatchOpts, sink chan<- *LilypadVestingLilypadVestingVestingScheduleCreated, beneficiary []common.Address, scheduleId []*big.Int) (event.Subscription, error) {

	var beneficiaryRule []interface{}
	for _, beneficiaryItem := range beneficiary {
		beneficiaryRule = append(beneficiaryRule, beneficiaryItem)
	}
	var scheduleIdRule []interface{}
	for _, scheduleIdItem := range scheduleId {
		scheduleIdRule = append(scheduleIdRule, scheduleIdItem)
	}

	logs, sub, err := _LilypadVesting.contract.WatchLogs(opts, "LilypadVesting__VestingScheduleCreated", beneficiaryRule, scheduleIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(LilypadVestingLilypadVestingVestingScheduleCreated)
				if err := _LilypadVesting.contract.UnpackLog(event, "LilypadVesting__VestingScheduleCreated", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseLilypadVestingVestingScheduleCreated is a log parse operation binding the contract event 0x8041caca5c525dbba3d75a05e10c0063bdd0448a460d4c3b509c60de4ff1f7a8.
//
// Solidity: event LilypadVesting__VestingScheduleCreated(address indexed beneficiary, uint256 indexed scheduleId, uint256 amount, uint256 startTime)
func (_LilypadVesting *LilypadVestingFilterer) ParseLilypadVestingVestingScheduleCreated(log types.Log) (*LilypadVestingLilypadVestingVestingScheduleCreated, error) {
	event := new(LilypadVestingLilypadVestingVestingScheduleCreated)
	if err := _LilypadVesting.contract.UnpackLog(event, "LilypadVesting__VestingScheduleCreated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// LilypadVestingLilypadVestingL2TokensReleasedIterator is returned from FilterLilypadVestingL2TokensReleased and is used to iterate over the raw logs and unpacked data for LilypadVestingL2TokensReleased events raised by the LilypadVesting contract.
type LilypadVestingLilypadVestingL2TokensReleasedIterator struct {
	Event *LilypadVestingLilypadVestingL2TokensReleased // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *LilypadVestingLilypadVestingL2TokensReleasedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(LilypadVestingLilypadVestingL2TokensReleased)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(LilypadVestingLilypadVestingL2TokensReleased)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *LilypadVestingLilypadVestingL2TokensReleasedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *LilypadVestingLilypadVestingL2TokensReleasedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// LilypadVestingLilypadVestingL2TokensReleased represents a LilypadVestingL2TokensReleased event raised by the LilypadVesting contract.
type LilypadVestingLilypadVestingL2TokensReleased struct {
	Beneficiary common.Address
	ScheduleId  *big.Int
	Amount      *big.Int
	Raw         types.Log // Blockchain specific contextual infos
}

// FilterLilypadVestingL2TokensReleased is a free log retrieval operation binding the contract event 0xbe3ba0dce66ef6b0edd30e152c58ccd66276e7fb061432341ddaf126661eef68.
//
// Solidity: event LilypadVesting__l2TokensReleased(address indexed beneficiary, uint256 indexed scheduleId, uint256 amount)
func (_LilypadVesting *LilypadVestingFilterer) FilterLilypadVestingL2TokensReleased(opts *bind.FilterOpts, beneficiary []common.Address, scheduleId []*big.Int) (*LilypadVestingLilypadVestingL2TokensReleasedIterator, error) {

	var beneficiaryRule []interface{}
	for _, beneficiaryItem := range beneficiary {
		beneficiaryRule = append(beneficiaryRule, beneficiaryItem)
	}
	var scheduleIdRule []interface{}
	for _, scheduleIdItem := range scheduleId {
		scheduleIdRule = append(scheduleIdRule, scheduleIdItem)
	}

	logs, sub, err := _LilypadVesting.contract.FilterLogs(opts, "LilypadVesting__l2TokensReleased", beneficiaryRule, scheduleIdRule)
	if err != nil {
		return nil, err
	}
	return &LilypadVestingLilypadVestingL2TokensReleasedIterator{contract: _LilypadVesting.contract, event: "LilypadVesting__l2TokensReleased", logs: logs, sub: sub}, nil
}

// WatchLilypadVestingL2TokensReleased is a free log subscription operation binding the contract event 0xbe3ba0dce66ef6b0edd30e152c58ccd66276e7fb061432341ddaf126661eef68.
//
// Solidity: event LilypadVesting__l2TokensReleased(address indexed beneficiary, uint256 indexed scheduleId, uint256 amount)
func (_LilypadVesting *LilypadVestingFilterer) WatchLilypadVestingL2TokensReleased(opts *bind.WatchOpts, sink chan<- *LilypadVestingLilypadVestingL2TokensReleased, beneficiary []common.Address, scheduleId []*big.Int) (event.Subscription, error) {

	var beneficiaryRule []interface{}
	for _, beneficiaryItem := range beneficiary {
		beneficiaryRule = append(beneficiaryRule, beneficiaryItem)
	}
	var scheduleIdRule []interface{}
	for _, scheduleIdItem := range scheduleId {
		scheduleIdRule = append(scheduleIdRule, scheduleIdItem)
	}

	logs, sub, err := _LilypadVesting.contract.WatchLogs(opts, "LilypadVesting__l2TokensReleased", beneficiaryRule, scheduleIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(LilypadVestingLilypadVestingL2TokensReleased)
				if err := _LilypadVesting.contract.UnpackLog(event, "LilypadVesting__l2TokensReleased", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseLilypadVestingL2TokensReleased is a log parse operation binding the contract event 0xbe3ba0dce66ef6b0edd30e152c58ccd66276e7fb061432341ddaf126661eef68.
//
// Solidity: event LilypadVesting__l2TokensReleased(address indexed beneficiary, uint256 indexed scheduleId, uint256 amount)
func (_LilypadVesting *LilypadVestingFilterer) ParseLilypadVestingL2TokensReleased(log types.Log) (*LilypadVestingLilypadVestingL2TokensReleased, error) {
	event := new(LilypadVestingLilypadVestingL2TokensReleased)
	if err := _LilypadVesting.contract.UnpackLog(event, "LilypadVesting__l2TokensReleased", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// LilypadVestingRoleAdminChangedIterator is returned from FilterRoleAdminChanged and is used to iterate over the raw logs and unpacked data for RoleAdminChanged events raised by the LilypadVesting contract.
type LilypadVestingRoleAdminChangedIterator struct {
	Event *LilypadVestingRoleAdminChanged // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *LilypadVestingRoleAdminChangedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(LilypadVestingRoleAdminChanged)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(LilypadVestingRoleAdminChanged)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *LilypadVestingRoleAdminChangedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *LilypadVestingRoleAdminChangedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// LilypadVestingRoleAdminChanged represents a RoleAdminChanged event raised by the LilypadVesting contract.
type LilypadVestingRoleAdminChanged struct {
	Role              [32]byte
	PreviousAdminRole [32]byte
	NewAdminRole      [32]byte
	Raw               types.Log // Blockchain specific contextual infos
}

// FilterRoleAdminChanged is a free log retrieval operation binding the contract event 0xbd79b86ffe0ab8e8776151514217cd7cacd52c909f66475c3af44e129f0b00ff.
//
// Solidity: event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole)
func (_LilypadVesting *LilypadVestingFilterer) FilterRoleAdminChanged(opts *bind.FilterOpts, role [][32]byte, previousAdminRole [][32]byte, newAdminRole [][32]byte) (*LilypadVestingRoleAdminChangedIterator, error) {

	var roleRule []interface{}
	for _, roleItem := range role {
		roleRule = append(roleRule, roleItem)
	}
	var previousAdminRoleRule []interface{}
	for _, previousAdminRoleItem := range previousAdminRole {
		previousAdminRoleRule = append(previousAdminRoleRule, previousAdminRoleItem)
	}
	var newAdminRoleRule []interface{}
	for _, newAdminRoleItem := range newAdminRole {
		newAdminRoleRule = append(newAdminRoleRule, newAdminRoleItem)
	}

	logs, sub, err := _LilypadVesting.contract.FilterLogs(opts, "RoleAdminChanged", roleRule, previousAdminRoleRule, newAdminRoleRule)
	if err != nil {
		return nil, err
	}
	return &LilypadVestingRoleAdminChangedIterator{contract: _LilypadVesting.contract, event: "RoleAdminChanged", logs: logs, sub: sub}, nil
}

// WatchRoleAdminChanged is a free log subscription operation binding the contract event 0xbd79b86ffe0ab8e8776151514217cd7cacd52c909f66475c3af44e129f0b00ff.
//
// Solidity: event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole)
func (_LilypadVesting *LilypadVestingFilterer) WatchRoleAdminChanged(opts *bind.WatchOpts, sink chan<- *LilypadVestingRoleAdminChanged, role [][32]byte, previousAdminRole [][32]byte, newAdminRole [][32]byte) (event.Subscription, error) {

	var roleRule []interface{}
	for _, roleItem := range role {
		roleRule = append(roleRule, roleItem)
	}
	var previousAdminRoleRule []interface{}
	for _, previousAdminRoleItem := range previousAdminRole {
		previousAdminRoleRule = append(previousAdminRoleRule, previousAdminRoleItem)
	}
	var newAdminRoleRule []interface{}
	for _, newAdminRoleItem := range newAdminRole {
		newAdminRoleRule = append(newAdminRoleRule, newAdminRoleItem)
	}

	logs, sub, err := _LilypadVesting.contract.WatchLogs(opts, "RoleAdminChanged", roleRule, previousAdminRoleRule, newAdminRoleRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(LilypadVestingRoleAdminChanged)
				if err := _LilypadVesting.contract.UnpackLog(event, "RoleAdminChanged", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseRoleAdminChanged is a log parse operation binding the contract event 0xbd79b86ffe0ab8e8776151514217cd7cacd52c909f66475c3af44e129f0b00ff.
//
// Solidity: event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole)
func (_LilypadVesting *LilypadVestingFilterer) ParseRoleAdminChanged(log types.Log) (*LilypadVestingRoleAdminChanged, error) {
	event := new(LilypadVestingRoleAdminChanged)
	if err := _LilypadVesting.contract.UnpackLog(event, "RoleAdminChanged", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// LilypadVestingRoleGrantedIterator is returned from FilterRoleGranted and is used to iterate over the raw logs and unpacked data for RoleGranted events raised by the LilypadVesting contract.
type LilypadVestingRoleGrantedIterator struct {
	Event *LilypadVestingRoleGranted // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *LilypadVestingRoleGrantedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(LilypadVestingRoleGranted)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(LilypadVestingRoleGranted)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *LilypadVestingRoleGrantedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *LilypadVestingRoleGrantedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// LilypadVestingRoleGranted represents a RoleGranted event raised by the LilypadVesting contract.
type LilypadVestingRoleGranted struct {
	Role    [32]byte
	Account common.Address
	Sender  common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterRoleGranted is a free log retrieval operation binding the contract event 0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d.
//
// Solidity: event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)
func (_LilypadVesting *LilypadVestingFilterer) FilterRoleGranted(opts *bind.FilterOpts, role [][32]byte, account []common.Address, sender []common.Address) (*LilypadVestingRoleGrantedIterator, error) {

	var roleRule []interface{}
	for _, roleItem := range role {
		roleRule = append(roleRule, roleItem)
	}
	var accountRule []interface{}
	for _, accountItem := range account {
		accountRule = append(accountRule, accountItem)
	}
	var senderRule []interface{}
	for _, senderItem := range sender {
		senderRule = append(senderRule, senderItem)
	}

	logs, sub, err := _LilypadVesting.contract.FilterLogs(opts, "RoleGranted", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return &LilypadVestingRoleGrantedIterator{contract: _LilypadVesting.contract, event: "RoleGranted", logs: logs, sub: sub}, nil
}

// WatchRoleGranted is a free log subscription operation binding the contract event 0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d.
//
// Solidity: event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)
func (_LilypadVesting *LilypadVestingFilterer) WatchRoleGranted(opts *bind.WatchOpts, sink chan<- *LilypadVestingRoleGranted, role [][32]byte, account []common.Address, sender []common.Address) (event.Subscription, error) {

	var roleRule []interface{}
	for _, roleItem := range role {
		roleRule = append(roleRule, roleItem)
	}
	var accountRule []interface{}
	for _, accountItem := range account {
		accountRule = append(accountRule, accountItem)
	}
	var senderRule []interface{}
	for _, senderItem := range sender {
		senderRule = append(senderRule, senderItem)
	}

	logs, sub, err := _LilypadVesting.contract.WatchLogs(opts, "RoleGranted", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(LilypadVestingRoleGranted)
				if err := _LilypadVesting.contract.UnpackLog(event, "RoleGranted", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseRoleGranted is a log parse operation binding the contract event 0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d.
//
// Solidity: event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)
func (_LilypadVesting *LilypadVestingFilterer) ParseRoleGranted(log types.Log) (*LilypadVestingRoleGranted, error) {
	event := new(LilypadVestingRoleGranted)
	if err := _LilypadVesting.contract.UnpackLog(event, "RoleGranted", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// LilypadVestingRoleRevokedIterator is returned from FilterRoleRevoked and is used to iterate over the raw logs and unpacked data for RoleRevoked events raised by the LilypadVesting contract.
type LilypadVestingRoleRevokedIterator struct {
	Event *LilypadVestingRoleRevoked // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *LilypadVestingRoleRevokedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(LilypadVestingRoleRevoked)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(LilypadVestingRoleRevoked)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *LilypadVestingRoleRevokedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *LilypadVestingRoleRevokedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// LilypadVestingRoleRevoked represents a RoleRevoked event raised by the LilypadVesting contract.
type LilypadVestingRoleRevoked struct {
	Role    [32]byte
	Account common.Address
	Sender  common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterRoleRevoked is a free log retrieval operation binding the contract event 0xf6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b.
//
// Solidity: event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender)
func (_LilypadVesting *LilypadVestingFilterer) FilterRoleRevoked(opts *bind.FilterOpts, role [][32]byte, account []common.Address, sender []common.Address) (*LilypadVestingRoleRevokedIterator, error) {

	var roleRule []interface{}
	for _, roleItem := range role {
		roleRule = append(roleRule, roleItem)
	}
	var accountRule []interface{}
	for _, accountItem := range account {
		accountRule = append(accountRule, accountItem)
	}
	var senderRule []interface{}
	for _, senderItem := range sender {
		senderRule = append(senderRule, senderItem)
	}

	logs, sub, err := _LilypadVesting.contract.FilterLogs(opts, "RoleRevoked", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return &LilypadVestingRoleRevokedIterator{contract: _LilypadVesting.contract, event: "RoleRevoked", logs: logs, sub: sub}, nil
}

// WatchRoleRevoked is a free log subscription operation binding the contract event 0xf6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b.
//
// Solidity: event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender)
func (_LilypadVesting *LilypadVestingFilterer) WatchRoleRevoked(opts *bind.WatchOpts, sink chan<- *LilypadVestingRoleRevoked, role [][32]byte, account []common.Address, sender []common.Address) (event.Subscription, error) {

	var roleRule []interface{}
	for _, roleItem := range role {
		roleRule = append(roleRule, roleItem)
	}
	var accountRule []interface{}
	for _, accountItem := range account {
		accountRule = append(accountRule, accountItem)
	}
	var senderRule []interface{}
	for _, senderItem := range sender {
		senderRule = append(senderRule, senderItem)
	}

	logs, sub, err := _LilypadVesting.contract.WatchLogs(opts, "RoleRevoked", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(LilypadVestingRoleRevoked)
				if err := _LilypadVesting.contract.UnpackLog(event, "RoleRevoked", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseRoleRevoked is a log parse operation binding the contract event 0xf6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b.
//
// Solidity: event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender)
func (_LilypadVesting *LilypadVestingFilterer) ParseRoleRevoked(log types.Log) (*LilypadVestingRoleRevoked, error) {
	event := new(LilypadVestingRoleRevoked)
	if err := _LilypadVesting.contract.UnpackLog(event, "RoleRevoked", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
