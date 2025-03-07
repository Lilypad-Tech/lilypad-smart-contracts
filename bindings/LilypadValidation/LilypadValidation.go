// Code generated - DO NOT EDIT.
// This file is a generated binding and any manual changes will be lost.

package lilypadvalidation

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

// SharedStructsDeal is an auto generated low-level Go binding around an user-defined struct.
type SharedStructsDeal struct {
	DealId           string
	JobCreator       common.Address
	ResourceProvider common.Address
	ModuleCreator    common.Address
	Solver           common.Address
	JobOfferCID      string
	ResourceOfferCID string
	Status           uint8
	Timestamp        *big.Int
	PaymentStructure SharedStructsDealPaymentStructure
}

// SharedStructsDealPaymentStructure is an auto generated low-level Go binding around an user-defined struct.
type SharedStructsDealPaymentStructure struct {
	JobCreatorSolverFee       *big.Int
	ResourceProviderSolverFee *big.Int
	NetworkCongestionFee      *big.Int
	ModuleCreatorFee          *big.Int
	PriceOfJobWithoutFees     *big.Int
}

// SharedStructsResult is an auto generated low-level Go binding around an user-defined struct.
type SharedStructsResult struct {
	ResultId  string
	DealId    string
	ResultCID string
	Status    uint8
	Timestamp *big.Int
}

// SharedStructsValidationResult is an auto generated low-level Go binding around an user-defined struct.
type SharedStructsValidationResult struct {
	ValidationResultId string
	ResultId           string
	ValidationCID      string
	Status             uint8
	Timestamp          *big.Int
	Validator          common.Address
}

// LilypadValidationMetaData contains all meta data concerning the LilypadValidation contract.
var LilypadValidationMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"constructor\",\"inputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"DEFAULT_ADMIN_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getRoleAdmin\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getValidators\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getVersion\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"grantRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"hasRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"initialize\",\"inputs\":[{\"name\":\"storageAddress\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"userAddress\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"lilypadStorage\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"contractILilypadStorage\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"lilypadUser\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"contractILilypadUser\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"processValidation\",\"inputs\":[{\"name\":\"validation\",\"type\":\"tuple\",\"internalType\":\"structSharedStructs.ValidationResult\",\"components\":[{\"name\":\"validationResultId\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"resultId\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"validationCID\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"status\",\"type\":\"uint8\",\"internalType\":\"enumSharedStructs.ValidationResultStatusEnum\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"validator\",\"type\":\"address\",\"internalType\":\"address\"}]}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"renounceRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"callerConfirmation\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"requestValidation\",\"inputs\":[{\"name\":\"deal\",\"type\":\"tuple\",\"internalType\":\"structSharedStructs.Deal\",\"components\":[{\"name\":\"dealId\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"jobCreator\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"resourceProvider\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"moduleCreator\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"solver\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"jobOfferCID\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"resourceOfferCID\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"status\",\"type\":\"uint8\",\"internalType\":\"enumSharedStructs.DealStatusEnum\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"paymentStructure\",\"type\":\"tuple\",\"internalType\":\"structSharedStructs.DealPaymentStructure\",\"components\":[{\"name\":\"jobCreatorSolverFee\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"resourceProviderSolverFee\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"networkCongestionFee\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"moduleCreatorFee\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"priceOfJobWithoutFees\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]}]},{\"name\":\"result\",\"type\":\"tuple\",\"internalType\":\"structSharedStructs.Result\",\"components\":[{\"name\":\"resultId\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"dealId\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"resultCID\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"status\",\"type\":\"uint8\",\"internalType\":\"enumSharedStructs.ResultStatusEnum\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"name\":\"validation\",\"type\":\"tuple\",\"internalType\":\"structSharedStructs.ValidationResult\",\"components\":[{\"name\":\"validationResultId\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"resultId\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"validationCID\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"status\",\"type\":\"uint8\",\"internalType\":\"enumSharedStructs.ValidationResultStatusEnum\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"validator\",\"type\":\"address\",\"internalType\":\"address\"}]}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"revokeRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"supportsInterface\",\"inputs\":[{\"name\":\"interfaceId\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"version\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"view\"},{\"type\":\"event\",\"name\":\"Initialized\",\"inputs\":[{\"name\":\"version\",\"type\":\"uint64\",\"indexed\":false,\"internalType\":\"uint64\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleAdminChanged\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"previousAdminRole\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"newAdminRole\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleGranted\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"sender\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleRevoked\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"sender\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"StorageContractSet\",\"inputs\":[{\"name\":\"storageContract\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"UserContractSet\",\"inputs\":[{\"name\":\"userContract\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ValidationProcessed\",\"inputs\":[{\"name\":\"validationResultId\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"},{\"name\":\"status\",\"type\":\"uint8\",\"indexed\":false,\"internalType\":\"enumSharedStructs.ValidationResultStatusEnum\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ValidationRequested\",\"inputs\":[{\"name\":\"dealId\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"},{\"name\":\"resultId\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"},{\"name\":\"jobCreator\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"AccessControlBadConfirmation\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"AccessControlUnauthorizedAccount\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"neededRole\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}]},{\"type\":\"error\",\"name\":\"InvalidInitialization\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"LilypadValidation__InvalidDeal\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"LilypadValidation__InvalidResult\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"LilypadValidation__InvalidValidation\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"LilypadValidation__NoValidatorsAvailable\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"LilypadValidation__NotValidator\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"LilypadValidation__ZeroAddressNotAllowed\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NotInitializing\",\"inputs\":[]}]",
}

// LilypadValidationABI is the input ABI used to generate the binding from.
// Deprecated: Use LilypadValidationMetaData.ABI instead.
var LilypadValidationABI = LilypadValidationMetaData.ABI

