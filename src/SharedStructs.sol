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

    enum PaymentReason {
        // the money the JC puts up to pay for the job
        JobFee,
        // the money the RP gets paid for the job for running it successfully
        JobPayment,
        // the money the RP puts up to attest it's results are correct
        ResourceProviderCollateral,
        // the money the RP, JC and Validtor all put up to prevent timeouts
        TimeoutCollateral,
        // The money a JC puts up to pay for a validator to validate their results
        Validiationcollateral,
        // the money the JC pays the Validtor for resolving a dispute
        ValidationFee,
        // the money that the module creator pays to the protocol when a module is run
        ModuleMarketplaceFeePayment,
        // The fee that a JC pays to a module creator for running their module
        ModuleCreatorFeePayment,
        // The fee that is paid to the solver for making a match
        MatchFee
    }

    enum PaymentDirection {
        // money flowing into the contract
        PaidIn,
        // money paid out to services
        PaidOut,
        // collateral that is locked up being refunded
        Refunded,
        // collateral that is locked up being slashed
        Slashed,
        // money that is burnt
        Burned
    }

    bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

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

    /**
     * @dev This struct is used to store the payment structure for a deal
     * @notice
     * - The priceOfJobWithoutFees is the price of the job from the Job Creator's perspective i.e how much they pay to run the job
     * - The moduleCreatorFee is the fee that the Job Creator pays to the Module Creator for running the module
     * - The totalSolverFees are the total fees paid by the Resource Provider and Job Creator to the Solver for preforming the work to match them on a job
     * - The networkCongestionFee is the fee that the Job Creator pays to the network for the congestion of the network
     * - The moduleCreator is the address of the Module Creator
     * - The solver is the address of the Solver
     * - The total cost of a job from a Job Creator perspective is the sum of the priceOfJobWithoutFees, the moduleCreatorFee, the totalSolverFees/2 and the networkCongestionFee
     */
     // TODO: Should we add the module name here too?
    struct DealPaymentStructure {
        uint256 totalSolverFees;
        uint256 networkCongestionFee;
        uint256 moduleCreatorFee;
        uint256 priceOfJobWithoutFees;
    }

    struct Deal {
        string dealId;
        address jobCreator;
        address resourceProvider;
        address moduleCreator;
        address solver;
        string jobOfferCID;
        string resourceOfferCID;
        DealStatusEnum status;
        uint256 timestamp;
        DealPaymentStructure paymentStructure;
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
}
