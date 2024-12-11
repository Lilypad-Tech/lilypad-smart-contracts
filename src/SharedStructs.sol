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

  // we map addresses onto infomation about the user
  struct User {
    address userAddress;
    // the decentralized identifier for the user's metadata (e.g. CID)
    string metadataID;
    // the url of the user's metadata
    string url;
    // // the roles of the user
    // UserType[] roles;
  }
}