// LilypadValidation is an auto generated Go binding around an Ethereum contract.
type LilypadValidation struct {
	LilypadValidationCaller     // Read-only binding to the contract
	LilypadValidationTransactor // Write-only binding to the contract
	LilypadValidationFilterer   // Log filterer for contract events
}

// LilypadValidationCaller is an auto generated read-only Go binding around an Ethereum contract.
type LilypadValidationCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// LilypadValidationTransactor is an auto generated write-only Go binding around an Ethereum contract.
type LilypadValidationTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// LilypadValidationFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type LilypadValidationFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// LilypadValidationSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type LilypadValidationSession struct {
	Contract     *LilypadValidation // Generic contract binding to set the session for
	CallOpts     bind.CallOpts      // Call options to use throughout this session
	TransactOpts bind.TransactOpts  // Transaction auth options to use throughout this session
}

// LilypadValidationCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type LilypadValidationCallerSession struct {
	Contract *LilypadValidationCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts            // Call options to use throughout this session
}

// LilypadValidationTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type LilypadValidationTransactorSession struct {
	Contract     *LilypadValidationTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts            // Transaction auth options to use throughout this session
}

// LilypadValidationRaw is an auto generated low-level Go binding around an Ethereum contract.
type LilypadValidationRaw struct {
	Contract *LilypadValidation // Generic contract binding to access the raw methods on
}

// LilypadValidationCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type LilypadValidationCallerRaw struct {
	Contract *LilypadValidationCaller // Generic read-only contract binding to access the raw methods on
}

// LilypadValidationTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type LilypadValidationTransactorRaw struct {
	Contract *LilypadValidationTransactor // Generic write-only contract binding to access the raw methods on
}

