// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

library SharedStructs {
    enum UserType {
        Solver,
        Validator,
        ModuleCreator,
        ResourceProvider,
        JobCreator,
        Admin
    }

    enum DealStatusEnum {
        DealAgreed,
        DealCompleted
    }

    enum ResultStatusEnum {
        ResultsAccepted,
        ResultsRejected
    }

    enum ValidationResultStatusEnum {
        ValidationPending,
        ValidationAccepted,
        ValidationRejected
    }

    bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");

    // we map addresses onto infomation about the user
    struct User {
        address userAddress;
        // the decentralized identifier for the user's metadata (e.g. CID)
        string metadataID;
        // the url of the user's metadata
        string url;
    }
    // // the roles of the user
    // UserType[] roles;

    struct Deal {
        string dealId;
        address jobCreator;
        address resourceProvider;
        string jobOfferCID;
        string resourceOfferCID;
        DealStatusEnum status;
        uint256 timestamp;
    }

    struct Result {
        string resultId;
        string dealId;
        string resultCID;
        ResultStatusEnum status;
        uint256 timestamp;
    }

    struct ValidationResult {
        string validationResultId;
        string resultId;
        string validationCID;
        ValidationResultStatusEnum status;
        uint256 timestamp;
        address validator;
    }

    struct Module {
        address moduleOwner;
        string moduleName;
        string moduleUrl;
    }
}