// NewLilypadValidation creates a new instance of LilypadValidation, bound to a specific deployed contract.
func NewLilypadValidation(address common.Address, backend bind.ContractBackend) (*LilypadValidation, error) {
	contract, err := bindLilypadValidation(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &LilypadValidation{LilypadValidationCaller: LilypadValidationCaller{contract: contract}, LilypadValidationTransactor: LilypadValidationTransactor{contract: contract}, LilypadValidationFilterer: LilypadValidationFilterer{contract: contract}}, nil
}

// NewLilypadValidationCaller creates a new read-only instance of LilypadValidation, bound to a specific deployed contract.
func NewLilypadValidationCaller(address common.Address, caller bind.ContractCaller) (*LilypadValidationCaller, error) {
	contract, err := bindLilypadValidation(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &LilypadValidationCaller{contract: contract}, nil
}

// NewLilypadValidationTransactor creates a new write-only instance of LilypadValidation, bound to a specific deployed contract.
func NewLilypadValidationTransactor(address common.Address, transactor bind.ContractTransactor) (*LilypadValidationTransactor, error) {
	contract, err := bindLilypadValidation(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &LilypadValidationTransactor{contract: contract}, nil
}

// NewLilypadValidationFilterer creates a new log filterer instance of LilypadValidation, bound to a specific deployed contract.
func NewLilypadValidationFilterer(address common.Address, filterer bind.ContractFilterer) (*LilypadValidationFilterer, error) {
	contract, err := bindLilypadValidation(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &LilypadValidationFilterer{contract: contract}, nil
}

// bindLilypadValidation binds a generic wrapper to an already deployed contract.
func bindLilypadValidation(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := LilypadValidationMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_LilypadValidation *LilypadValidationRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _LilypadValidation.Contract.LilypadValidationCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_LilypadValidation *LilypadValidationRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _LilypadValidation.Contract.LilypadValidationTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_LilypadValidation *LilypadValidationRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _LilypadValidation.Contract.LilypadValidationTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_LilypadValidation *LilypadValidationCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _LilypadValidation.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_LilypadValidation *LilypadValidationTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _LilypadValidation.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_LilypadValidation *LilypadValidationTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _LilypadValidation.Contract.contract.Transact(opts, method, params...)
}

// DEFAULTADMINROLE is a free data retrieval call binding the contract method 0xa217fddf.
//
// Solidity: function DEFAULT_ADMIN_ROLE() view returns(bytes32)
func (_LilypadValidation *LilypadValidationCaller) DEFAULTADMINROLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _LilypadValidation.contract.Call(opts, &out, "DEFAULT_ADMIN_ROLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// DEFAULTADMINROLE is a free data retrieval call binding the contract method 0xa217fddf.
//
// Solidity: function DEFAULT_ADMIN_ROLE() view returns(bytes32)
func (_LilypadValidation *LilypadValidationSession) DEFAULTADMINROLE() ([32]byte, error) {
	return _LilypadValidation.Contract.DEFAULTADMINROLE(&_LilypadValidation.CallOpts)
}

// DEFAULTADMINROLE is a free data retrieval call binding the contract method 0xa217fddf.
//
// Solidity: function DEFAULT_ADMIN_ROLE() view returns(bytes32)
func (_LilypadValidation *LilypadValidationCallerSession) DEFAULTADMINROLE() ([32]byte, error) {
	return _LilypadValidation.Contract.DEFAULTADMINROLE(&_LilypadValidation.CallOpts)
}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 role) view returns(bytes32)
func (_LilypadValidation *LilypadValidationCaller) GetRoleAdmin(opts *bind.CallOpts, role [32]byte) ([32]byte, error) {
	var out []interface{}
	err := _LilypadValidation.contract.Call(opts, &out, "getRoleAdmin", role)

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 role) view returns(bytes32)
func (_LilypadValidation *LilypadValidationSession) GetRoleAdmin(role [32]byte) ([32]byte, error) {
	return _LilypadValidation.Contract.GetRoleAdmin(&_LilypadValidation.CallOpts, role)
}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 role) view returns(bytes32)
func (_LilypadValidation *LilypadValidationCallerSession) GetRoleAdmin(role [32]byte) ([32]byte, error) {
	return _LilypadValidation.Contract.GetRoleAdmin(&_LilypadValidation.CallOpts, role)
}

// GetValidators is a free data retrieval call binding the contract method 0xb7ab4db5.
//
// Solidity: function getValidators() view returns(address[])
func (_LilypadValidation *LilypadValidationCaller) GetValidators(opts *bind.CallOpts) ([]common.Address, error) {
	var out []interface{}
	err := _LilypadValidation.contract.Call(opts, &out, "getValidators")

	if err != nil {
		return *new([]common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new([]common.Address)).(*[]common.Address)

	return out0, err

}

// GetValidators is a free data retrieval call binding the contract method 0xb7ab4db5.
//
// Solidity: function getValidators() view returns(address[])
func (_LilypadValidation *LilypadValidationSession) GetValidators() ([]common.Address, error) {
	return _LilypadValidation.Contract.GetValidators(&_LilypadValidation.CallOpts)
}

// GetValidators is a free data retrieval call binding the contract method 0xb7ab4db5.
//
// Solidity: function getValidators() view returns(address[])
func (_LilypadValidation *LilypadValidationCallerSession) GetValidators() ([]common.Address, error) {
	return _LilypadValidation.Contract.GetValidators(&_LilypadValidation.CallOpts)
}

// GetVersion is a free data retrieval call binding the contract method 0x0d8e6e2c.
//
// Solidity: function getVersion() view returns(string)
func (_LilypadValidation *LilypadValidationCaller) GetVersion(opts *bind.CallOpts) (string, error) {
	var out []interface{}
	err := _LilypadValidation.contract.Call(opts, &out, "getVersion")

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// GetVersion is a free data retrieval call binding the contract method 0x0d8e6e2c.
//
// Solidity: function getVersion() view returns(string)
func (_LilypadValidation *LilypadValidationSession) GetVersion() (string, error) {
	return _LilypadValidation.Contract.GetVersion(&_LilypadValidation.CallOpts)
}

// GetVersion is a free data retrieval call binding the contract method 0x0d8e6e2c.
//
// Solidity: function getVersion() view returns(string)
func (_LilypadValidation *LilypadValidationCallerSession) GetVersion() (string, error) {
	return _LilypadValidation.Contract.GetVersion(&_LilypadValidation.CallOpts)
}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 role, address account) view returns(bool)
func (_LilypadValidation *LilypadValidationCaller) HasRole(opts *bind.CallOpts, role [32]byte, account common.Address) (bool, error) {
	var out []interface{}
	err := _LilypadValidation.contract.Call(opts, &out, "hasRole", role, account)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 role, address account) view returns(bool)
func (_LilypadValidation *LilypadValidationSession) HasRole(role [32]byte, account common.Address) (bool, error) {
	return _LilypadValidation.Contract.HasRole(&_LilypadValidation.CallOpts, role, account)
}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 role, address account) view returns(bool)
func (_LilypadValidation *LilypadValidationCallerSession) HasRole(role [32]byte, account common.Address) (bool, error) {
	return _LilypadValidation.Contract.HasRole(&_LilypadValidation.CallOpts, role, account)
}

// LilypadStorage is a free data retrieval call binding the contract method 0x053f9ed9.
//
// Solidity: function lilypadStorage() view returns(address)
func (_LilypadValidation *LilypadValidationCaller) LilypadStorage(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _LilypadValidation.contract.Call(opts, &out, "lilypadStorage")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// LilypadStorage is a free data retrieval call binding the contract method 0x053f9ed9.
//
// Solidity: function lilypadStorage() view returns(address)
func (_LilypadValidation *LilypadValidationSession) LilypadStorage() (common.Address, error) {
	return _LilypadValidation.Contract.LilypadStorage(&_LilypadValidation.CallOpts)
}

// LilypadStorage is a free data retrieval call binding the contract method 0x053f9ed9.
//
// Solidity: function lilypadStorage() view returns(address)
func (_LilypadValidation *LilypadValidationCallerSession) LilypadStorage() (common.Address, error) {
	return _LilypadValidation.Contract.LilypadStorage(&_LilypadValidation.CallOpts)
}

// LilypadUser is a free data retrieval call binding the contract method 0xb5b2544d.
//
// Solidity: function lilypadUser() view returns(address)
func (_LilypadValidation *LilypadValidationCaller) LilypadUser(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _LilypadValidation.contract.Call(opts, &out, "lilypadUser")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// LilypadUser is a free data retrieval call binding the contract method 0xb5b2544d.
//
// Solidity: function lilypadUser() view returns(address)
func (_LilypadValidation *LilypadValidationSession) LilypadUser() (common.Address, error) {
	return _LilypadValidation.Contract.LilypadUser(&_LilypadValidation.CallOpts)
}

// LilypadUser is a free data retrieval call binding the contract method 0xb5b2544d.
//
// Solidity: function lilypadUser() view returns(address)
func (_LilypadValidation *LilypadValidationCallerSession) LilypadUser() (common.Address, error) {
	return _LilypadValidation.Contract.LilypadUser(&_LilypadValidation.CallOpts)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_LilypadValidation *LilypadValidationCaller) SupportsInterface(opts *bind.CallOpts, interfaceId [4]byte) (bool, error) {
	var out []interface{}
	err := _LilypadValidation.contract.Call(opts, &out, "supportsInterface", interfaceId)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_LilypadValidation *LilypadValidationSession) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _LilypadValidation.Contract.SupportsInterface(&_LilypadValidation.CallOpts, interfaceId)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_LilypadValidation *LilypadValidationCallerSession) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _LilypadValidation.Contract.SupportsInterface(&_LilypadValidation.CallOpts, interfaceId)
}

// Version is a free data retrieval call binding the contract method 0x54fd4d50.
//
// Solidity: function version() view returns(string)
func (_LilypadValidation *LilypadValidationCaller) Version(opts *bind.CallOpts) (string, error) {
	var out []interface{}
	err := _LilypadValidation.contract.Call(opts, &out, "version")

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// Version is a free data retrieval call binding the contract method 0x54fd4d50.
//
// Solidity: function version() view returns(string)
func (_LilypadValidation *LilypadValidationSession) Version() (string, error) {
	return _LilypadValidation.Contract.Version(&_LilypadValidation.CallOpts)
}

// Version is a free data retrieval call binding the contract method 0x54fd4d50.
//
// Solidity: function version() view returns(string)
func (_LilypadValidation *LilypadValidationCallerSession) Version() (string, error) {
	return _LilypadValidation.Contract.Version(&_LilypadValidation.CallOpts)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_LilypadValidation *LilypadValidationTransactor) GrantRole(opts *bind.TransactOpts, role [32]byte, account common.Address) (*types.Transaction, error) {
	return _LilypadValidation.contract.Transact(opts, "grantRole", role, account)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_LilypadValidation *LilypadValidationSession) GrantRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _LilypadValidation.Contract.GrantRole(&_LilypadValidation.TransactOpts, role, account)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_LilypadValidation *LilypadValidationTransactorSession) GrantRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _LilypadValidation.Contract.GrantRole(&_LilypadValidation.TransactOpts, role, account)
}

// Initialize is a paid mutator transaction binding the contract method 0x485cc955.
//
// Solidity: function initialize(address storageAddress, address userAddress) returns()
func (_LilypadValidation *LilypadValidationTransactor) Initialize(opts *bind.TransactOpts, storageAddress common.Address, userAddress common.Address) (*types.Transaction, error) {
	return _LilypadValidation.contract.Transact(opts, "initialize", storageAddress, userAddress)
}

// Initialize is a paid mutator transaction binding the contract method 0x485cc955.
//
// Solidity: function initialize(address storageAddress, address userAddress) returns()
func (_LilypadValidation *LilypadValidationSession) Initialize(storageAddress common.Address, userAddress common.Address) (*types.Transaction, error) {
	return _LilypadValidation.Contract.Initialize(&_LilypadValidation.TransactOpts, storageAddress, userAddress)
}

// Initialize is a paid mutator transaction binding the contract method 0x485cc955.
//
// Solidity: function initialize(address storageAddress, address userAddress) returns()
func (_LilypadValidation *LilypadValidationTransactorSession) Initialize(storageAddress common.Address, userAddress common.Address) (*types.Transaction, error) {
	return _LilypadValidation.Contract.Initialize(&_LilypadValidation.TransactOpts, storageAddress, userAddress)
}

// ProcessValidation is a paid mutator transaction binding the contract method 0xb1dfa199.
//
// Solidity: function processValidation((string,string,string,uint8,uint256,address) validation) returns(bool)
func (_LilypadValidation *LilypadValidationTransactor) ProcessValidation(opts *bind.TransactOpts, validation SharedStructsValidationResult) (*types.Transaction, error) {
	return _LilypadValidation.contract.Transact(opts, "processValidation", validation)
}

// ProcessValidation is a paid mutator transaction binding the contract method 0xb1dfa199.
//
// Solidity: function processValidation((string,string,string,uint8,uint256,address) validation) returns(bool)
func (_LilypadValidation *LilypadValidationSession) ProcessValidation(validation SharedStructsValidationResult) (*types.Transaction, error) {
	return _LilypadValidation.Contract.ProcessValidation(&_LilypadValidation.TransactOpts, validation)
}

// ProcessValidation is a paid mutator transaction binding the contract method 0xb1dfa199.
//
// Solidity: function processValidation((string,string,string,uint8,uint256,address) validation) returns(bool)
func (_LilypadValidation *LilypadValidationTransactorSession) ProcessValidation(validation SharedStructsValidationResult) (*types.Transaction, error) {
	return _LilypadValidation.Contract.ProcessValidation(&_LilypadValidation.TransactOpts, validation)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address callerConfirmation) returns()
func (_LilypadValidation *LilypadValidationTransactor) RenounceRole(opts *bind.TransactOpts, role [32]byte, callerConfirmation common.Address) (*types.Transaction, error) {
	return _LilypadValidation.contract.Transact(opts, "renounceRole", role, callerConfirmation)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address callerConfirmation) returns()
func (_LilypadValidation *LilypadValidationSession) RenounceRole(role [32]byte, callerConfirmation common.Address) (*types.Transaction, error) {
	return _LilypadValidation.Contract.RenounceRole(&_LilypadValidation.TransactOpts, role, callerConfirmation)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address callerConfirmation) returns()
func (_LilypadValidation *LilypadValidationTransactorSession) RenounceRole(role [32]byte, callerConfirmation common.Address) (*types.Transaction, error) {
	return _LilypadValidation.Contract.RenounceRole(&_LilypadValidation.TransactOpts, role, callerConfirmation)
}

// RequestValidation is a paid mutator transaction binding the contract method 0x5c160b39.
//
// Solidity: function requestValidation((string,address,address,address,address,string,string,uint8,uint256,(uint256,uint256,uint256,uint256,uint256)) deal, (string,string,string,uint8,uint256) result, (string,string,string,uint8,uint256,address) validation) returns(bool)
func (_LilypadValidation *LilypadValidationTransactor) RequestValidation(opts *bind.TransactOpts, deal SharedStructsDeal, result SharedStructsResult, validation SharedStructsValidationResult) (*types.Transaction, error) {
	return _LilypadValidation.contract.Transact(opts, "requestValidation", deal, result, validation)
}

// RequestValidation is a paid mutator transaction binding the contract method 0x5c160b39.
//
// Solidity: function requestValidation((string,address,address,address,address,string,string,uint8,uint256,(uint256,uint256,uint256,uint256,uint256)) deal, (string,string,string,uint8,uint256) result, (string,string,string,uint8,uint256,address) validation) returns(bool)
func (_LilypadValidation *LilypadValidationSession) RequestValidation(deal SharedStructsDeal, result SharedStructsResult, validation SharedStructsValidationResult) (*types.Transaction, error) {
	return _LilypadValidation.Contract.RequestValidation(&_LilypadValidation.TransactOpts, deal, result, validation)
}

// RequestValidation is a paid mutator transaction binding the contract method 0x5c160b39.
//
// Solidity: function requestValidation((string,address,address,address,address,string,string,uint8,uint256,(uint256,uint256,uint256,uint256,uint256)) deal, (string,string,string,uint8,uint256) result, (string,string,string,uint8,uint256,address) validation) returns(bool)
func (_LilypadValidation *LilypadValidationTransactorSession) RequestValidation(deal SharedStructsDeal, result SharedStructsResult, validation SharedStructsValidationResult) (*types.Transaction, error) {
	return _LilypadValidation.Contract.RequestValidation(&_LilypadValidation.TransactOpts, deal, result, validation)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_LilypadValidation *LilypadValidationTransactor) RevokeRole(opts *bind.TransactOpts, role [32]byte, account common.Address) (*types.Transaction, error) {
	return _LilypadValidation.contract.Transact(opts, "revokeRole", role, account)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_LilypadValidation *LilypadValidationSession) RevokeRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _LilypadValidation.Contract.RevokeRole(&_LilypadValidation.TransactOpts, role, account)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_LilypadValidation *LilypadValidationTransactorSession) RevokeRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _LilypadValidation.Contract.RevokeRole(&_LilypadValidation.TransactOpts, role, account)
}

// LilypadValidationInitializedIterator is returned from FilterInitialized and is used to iterate over the raw logs and unpacked data for Initialized events raised by the LilypadValidation contract.
type LilypadValidationInitializedIterator struct {
	Event *LilypadValidationInitialized // Event containing the contract specifics and raw log

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
func (it *LilypadValidationInitializedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(LilypadValidationInitialized)
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
		it.Event = new(LilypadValidationInitialized)
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
func (it *LilypadValidationInitializedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *LilypadValidationInitializedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// LilypadValidationInitialized represents a Initialized event raised by the LilypadValidation contract.
type LilypadValidationInitialized struct {
	Version uint64
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterInitialized is a free log retrieval operation binding the contract event 0xc7f505b2f371ae2175ee4913f4499e1f2633a7b5936321eed1cdaeb6115181d2.
//
// Solidity: event Initialized(uint64 version)
func (_LilypadValidation *LilypadValidationFilterer) FilterInitialized(opts *bind.FilterOpts) (*LilypadValidationInitializedIterator, error) {

	logs, sub, err := _LilypadValidation.contract.FilterLogs(opts, "Initialized")
	if err != nil {
		return nil, err
	}
	return &LilypadValidationInitializedIterator{contract: _LilypadValidation.contract, event: "Initialized", logs: logs, sub: sub}, nil
}

// WatchInitialized is a free log subscription operation binding the contract event 0xc7f505b2f371ae2175ee4913f4499e1f2633a7b5936321eed1cdaeb6115181d2.
//
// Solidity: event Initialized(uint64 version)
func (_LilypadValidation *LilypadValidationFilterer) WatchInitialized(opts *bind.WatchOpts, sink chan<- *LilypadValidationInitialized) (event.Subscription, error) {

	logs, sub, err := _LilypadValidation.contract.WatchLogs(opts, "Initialized")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(LilypadValidationInitialized)
				if err := _LilypadValidation.contract.UnpackLog(event, "Initialized", log); err != nil {
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

// ParseInitialized is a log parse operation binding the contract event 0xc7f505b2f371ae2175ee4913f4499e1f2633a7b5936321eed1cdaeb6115181d2.
//
// Solidity: event Initialized(uint64 version)
func (_LilypadValidation *LilypadValidationFilterer) ParseInitialized(log types.Log) (*LilypadValidationInitialized, error) {
	event := new(LilypadValidationInitialized)
	if err := _LilypadValidation.contract.UnpackLog(event, "Initialized", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// LilypadValidationRoleAdminChangedIterator is returned from FilterRoleAdminChanged and is used to iterate over the raw logs and unpacked data for RoleAdminChanged events raised by the LilypadValidation contract.
type LilypadValidationRoleAdminChangedIterator struct {
	Event *LilypadValidationRoleAdminChanged // Event containing the contract specifics and raw log

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
func (it *LilypadValidationRoleAdminChangedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(LilypadValidationRoleAdminChanged)
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
		it.Event = new(LilypadValidationRoleAdminChanged)
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
func (it *LilypadValidationRoleAdminChangedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *LilypadValidationRoleAdminChangedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// LilypadValidationRoleAdminChanged represents a RoleAdminChanged event raised by the LilypadValidation contract.
type LilypadValidationRoleAdminChanged struct {
	Role              [32]byte
	PreviousAdminRole [32]byte
	NewAdminRole      [32]byte
	Raw               types.Log // Blockchain specific contextual infos
}

// FilterRoleAdminChanged is a free log retrieval operation binding the contract event 0xbd79b86ffe0ab8e8776151514217cd7cacd52c909f66475c3af44e129f0b00ff.
//
// Solidity: event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole)
func (_LilypadValidation *LilypadValidationFilterer) FilterRoleAdminChanged(opts *bind.FilterOpts, role [][32]byte, previousAdminRole [][32]byte, newAdminRole [][32]byte) (*LilypadValidationRoleAdminChangedIterator, error) {

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

	logs, sub, err := _LilypadValidation.contract.FilterLogs(opts, "RoleAdminChanged", roleRule, previousAdminRoleRule, newAdminRoleRule)
	if err != nil {
		return nil, err
	}
	return &LilypadValidationRoleAdminChangedIterator{contract: _LilypadValidation.contract, event: "RoleAdminChanged", logs: logs, sub: sub}, nil
}

// WatchRoleAdminChanged is a free log subscription operation binding the contract event 0xbd79b86ffe0ab8e8776151514217cd7cacd52c909f66475c3af44e129f0b00ff.
//
// Solidity: event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole)
func (_LilypadValidation *LilypadValidationFilterer) WatchRoleAdminChanged(opts *bind.WatchOpts, sink chan<- *LilypadValidationRoleAdminChanged, role [][32]byte, previousAdminRole [][32]byte, newAdminRole [][32]byte) (event.Subscription, error) {

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

	logs, sub, err := _LilypadValidation.contract.WatchLogs(opts, "RoleAdminChanged", roleRule, previousAdminRoleRule, newAdminRoleRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(LilypadValidationRoleAdminChanged)
				if err := _LilypadValidation.contract.UnpackLog(event, "RoleAdminChanged", log); err != nil {
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
func (_LilypadValidation *LilypadValidationFilterer) ParseRoleAdminChanged(log types.Log) (*LilypadValidationRoleAdminChanged, error) {
	event := new(LilypadValidationRoleAdminChanged)
	if err := _LilypadValidation.contract.UnpackLog(event, "RoleAdminChanged", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// LilypadValidationRoleGrantedIterator is returned from FilterRoleGranted and is used to iterate over the raw logs and unpacked data for RoleGranted events raised by the LilypadValidation contract.
type LilypadValidationRoleGrantedIterator struct {
	Event *LilypadValidationRoleGranted // Event containing the contract specifics and raw log

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
func (it *LilypadValidationRoleGrantedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(LilypadValidationRoleGranted)
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
		it.Event = new(LilypadValidationRoleGranted)
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
func (it *LilypadValidationRoleGrantedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *LilypadValidationRoleGrantedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// LilypadValidationRoleGranted represents a RoleGranted event raised by the LilypadValidation contract.
type LilypadValidationRoleGranted struct {
	Role    [32]byte
	Account common.Address
	Sender  common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterRoleGranted is a free log retrieval operation binding the contract event 0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d.
//
// Solidity: event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)
func (_LilypadValidation *LilypadValidationFilterer) FilterRoleGranted(opts *bind.FilterOpts, role [][32]byte, account []common.Address, sender []common.Address) (*LilypadValidationRoleGrantedIterator, error) {

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

	logs, sub, err := _LilypadValidation.contract.FilterLogs(opts, "RoleGranted", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return &LilypadValidationRoleGrantedIterator{contract: _LilypadValidation.contract, event: "RoleGranted", logs: logs, sub: sub}, nil
}

// WatchRoleGranted is a free log subscription operation binding the contract event 0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d.
//
// Solidity: event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)
func (_LilypadValidation *LilypadValidationFilterer) WatchRoleGranted(opts *bind.WatchOpts, sink chan<- *LilypadValidationRoleGranted, role [][32]byte, account []common.Address, sender []common.Address) (event.Subscription, error) {

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

	logs, sub, err := _LilypadValidation.contract.WatchLogs(opts, "RoleGranted", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(LilypadValidationRoleGranted)
				if err := _LilypadValidation.contract.UnpackLog(event, "RoleGranted", log); err != nil {
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
func (_LilypadValidation *LilypadValidationFilterer) ParseRoleGranted(log types.Log) (*LilypadValidationRoleGranted, error) {
	event := new(LilypadValidationRoleGranted)
	if err := _LilypadValidation.contract.UnpackLog(event, "RoleGranted", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// LilypadValidationRoleRevokedIterator is returned from FilterRoleRevoked and is used to iterate over the raw logs and unpacked data for RoleRevoked events raised by the LilypadValidation contract.
type LilypadValidationRoleRevokedIterator struct {
	Event *LilypadValidationRoleRevoked // Event containing the contract specifics and raw log

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
func (it *LilypadValidationRoleRevokedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(LilypadValidationRoleRevoked)
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
		it.Event = new(LilypadValidationRoleRevoked)
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
func (it *LilypadValidationRoleRevokedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *LilypadValidationRoleRevokedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// LilypadValidationRoleRevoked represents a RoleRevoked event raised by the LilypadValidation contract.
type LilypadValidationRoleRevoked struct {
	Role    [32]byte
	Account common.Address
	Sender  common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterRoleRevoked is a free log retrieval operation binding the contract event 0xf6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b.
//
// Solidity: event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender)
func (_LilypadValidation *LilypadValidationFilterer) FilterRoleRevoked(opts *bind.FilterOpts, role [][32]byte, account []common.Address, sender []common.Address) (*LilypadValidationRoleRevokedIterator, error) {

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

	logs, sub, err := _LilypadValidation.contract.FilterLogs(opts, "RoleRevoked", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return &LilypadValidationRoleRevokedIterator{contract: _LilypadValidation.contract, event: "RoleRevoked", logs: logs, sub: sub}, nil
}

// WatchRoleRevoked is a free log subscription operation binding the contract event 0xf6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b.
//
// Solidity: event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender)
func (_LilypadValidation *LilypadValidationFilterer) WatchRoleRevoked(opts *bind.WatchOpts, sink chan<- *LilypadValidationRoleRevoked, role [][32]byte, account []common.Address, sender []common.Address) (event.Subscription, error) {

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

	logs, sub, err := _LilypadValidation.contract.WatchLogs(opts, "RoleRevoked", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(LilypadValidationRoleRevoked)
				if err := _LilypadValidation.contract.UnpackLog(event, "RoleRevoked", log); err != nil {
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
func (_LilypadValidation *LilypadValidationFilterer) ParseRoleRevoked(log types.Log) (*LilypadValidationRoleRevoked, error) {
	event := new(LilypadValidationRoleRevoked)
	if err := _LilypadValidation.contract.UnpackLog(event, "RoleRevoked", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// LilypadValidationStorageContractSetIterator is returned from FilterStorageContractSet and is used to iterate over the raw logs and unpacked data for StorageContractSet events raised by the LilypadValidation contract.
type LilypadValidationStorageContractSetIterator struct {
	Event *LilypadValidationStorageContractSet // Event containing the contract specifics and raw log

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
func (it *LilypadValidationStorageContractSetIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(LilypadValidationStorageContractSet)
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
		it.Event = new(LilypadValidationStorageContractSet)
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
func (it *LilypadValidationStorageContractSetIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *LilypadValidationStorageContractSetIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// LilypadValidationStorageContractSet represents a StorageContractSet event raised by the LilypadValidation contract.
type LilypadValidationStorageContractSet struct {
	StorageContract common.Address
	Raw             types.Log // Blockchain specific contextual infos
}

// FilterStorageContractSet is a free log retrieval operation binding the contract event 0x7f34aa6a28b169a0ffd4b956a2afe20f56fbe53ce4c87a24e3b97e400b694895.
//
// Solidity: event StorageContractSet(address storageContract)
func (_LilypadValidation *LilypadValidationFilterer) FilterStorageContractSet(opts *bind.FilterOpts) (*LilypadValidationStorageContractSetIterator, error) {

	logs, sub, err := _LilypadValidation.contract.FilterLogs(opts, "StorageContractSet")
	if err != nil {
		return nil, err
	}
	return &LilypadValidationStorageContractSetIterator{contract: _LilypadValidation.contract, event: "StorageContractSet", logs: logs, sub: sub}, nil
}

// WatchStorageContractSet is a free log subscription operation binding the contract event 0x7f34aa6a28b169a0ffd4b956a2afe20f56fbe53ce4c87a24e3b97e400b694895.
//
// Solidity: event StorageContractSet(address storageContract)
func (_LilypadValidation *LilypadValidationFilterer) WatchStorageContractSet(opts *bind.WatchOpts, sink chan<- *LilypadValidationStorageContractSet) (event.Subscription, error) {

	logs, sub, err := _LilypadValidation.contract.WatchLogs(opts, "StorageContractSet")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(LilypadValidationStorageContractSet)
				if err := _LilypadValidation.contract.UnpackLog(event, "StorageContractSet", log); err != nil {
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

// ParseStorageContractSet is a log parse operation binding the contract event 0x7f34aa6a28b169a0ffd4b956a2afe20f56fbe53ce4c87a24e3b97e400b694895.
//
// Solidity: event StorageContractSet(address storageContract)
func (_LilypadValidation *LilypadValidationFilterer) ParseStorageContractSet(log types.Log) (*LilypadValidationStorageContractSet, error) {
	event := new(LilypadValidationStorageContractSet)
	if err := _LilypadValidation.contract.UnpackLog(event, "StorageContractSet", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// LilypadValidationUserContractSetIterator is returned from FilterUserContractSet and is used to iterate over the raw logs and unpacked data for UserContractSet events raised by the LilypadValidation contract.
type LilypadValidationUserContractSetIterator struct {
	Event *LilypadValidationUserContractSet // Event containing the contract specifics and raw log

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
func (it *LilypadValidationUserContractSetIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(LilypadValidationUserContractSet)
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
		it.Event = new(LilypadValidationUserContractSet)
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
func (it *LilypadValidationUserContractSetIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *LilypadValidationUserContractSetIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// LilypadValidationUserContractSet represents a UserContractSet event raised by the LilypadValidation contract.
type LilypadValidationUserContractSet struct {
	UserContract common.Address
	Raw          types.Log // Blockchain specific contextual infos
}

// FilterUserContractSet is a free log retrieval operation binding the contract event 0x254f262860309f72631283f2dc1074165bea5a1f6281215f1dc70a334beff688.
//
// Solidity: event UserContractSet(address userContract)
func (_LilypadValidation *LilypadValidationFilterer) FilterUserContractSet(opts *bind.FilterOpts) (*LilypadValidationUserContractSetIterator, error) {

	logs, sub, err := _LilypadValidation.contract.FilterLogs(opts, "UserContractSet")
	if err != nil {
		return nil, err
	}
	return &LilypadValidationUserContractSetIterator{contract: _LilypadValidation.contract, event: "UserContractSet", logs: logs, sub: sub}, nil
}

// WatchUserContractSet is a free log subscription operation binding the contract event 0x254f262860309f72631283f2dc1074165bea5a1f6281215f1dc70a334beff688.
//
// Solidity: event UserContractSet(address userContract)
func (_LilypadValidation *LilypadValidationFilterer) WatchUserContractSet(opts *bind.WatchOpts, sink chan<- *LilypadValidationUserContractSet) (event.Subscription, error) {

	logs, sub, err := _LilypadValidation.contract.WatchLogs(opts, "UserContractSet")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(LilypadValidationUserContractSet)
				if err := _LilypadValidation.contract.UnpackLog(event, "UserContractSet", log); err != nil {
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

// ParseUserContractSet is a log parse operation binding the contract event 0x254f262860309f72631283f2dc1074165bea5a1f6281215f1dc70a334beff688.
//
// Solidity: event UserContractSet(address userContract)
func (_LilypadValidation *LilypadValidationFilterer) ParseUserContractSet(log types.Log) (*LilypadValidationUserContractSet, error) {
	event := new(LilypadValidationUserContractSet)
	if err := _LilypadValidation.contract.UnpackLog(event, "UserContractSet", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// LilypadValidationValidationProcessedIterator is returned from FilterValidationProcessed and is used to iterate over the raw logs and unpacked data for ValidationProcessed events raised by the LilypadValidation contract.
type LilypadValidationValidationProcessedIterator struct {
	Event *LilypadValidationValidationProcessed // Event containing the contract specifics and raw log

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
func (it *LilypadValidationValidationProcessedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(LilypadValidationValidationProcessed)
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
		it.Event = new(LilypadValidationValidationProcessed)
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
func (it *LilypadValidationValidationProcessedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *LilypadValidationValidationProcessedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// LilypadValidationValidationProcessed represents a ValidationProcessed event raised by the LilypadValidation contract.
type LilypadValidationValidationProcessed struct {
	ValidationResultId string
	Status             uint8
	Raw                types.Log // Blockchain specific contextual infos
}

// FilterValidationProcessed is a free log retrieval operation binding the contract event 0xc15d91b9a2840c414b0c6839386846b7db83d00300505b80daefa661c7830d17.
//
// Solidity: event ValidationProcessed(string validationResultId, uint8 status)
func (_LilypadValidation *LilypadValidationFilterer) FilterValidationProcessed(opts *bind.FilterOpts) (*LilypadValidationValidationProcessedIterator, error) {

	logs, sub, err := _LilypadValidation.contract.FilterLogs(opts, "ValidationProcessed")
	if err != nil {
		return nil, err
	}
	return &LilypadValidationValidationProcessedIterator{contract: _LilypadValidation.contract, event: "ValidationProcessed", logs: logs, sub: sub}, nil
}

// WatchValidationProcessed is a free log subscription operation binding the contract event 0xc15d91b9a2840c414b0c6839386846b7db83d00300505b80daefa661c7830d17.
//
// Solidity: event ValidationProcessed(string validationResultId, uint8 status)
func (_LilypadValidation *LilypadValidationFilterer) WatchValidationProcessed(opts *bind.WatchOpts, sink chan<- *LilypadValidationValidationProcessed) (event.Subscription, error) {

	logs, sub, err := _LilypadValidation.contract.WatchLogs(opts, "ValidationProcessed")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(LilypadValidationValidationProcessed)
				if err := _LilypadValidation.contract.UnpackLog(event, "ValidationProcessed", log); err != nil {
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

// ParseValidationProcessed is a log parse operation binding the contract event 0xc15d91b9a2840c414b0c6839386846b7db83d00300505b80daefa661c7830d17.
//
// Solidity: event ValidationProcessed(string validationResultId, uint8 status)
func (_LilypadValidation *LilypadValidationFilterer) ParseValidationProcessed(log types.Log) (*LilypadValidationValidationProcessed, error) {
	event := new(LilypadValidationValidationProcessed)
	if err := _LilypadValidation.contract.UnpackLog(event, "ValidationProcessed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// LilypadValidationValidationRequestedIterator is returned from FilterValidationRequested and is used to iterate over the raw logs and unpacked data for ValidationRequested events raised by the LilypadValidation contract.
type LilypadValidationValidationRequestedIterator struct {
	Event *LilypadValidationValidationRequested // Event containing the contract specifics and raw log

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
func (it *LilypadValidationValidationRequestedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(LilypadValidationValidationRequested)
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
		it.Event = new(LilypadValidationValidationRequested)
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
func (it *LilypadValidationValidationRequestedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *LilypadValidationValidationRequestedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// LilypadValidationValidationRequested represents a ValidationRequested event raised by the LilypadValidation contract.
type LilypadValidationValidationRequested struct {
	DealId     string
	ResultId   string
	JobCreator common.Address
	Raw        types.Log // Blockchain specific contextual infos
}

// FilterValidationRequested is a free log retrieval operation binding the contract event 0x8244b9979ad52cc5adb5d45ae32337429ea6ae10a0ddb87c99335d54d2714555.
//
// Solidity: event ValidationRequested(string dealId, string resultId, address jobCreator)
func (_LilypadValidation *LilypadValidationFilterer) FilterValidationRequested(opts *bind.FilterOpts) (*LilypadValidationValidationRequestedIterator, error) {

	logs, sub, err := _LilypadValidation.contract.FilterLogs(opts, "ValidationRequested")
	if err != nil {
		return nil, err
	}
	return &LilypadValidationValidationRequestedIterator{contract: _LilypadValidation.contract, event: "ValidationRequested", logs: logs, sub: sub}, nil
}

// WatchValidationRequested is a free log subscription operation binding the contract event 0x8244b9979ad52cc5adb5d45ae32337429ea6ae10a0ddb87c99335d54d2714555.
//
// Solidity: event ValidationRequested(string dealId, string resultId, address jobCreator)
func (_LilypadValidation *LilypadValidationFilterer) WatchValidationRequested(opts *bind.WatchOpts, sink chan<- *LilypadValidationValidationRequested) (event.Subscription, error) {

	logs, sub, err := _LilypadValidation.contract.WatchLogs(opts, "ValidationRequested")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(LilypadValidationValidationRequested)
				if err := _LilypadValidation.contract.UnpackLog(event, "ValidationRequested", log); err != nil {
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

// ParseValidationRequested is a log parse operation binding the contract event 0x8244b9979ad52cc5adb5d45ae32337429ea6ae10a0ddb87c99335d54d2714555.
//
// Solidity: event ValidationRequested(string dealId, string resultId, address jobCreator)
func (_LilypadValidation *LilypadValidationFilterer) ParseValidationRequested(log types.Log) (*LilypadValidationValidationRequested, error) {
	event := new(LilypadValidationValidationRequested)
	if err := _LilypadValidation.contract.UnpackLog(event, "ValidationRequested", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
